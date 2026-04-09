import { prisma } from "../lib/prisma";
import ProductService from "./ProductService";
import PaymentService from "./PaymentService";
import { Prisma } from "@prisma/client";

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

    // 2. Calculate Pricing (Weight * Price * 1.03)
    const pricing = ProductService.calculateEffectivePrice(product, livePrice);

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
        status: "CREATED",
        goldPriceAtPurchase: new Prisma.Decimal(livePrice),
        referralCode: referralCode,
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
    if (order.status === "PAID") return order; // Already processed

    // 2. Verify Payment via Razorpay Signature
    if (!order.paymentId) throw new Error("Order has no active payment session");
    
    const isValid = PaymentService.verifySignature(order.paymentId, razorpayPaymentId, razorpaySignature);
    if (!isValid) throw new Error("Invalid payment signature");


    // 3. Update Order Status and Process Rewards
    const invoiceNo = `INV-${Date.now()}-${order.id.substring(0, 4).toUpperCase()}`;

    return await prisma.$transaction(async (tx) => {
      // Get delivery settings
      const deliveryDaysSetting = await tx.setting.findUnique({ where: { key: "delivery_days" } });
      const deliveryDays = deliveryDaysSetting ? parseInt(deliveryDaysSetting.value) : 7;
      const deliveryDate = new Date();
      deliveryDate.setDate(deliveryDate.getDate() + deliveryDays);

      const latestPrice = await ProductService.getLatestGoldPrice();

      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: {
          status: "PAID",
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

      // Transition to PENDING (Delivery starts)
      await tx.order.update({
        where: { id: orderId },
        data: { status: "PENDING" }
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
          description: `Gold Purchase - ${order.product.name} (Qty: ${order.quantity})`,
          status: "COMPLETED",
          invoiceNo: invoiceNo,
        }
      });

      // Handle Referral Reward (1% commission to referrer)
      if (order.referralCode) {
        const referrer = await tx.user.findUnique({
          where: { referralCode: order.referralCode }
        });

        if (referrer && referrer.id !== userId) {
          const rewardAmount = Number(order.total) * 0.01; // Professional 1% commission
          
          await tx.wallet.update({
            where: { userId: referrer.id },
            data: { 
              balance: { increment: rewardAmount },
              referralRewards: { increment: rewardAmount }
            }
          });

          await tx.transaction.create({
            data: {
              userId: referrer.id,
              type: "REFERRAL",
              amount: new Prisma.Decimal(rewardAmount),
              description: `Referral reward for order ${orderId}`,
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
  }

  /**
   * Get purchase history for a user
   */
  async getUserOrders(userId: string) {
    return await prisma.order.findMany({
      where: { userId },
      include: { product: true },
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
        user: {
          select: {
            id: true,
            name: true,
            phone: true,
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
    const order = await prisma.order.update({
      where: { id: orderId },
      data: { status: status.toUpperCase() as any },
    });

    // If status changed to READY, check for notifications (handled in Phase 4)
    return order;
  }

  /**
   * Cancel order - only if not yet READY
   */
  async cancelOrder(userId: string, orderId: string) {
    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order || order.userId !== userId) throw new Error("Order not found");
    if (order.status === "READY" || order.status === "PICKED" || order.status === "RESOLD") {
      throw new Error("Order cannot be cancelled at this stage");
    }

    return await prisma.order.update({
      where: { id: orderId },
      data: { status: "CANCELLED" }
    });
  }

  /**
   * Resell logic - Buy back based on current purchase price
   */
  async resellOrder(userId: string, orderId: string) {
    const order = await prisma.order.findUnique({ 
      where: { id: orderId },
      include: { product: true } 
    });
    if (!order || order.userId !== userId) throw new Error("Order not found");
    if (order.status !== "READY") throw new Error("Only READY orders can be resold");

    const livePriceObj = await ProductService.getLatestGoldPrice();
    const purchasePrice = Number(livePriceObj.buyPrice);
    const weight = Number(order.weight);
    const quantity = order.quantity;
    const resellAmount = purchasePrice * weight * quantity;

    return await prisma.$transaction(async (tx) => {
      // 1. Mark order as RESOLD
      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: { status: "RESOLD" }
      });

      // 2. Add amount to user wallet
      await tx.wallet.update({
        where: { userId },
        data: { balance: { increment: resellAmount } }
      });

      // 3. Create Transaction record
      await tx.transaction.create({
        data: {
          userId,
          type: "PROFIT",
          amount: new Prisma.Decimal(resellAmount),
          description: `Resell credit for order ${orderId}`,
          status: "COMPLETED"
        }
      });

      return updatedOrder;
    });
  }

  /**
   * FIFO Auto-approval: Mark oldest pending orders as READY
   */
  async autoApproveOrders(productId: string, readyStockCount: number) {
    if (readyStockCount <= 0) return;

    // Get oldest PENDING orders for this product
    const pendingOrders = await prisma.order.findMany({
      where: { productId, status: "PENDING" },
      orderBy: { createdAt: "asc" },
      take: readyStockCount
    });

    return await prisma.$transaction(async (tx) => {
      for (const order of pendingOrders) {
        await tx.order.update({
          where: { id: order.id },
          data: { status: "READY" }
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
