import { prisma } from "../lib/prisma";
import ProductService from "./ProductService";
import PaymentService from "./PaymentService";
import { Prisma } from "@prisma/client";
import invoiceService from "./InvoiceService";
import NotificationService from "./NotificationService";

class OrderService {
  /**
   * Create a new purchase order
   * @param userId The ID of the user buying
   * @param productId The Gold Coin to buy
   * @param quantity Number of coins
   */
  async createPurchaseOrder(userId: string, productId: string, quantity: number, referralCode?: string) {
    // 1. Get Product & Live Price
    const product = await ProductService.getProductById(productId);
    if (!product) throw new Error("Product not found");
    if (product.stock < quantity) throw new Error("Out of stock");

    const livePriceObj = await ProductService.getLatestGoldPrice();
    const livePrice = Number(livePriceObj.sellPrice);

    // 2. Validate Referral Logic (Cannot use own code on 1st order)
    const paidOrderCount = await prisma.order.count({
      where: { userId, status: "PAYMENT_SUCCESSFUL" }
    });
    
    if (referralCode) {
      const dbUser = await prisma.user.findUnique({ where: { id: userId } });
      if (dbUser) {
        const isSelf = dbUser.referralCode === referralCode.trim().toUpperCase();
        if (isSelf && paidOrderCount === 0) {
          throw new Error("You cannot use your own referral code for the first order.");
        }
      }
    }

    // 3. Calculate Pricing (Weight * Price * 1.03)
    const pricing = ProductService.calculateProductPrice(product, livePrice);

    // Get IST time
    const istOffset = 5.5 * 60 * 60 * 1000;
    const nowIST = new Date(Date.now() + istOffset);

    // 3. Create Database Order (Pending)
    const order = await prisma.order.create({
      data: {
        userId,
        productId,
        quantity,
        amount: new Prisma.Decimal(pricing.goldValue),
        gst: new Prisma.Decimal(pricing.gstAmount),
        total: new Prisma.Decimal(pricing.total),
        weight: new Prisma.Decimal(pricing.weight),
        status: "PAYMENT_PENDING",
        goldPriceAtPurchase: new Prisma.Decimal(livePrice),
        referralCode: referralCode,
        createdAt: nowIST,
        statusHistory: {
          create: {
            status: "PAYMENT_PENDING",
            notes: "Order initiated and awaiting payment.",
            createdAt: nowIST,
          }
        }
      },
    });

    // 4. Create Razorpay Order
    const user = await prisma.user.findUnique({ where: { id: userId } });
    let razorpayOrder;
    try {
      razorpayOrder = await PaymentService.createOrder(
        pricing.total * quantity,
        order.id,
        userId,
        user?.phone || "9999999999"
      );
    } catch (paymentError: any) {
      console.error("❌ [OrderService] Razorpay Order Creation Failed:", paymentError.message || paymentError);
      throw new Error(`Payment gateway error: ${paymentError.message || "Failed to initiate payment"}`);
    }

    // 5. Link Razorpay Order ID to our local Order
    await prisma.order.update({
      where: { id: order.id },
      data: { paymentId: (razorpayOrder as any).id },
    });

    return {
      orderId: order.id,
      razorpayOrderId: (razorpayOrder as any).id,
      amount: pricing.total * quantity,
      currency: "INR",
    };
  }

