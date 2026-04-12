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

    // 2. Validate Referral Logic
    // Status does not matter: if they have any order, it's not their first.
    const orderCount = await prisma.order.count({
      where: { userId }
    });
    
    if (referralCode) {
      const dbUser = await prisma.user.findUnique({ where: { id: userId } });
      if (dbUser) {
        const normalizedCode = referralCode.trim().toUpperCase();
        const isSelf = dbUser.referralCode === normalizedCode;
        
        // Cannot use own code for the very first order
        if (isSelf && orderCount === 0) {
          throw new Error("You cannot use your own referral code for your first order.");
        }

        // Verify the referral code actually exists in the system
        const referrer = await prisma.user.findUnique({ where: { referralCode: normalizedCode } });
        if (!referrer) {
          throw new Error("The referral code provided is invalid or does not exist.");
        }
      }
    }

    // 3. Calculate Pricing (Weight * Price * 1.03)
    const pricing = ProductService.calculateProductPrice(product, livePrice);

    // 4. Create Razorpay Order with DETAILS IN NOTES
    // We don't create a DB record yet to satisfy the requirement: "Until Customer Completes his order successfully with payment, dont create new record"
    const tempReceipt = `RCPT-${Date.now()}-${userId.substring(0, 4)}`;
    
    const user = await prisma.user.findUnique({ where: { id: userId } });
    
    let razorpayOrder;
    try {
      razorpayOrder = await PaymentService.createOrder(
        pricing.total * quantity,
        tempReceipt,
        userId,
        user?.phone || "9999999999",
        {
          productId,
          quantity: quantity.toString(),
          referralCode: referralCode || "",
          livePrice: livePrice.toString(),
          pricingTotal: pricing.total.toString(),
          pricingGold: pricing.goldValue.toString(),
          pricingGst: pricing.gstAmount.toString(),
          pricingWeight: pricing.weight.toString(),
        }
      );
    } catch (paymentError: any) {
      console.error("❌ [OrderService] Razorpay Order Creation Failed:", paymentError.message || paymentError);
      throw new Error(`Payment gateway error: ${paymentError.message || "Failed to initiate payment"}`);
    }

    return {
      orderId: (razorpayOrder as any).id, // We use Razorpay ID as temporary orderId
      razorpayOrderId: (razorpayOrder as any).id,
      amount: pricing.total * quantity,
      currency: "INR",
    };
  }


  /**
   * Complete the order after payment verification
   */
  private getIST() {
    const istOffset = 5.5 * 60 * 60 * 1000;
    return new Date(Date.now() + istOffset);
  }

  /**
   * Complete the order after payment verification
   */
  async verifyAndFinalizeOrder(
    userId: string,
    razorpayOrderId: string,
    razorpayPaymentId: string,
    razorpaySignature: string
  ) {
    // 1. Verify Payment via Razorpay Signature
    const isValid = PaymentService.verifySignature(razorpayOrderId, razorpayPaymentId, razorpaySignature);
    if (!isValid) throw new Error("Invalid payment signature");

    // 2. Fetch Order Details from Razorpay (since we didn't save it in DB yet)
    const razorpayOrder = await PaymentService.fetchOrder(razorpayOrderId);
    const notes = razorpayOrder.notes as any;

    if (!notes || notes.customerId !== userId) {
      throw new Error("Invalid order session or unauthorized user.");
    }

    // Check if order already exists (Idempotency)
    const existingOrder = await prisma.order.findFirst({
      where: { paymentId: razorpayOrderId }
    });
    if (existingOrder) return existingOrder;

    const productId = notes.productId;
    const quantity = parseInt(notes.quantity);
    const referralCode = notes.referralCode;
    const livePrice = new Prisma.Decimal(notes.livePrice);
    const amount = new Prisma.Decimal(notes.pricingGold);
    const gst = new Prisma.Decimal(notes.pricingGst);
    const total = new Prisma.Decimal(notes.pricingTotal);
    const weight = new Prisma.Decimal(notes.pricingWeight);

    // 3. Create actual Order Record in Database
    const nowIST = this.getIST();
    const invoiceNo = `INV-${Date.now()}-${razorpayOrderId.substring(razorpayOrderId.length - 4).toUpperCase()}`;

    const result = await prisma.$transaction(async (tx) => {
      // Get delivery settings
      const deliveryDaysSetting = await tx.setting.findUnique({ where: { key: "delivery_days" } });
      const deliveryDays = deliveryDaysSetting ? parseInt(deliveryDaysSetting.value) : 7;
      const deliveryDate = new Date(nowIST);
      deliveryDate.setDate(deliveryDate.getDate() + deliveryDays);

      // Create Order
      const newOrder = await tx.order.create({
        data: {
          userId,
          productId,
          quantity,
          amount,
          gst,
          total,
          weight,
          paymentId: razorpayOrderId,
          paymentStatus: "SUCCESS",
          status: "ORDER_CONFIRMED" as any,
          invoiceNo: invoiceNo,
          deliveryDate: deliveryDate,
          goldPriceAtPurchase: livePrice,
          referralCode: referralCode || null,
          createdAt: nowIST,
          statusHistory: {
            createMany: {
              data: [
                { status: "PAYMENT_SUCCESSFUL" as any, notes: "Verified Payment Successfully.", createdAt: nowIST },
                { status: "ORDER_CONFIRMED" as any, notes: "Order confirmed and fulfillment initiated.", createdAt: nowIST }
              ]
            }
          }
        },
        include: { product: true }
      });

      // Track Payment in separate table
      await tx.payment.create({
        data: {
          orderId: newOrder.id,
          razorpayOrderId: razorpayOrderId,
          razorpayPaymentId: razorpayPaymentId,
          razorpaySignature: razorpaySignature,
          amount: total,
          status: "SUCCESS"
        }
      });

      // Reduce Stock
      await tx.product.update({
        where: { id: productId },
        data: { stock: { decrement: quantity } },
      });

      // Create Transaction record for the Purchase
      await tx.transaction.create({
        data: {
          userId,
          type: "PURCHASE",
          amount: total,
          description: `Gold Collection - ${(newOrder as any).product.name} (Qty: ${quantity})`,
          status: "COMPLETED",
          invoiceNo: invoiceNo,
          createdAt: nowIST,
        }
      });

      // Handle Referral Reward (Fixed amount set by admin)
      if (referralCode) {
        const referrer = await tx.user.findUnique({
          where: { referralCode }
        });

        if (referrer) {
           const rewardSetting = await tx.setting.findUnique({ where: { key: "referral_reward" } });
           const rewardAmount = rewardSetting ? Number(rewardSetting.value) : 500;
           
           await tx.wallet.update({
             where: { userId: referrer.id },
             data: { balance: { increment: rewardAmount } }
           });

           await tx.transaction.create({
             data: {
               userId: referrer.id,
               type: "REFERRAL_REWARD",
               amount: new Prisma.Decimal(rewardAmount),
               description: `Referral reward for facilitating Order #${newOrder.id}`,
               status: "COMPLETED",
               createdAt: nowIST,
             }
           });
        }
      }

      // Log the event
      await tx.auditLog.create({
        data: {
          userId,
          action: "ORDER_PURCHASED",
          details: { orderId: newOrder.id, total, quantity },
          createdAt: nowIST,
        },
      });

      return newOrder;
    });

    // 4. Generate and Sync Invoice
    try {
      await invoiceService.generateAndSyncInvoice(result.id);
    } catch (err) {
      console.error(`⚠️ Invoice generation failed for order ${result.id}:`, err);
    }

    // 5. Auto-transition to PROCESSING after 2 seconds
    setTimeout(async () => {
      try {
        await this.updateOrderStatus(result.id, "PROCESSING");
      } catch (e) {
        console.error(`Failed to auto-transition order ${result.id} to PROCESSING:`, e);
      }
    }, 2000);

    return result;
  }


  /**
   * Get purchase history for a user
   */
  async getUserOrders(userId: string, page: number = 1, limit: number = 50) {
    const skip = (page - 1) * limit;
    
    const [orders, total] = await Promise.all([
      prisma.order.findMany({
        where: { userId },
        include: { 
          product: true,
          statusHistory: { orderBy: { createdAt: "asc" } }
        },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit
      }),
      prisma.order.count({ where: { userId } })
    ]);

    return {
      orders,
      pagination: { total, page, limit, totalPages: Math.ceil(total / limit) }
    };
  }

  /**
   * Get all orders in the system (Admin only)
   */
  async getAllOrders(page: number = 1, limit: number = 50) {
    const skip = (page - 1) * limit;

    const [orders, total] = await Promise.all([
      prisma.order.findMany({
        include: {
          product: true,
          statusHistory: { orderBy: { createdAt: "asc" } },
          user: {
            select: { id: true, name: true, phone: true, address: true }
          }
        },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit
      }),
      prisma.order.count()
    ]);

    return {
      orders,
      pagination: { total, page, limit, totalPages: Math.ceil(total / limit) }
    };
  }

  /**
   * Update order status (Admin only)
   */
  async updateOrderStatus(orderId: string, status: string) {
    const nowIST = this.getIST();

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
          status: "CANCELLED" as any,
          statusHistory: {
            create: { status: "CANCELLED" as any, notes: "Order cancelled by customer." }
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

      // 3. Create actual Transaction Record
      const txn = await tx.transaction.create({
        data: {
          userId,
          type: "SELL_BACK",
          amount: new Prisma.Decimal(latestPrice.buyPrice),
          description: `Sell back request initiated for order #${order.invoiceNo || orderId}`,
          status: "PENDING"
        }
      });

      // 4. Update Order Status
      await tx.order.update({
        where: { id: orderId },
        data: { 
          status: "PREPARING_ORDER", // Indicating it's being processed for buyback
          statusHistory: { create: { status: "PREPARING_ORDER", notes: "Sell back request initiated. Gold ready for pickup/verification." } }
        }
      });

      // 5. Create Buyback Request
      const request = await tx.buybackRequest.create({
        data: {
          orderId,
          userId,
          amount: new Prisma.Decimal(buybackAmount),
          buyPrice: latestPrice.buyPrice,
          status: "SELL_BACK_APPLIED"
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
      where: { status: "PENDING" as any },
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
      if (request.status !== "SELL_BACK_APPLIED" && request.status !== "APPROVED") throw new Error("Request already processed.");

      if (action === 'APPROVE') {
        const nextStatus = request.status === "SELL_BACK_APPLIED" ? "APPROVED" : "PAYMENT_SETTLED";
        
        // 1. Mark Request as Approved or Settled
        await tx.buybackRequest.update({
          where: { id: requestId },
          data: { status: nextStatus, adminNotes }
        });

        // 2. If settled, update Order Status
        if (nextStatus === "PAYMENT_SETTLED") {
          await tx.order.update({
            where: { id: request.orderId },
            data: { 
              status: "SOLD_BACK" as any,
              statusHistory: { create: { status: "SOLD_BACK" as any, notes: adminNotes || "Buyback payment settled." } }
            }
          });
        }

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
            status: "READY_FOR_PICKUP" as any,
            statusHistory: { create: { status: "BUYBACK_REJECTED" as any, notes: `Buyback rejected: ${adminNotes}` } }
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
      where: { productId, status: "ORDER_CONFIRMED" as any },
      orderBy: { createdAt: "asc" },
      take: readyStockCount
    });

    return await prisma.$transaction(async (tx) => {
      for (const order of pendingOrders) {
        await tx.order.update({
          where: { id: order.id },
          data: { 
            status: "READY_FOR_PICKUP" as any,
            statusHistory: {
              create: {
                status: "READY_FOR_PICKUP" as any,
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

  /**
   * Cancel a pending buyback request
   */
  async cancelBuyback(orderId: string, userId: string) {
    return await prisma.$transaction(async (tx) => {
      const request = await tx.buybackRequest.findUnique({
        where: { orderId },
        include: { order: true }
      });

      if (!request || request.userId !== userId) throw new Error("Buyback request not found.");
      if (request.status !== "PENDING") throw new Error("Request already processed.");

      // 1. Delete the request
      await tx.buybackRequest.delete({ where: { id: request.id } });

      // 2. Revert Order Status
      await tx.order.update({
        where: { id: orderId },
        data: { 
          status: "READY_FOR_PICKUP" as any,
          statusHistory: { create: { status: "BUYBACK_REJECTED" as any, notes: "Buyback request cancelled by customer." } }
        }
      });

      // 3. Mark the transaction as cancelled
      const txn = await tx.transaction.findFirst({
        where: { 
          userId, 
          type: "SELL_BACK", 
          status: "PENDING",
          amount: request.amount
        },
        orderBy: { createdAt: "desc" }
      });

      if (txn) {
        await tx.transaction.update({
          where: { id: txn.id },
          data: { status: "CANCELLED", description: "Buyback request cancelled by customer." }
        });
      }

      // 4. Restore original stock (Remove the increment we did during initiation)
      await tx.product.update({
        where: { id: request.order.productId },
        data: { stock: { decrement: request.order.quantity } }
      });

      return { message: "Buyback request cancelled successfully" };
    });
  }
}

export default new OrderService();