  /**
   * Complete the order after payment verification
   */
  async verifyAndFinalizeOrder(
    userId: string,
    orderId: string,
    razorpayPaymentId: string,
    razorpaySignature: string
  ) {
    // 1. Fetch Order
    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: { product: true }
    });

    if (!order || order.userId !== userId) throw new Error("Order not found");
    if (order.status === "PAYMENT_SUCCESSFUL") return order; // Already processed

    // 2. Verify Payment via Razorpay Signature
    if (!order.paymentId) throw new Error("Order has no active payment session");
    
    const isValid = PaymentService.verifySignature(order.paymentId, razorpayPaymentId, razorpaySignature);
    if (!isValid) throw new Error("Invalid payment signature");


    // 3. Update Order Status and Process Rewards
    const invoiceNo = `INV-${Date.now()}-${order.id.substring(0, 4).toUpperCase()}`;

    const result = await prisma.$transaction(async (tx) => {
      // Get delivery settings
      const deliveryDaysSetting = await tx.setting.findUnique({ where: { key: "delivery_days" } });
      const deliveryDays = deliveryDaysSetting ? parseInt(deliveryDaysSetting.value) : 7;
      const deliveryDate = new Date();
      deliveryDate.setDate(deliveryDate.getDate() + deliveryDays);

      const latestPrice = await ProductService.getLatestGoldPrice();

      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: {
          status: "PAYMENT_SUCCESSFUL",
          paymentStatus: "SUCCESS",
          invoiceNo: invoiceNo,
          deliveryDate: deliveryDate,
          goldPriceAtPurchase: latestPrice.sellPrice,
        } as any,
      });

      // Track Payment in separate table
      await tx.payment.create({
        data: {
          orderId: order.id,
          razorpayOrderId: order.paymentId!,
          razorpayPaymentId: razorpayPaymentId,
          razorpaySignature: razorpaySignature,
          amount: order.total,
          status: "SUCCESS"
        }
      });

      // Transition to ORDER_CONFIRMED (Collection countdown starts)
      await tx.order.update({
        where: { id: orderId },
        data: { 
          status: "ORDER_CONFIRMED",
          statusHistory: {
            createMany: {
              data: [
                { status: "PAYMENT_SUCCESSFUL", notes: "Payment verified successfully." },
                { status: "ORDER_CONFIRMED", notes: "Order confirmed and fulfillment initiated." }
              ]
            }
          }
        }
      });

      // Reduce Stock
      await tx.product.update({
        where: { id: order.productId },
        data: { stock: { decrement: order.quantity } },
      });

      // Create Transaction record for the Purchase
      await tx.transaction.create({
        data: {
          userId,
          type: "PURCHASE",
          amount: order.total,
          description: `Gold Collection - ${order.product.name} (Qty: ${order.quantity})`,
          status: "COMPLETED",
          invoiceNo: invoiceNo,
        }
      });

      // Handle Referral Reward (Fixed amount set by admin)
      if (order.referralCode) {
        const referrer = await tx.user.findUnique({
          where: { referralCode: order.referralCode }
        });

        if (referrer) {
          // Fetch reward setting (default ₹500 if not found)
          const rewardSetting = await tx.setting.findUnique({ where: { key: "referral_reward" } });
          const rewardAmount = rewardSetting ? Number(rewardSetting.value) : 500;
          
          await tx.wallet.update({
            where: { userId: referrer.id },
            data: { 
              balance: { increment: rewardAmount }
            }
          });

          await tx.transaction.create({
            data: {
              userId: referrer.id,
              type: "REFERRAL_REWARD",
              amount: new Prisma.Decimal(rewardAmount),
              description: `Referral reward for facilitating Order #${orderId}`,
              status: "COMPLETED"
            }
          });
        }
      }

      // Log the event
      await tx.auditLog.create({
        data: {
          userId,
          action: "ORDER_PURCHASED",
          details: { orderId, total: order.total, quantity: order.quantity },
        },
      });

      return updatedOrder;
    });

    // 4. Generate and Sync Invoice (Non-blocking but atomic attempt)
    try {
      await invoiceService.generateAndSyncInvoice(orderId);
    } catch (err) {
      console.error(`⚠️ Invoice generation failed for order ${orderId}:`, err);
    }

    // 5. Auto-transition to PROCESSING after 2 seconds
    setTimeout(async () => {
      try {
        await this.updateOrderStatus(orderId, "PROCESSING");
        console.log(`⏱️ Auto-transitioned order ${orderId} to PROCESSING.`);
      } catch (e) {
        console.error(`Failed to auto-transition order ${orderId} to PROCESSING:`, e);
      }
    }, 2000);

    return result;
  }

  /**
   * Get purchase history for a user
   */
  async getUserOrders(userId: string) {
    return await prisma.order.findMany({
      where: { userId },
      include: { 
        product: true,
        statusHistory: { orderBy: { createdAt: "asc" } }
      },
      orderBy: { createdAt: "desc" },
    });
  }

  /**
   * Get all orders in the system (Admin only)
   */
  async getAllOrders() {
    return await prisma.order.findMany({
      include: {
        product: true,
        statusHistory: { orderBy: { createdAt: "asc" } },
        user: {
          select: {
            id: true,
            name: true,
            phone: true,
            address: true,
          }
        }
      },
      orderBy: { createdAt: "desc" },
    });
  }

  /**
   * Update order status (Admin only)
   */
  async updateOrderStatus(orderId: string, status: string) {
    const istOffset = 5.5 * 60 * 60 * 1000;
    const nowIST = new Date(Date.now() + istOffset);

    const order = await prisma.order.update({
      where: { id: orderId },
      include: { user: true, product: true },
      data: { 
        status: status.toUpperCase() as any,
        statusHistory: {
          create: {
            status: status.toUpperCase() as any,
            notes: `Status updated by administrator.`,
            createdAt: nowIST,
          }
        }
      },
    });

    // Notify User
    await NotificationService.sendPushNotification(
      order.userId,
      'Order Status Update',
      `Your order #${orderId.substring(0, 8)} is now ${status.replace(/_/g, ' ')}.`,
      'ORDER_STATUS'
    );

    // If status is ORDER_CONFIRMED, generate/sync invoice
    if (status.toUpperCase() === 'ORDER_CONFIRMED' || status.toUpperCase() === 'PROCESSING') {
      try {
        await invoiceService.generateAndSyncInvoice(orderId);
      } catch (err) {
        console.error(`⚠️ Invoice generation failed for order ${orderId}:`, err);
      }
    }

    return order;
  }

  /**
   * Cancel an order (User initiated)
   * Only allowed before fulfillment processing reaches a certain stage
   */
  async cancelOrder(orderId: string, userId: string) {
    return await prisma.$transaction(async (tx) => {
      const order = await tx.order.findUnique({
        where: { id: orderId },
        include: { user: true }
      });

      if (!order || order.userId !== userId) throw new Error("Order not found");
      
      const cancellableStatuses = ["PAYMENT_PENDING", "PAYMENT_SUCCESSFUL", "ORDER_CONFIRMED", "PROCESSING"];
      if (!cancellableStatuses.includes(order.status)) {
        throw new Error(`Order cannot be cancelled at stage: ${order.status}`);
      }

      // Update Order Status
      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: { 
          status: "CANCELLED",
          statusHistory: {
            create: { status: "CANCELLED", notes: "Order cancelled by customer." }
          }
        }
      });

      // Log direct refund transaction for admin tracking (Direct Bank Transfer)
      if (order.status !== "PAYMENT_PENDING") {
        await tx.transaction.create({
          data: {
            userId,
            type: "REFUND",
            amount: order.total,
            description: `Refund for Cancelled Order #${orderId.substring(0,8)}. Payout to Bank Account.`,
            status: "PENDING"
          }
        });
      }

      // Restore Stock
      await tx.product.update({
        where: { id: order.productId },
        data: { stock: { increment: order.quantity } }
      });

      return updatedOrder;
    });
  }

  /**
   * Buyback Program (Sell Back Gold)
   * Only allowed if status is READY_FOR_PICKUP (User has the gold in vault)
   */
  async initiateBuyback(orderId: string, userId: string) {
    return await prisma.$transaction(async (tx) => {
      const order = await tx.order.findUnique({
        where: { id: orderId },
        include: { product: true }
      });

      if (!order || order.userId !== userId) throw new Error("Order not found");
      
      if (order.status !== "READY_FOR_PICKUP") {
        throw new Error("Only gold ready for pickup can be sold back.");
      }

      // Check if a request already exists
      const existingRequest = await tx.buybackRequest.findUnique({
        where: { orderId }
      });
      if (existingRequest && existingRequest.status === "PENDING") {
        throw new Error("A buyback request is already pending for this order.");
      }

      // Get latest Gold Buy Price
      const latestPrice = await tx.goldPrice.findFirst({
        orderBy: { timestamp: 'desc' }
      });
      if (!latestPrice) throw new Error("Gold price not available.");

      const buybackAmount = Number(order.weight) * Number(latestPrice.buyPrice);

      // 1. Update Order Status to BUYBACK_PENDING
      await tx.order.update({
        where: { id: orderId },
        data: { 
          status: "BUYBACK_PENDING",
          statusHistory: {
            create: { status: "BUYBACK_PENDING", notes: "Buyback request submitted for approval." }
          }
        }
      });

      // 2. Create BuybackRequest record
      const request = await tx.buybackRequest.create({
        data: {
          orderId,
          userId,
          amount: new Prisma.Decimal(buybackAmount),
          buyPrice: latestPrice.buyPrice,
          status: "PENDING"
        }
      });

      // 3. Create Transaction record for Payout (Tracking)
      await tx.transaction.create({
        data: {
          userId,
          type: "SELL_BACK",
          amount: new Prisma.Decimal(buybackAmount),
          description: `Buyback Payout Request for ${order.product.name}. Approval pending.`,
          status: "PENDING"
        }
      });

      // 4. Temporarily return to stock (Blocked for other users)
      await tx.product.update({
        where: { id: order.productId },
        data: { stock: { increment: order.quantity } }
      });

      return request;
    });
  }

  /**
   * List all pending buyback requests (Admin)
   */
  async listBuybackRequests() {
    return await prisma.buybackRequest.findMany({
      where: { status: "PENDING" },
      include: {
        user: { select: { name: true, phone: true } },
        order: { include: { product: true } }
      },
      orderBy: { createdAt: "desc" }
    });
  }

  /**
   * Process Admin action on Buyback
   */
  async processBuybackAction(requestId: string, action: 'APPROVE' | 'REJECT', adminNotes?: string) {
    return await prisma.$transaction(async (tx) => {
      const request = await tx.buybackRequest.findUnique({
        where: { id: requestId },
        include: { order: true }
      });

      if (!request) throw new Error("Buyback request not found.");
      if (request.status !== "PENDING") throw new Error("Request already processed.");

      if (action === 'APPROVE') {
        // 1. Mark Request as Completed
        await tx.buybackRequest.update({
          where: { id: requestId },
          data: { status: "COMPLETED", adminNotes }
        });

        // 2. Update Order Status
        await tx.order.update({
          where: { id: request.orderId },
          data: { 
            status: "SOLD_BACK",
            statusHistory: { create: { status: "SOLD_BACK", notes: adminNotes || "Buyback approved and processed." } }
          }
        });

        // 3. Update Transaction status
        // Find the pending transaction for this user/amount
        const txn = await tx.transaction.findFirst({
          where: { 
            userId: request.userId, 
            type: "SELL_BACK", 
            status: "PENDING",
            amount: request.amount
          },
          orderBy: { createdAt: "desc" }
        });

        if (txn) {
          await tx.transaction.update({
            where: { id: txn.id },
            data: { status: "COMPLETED", description: `Buyback completed. ${adminNotes || ""}` }
          });
        }
      } else {
        // REJECT
        // 1. Mark Request as Rejected
        await tx.buybackRequest.update({
          where: { id: requestId },
          data: { status: "REJECTED", adminNotes }
        });

        // 2. Revert Order Status
        await tx.order.update({
          where: { id: request.orderId },
          data: { 
            status: "READY_FOR_PICKUP",
            statusHistory: { create: { status: "READY_FOR_PICKUP", notes: `Buyback rejected: ${adminNotes}` } }
          }
        });

        // 3. Update Transaction
        const txn = await tx.transaction.findFirst({
          where: { 
            userId: request.userId, 
            type: "SELL_BACK", 
            status: "PENDING",
            amount: request.amount
          },
          orderBy: { createdAt: "desc" }
        });

        if (txn) {
          await tx.transaction.update({
            where: { id: txn.id },
            data: { status: "REJECTED", description: `Buyback rejected. ${adminNotes || ""}` }
          });
        }

        // 4. Remove from stock (Restore inventory)
        await tx.product.update({
          where: { id: request.order.productId },
          data: { stock: { decrement: request.order.quantity } }
        });
      }

      return request;
    });
  }

  /**
   * FIFO Auto-approval: Mark oldest pending orders as READY
   */
  async autoApproveOrders(productId: string, readyStockCount: number) {
    if (readyStockCount <= 0) return;

    // Get oldest PENDING orders for this product
    const pendingOrders = await prisma.order.findMany({
      where: { productId, status: "ORDER_CONFIRMED" },
      orderBy: { createdAt: "asc" },
      take: readyStockCount
    });

    return await prisma.$transaction(async (tx) => {
      for (const order of pendingOrders) {
        await tx.order.update({
          where: { id: order.id },
          data: { 
            status: "READY_FOR_PICKUP",
            statusHistory: {
              create: {
                status: "READY_FOR_PICKUP",
                notes: "Inventory available. Ready for store collection."
              }
            }
          }
        });
      }

      // Decrement ready stock from the product
      await tx.product.update({
        where: { id: productId },
        data: { readyStock: { decrement: pendingOrders.length } }
      });
    });
  }
}

export default new OrderService();
