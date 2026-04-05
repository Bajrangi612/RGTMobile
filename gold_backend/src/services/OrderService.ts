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
    if (!livePriceObj) throw new Error("Live gold price not available");

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
        weight: new Prisma.Decimal(pricing.weight), // Store product weight
        status: "PENDING",
        referralCode: referralCode, // Track code used
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
    orderId: string
  ) {
    // 1. Fetch Order
    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: { product: true }
    });

    if (!order || order.userId !== userId) throw new Error("Order not found");
    if (order.status === "PAID") return order; // Already processed

    // 2. Verify Payment via Razorpay
    // Razorpay uses its own order_id (e.g. order_xxx) which we saved as paymentId
    if (!order.paymentId) throw new Error("Order has no active payment session");
    const isPaid = await PaymentService.verifyPayment(order.paymentId);

    if (!isPaid) throw new Error("Payment could not be verified successfully");


    // 3. Update Order Status and Process Rewards
    return await prisma.$transaction(async (tx) => {
      // Generate Invoice Reference
      const year = new Date().getFullYear();
      const orderCount = await tx.order.count({
        where: { createdAt: { gte: new Date(`${year}-01-01`) } }
      });
      const invoiceNo = `RGT/${year}/${(orderCount + 1).toString().padStart(4, '0')}`;

      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: {
          status: "PAID",
          paymentStatus: "SUCCESS",
          invoiceNo: invoiceNo,
        } as any,
      });

      // Reduce Stock
      await tx.product.update({
        where: { id: order.productId },
        data: { stock: { decrement: order.quantity } },
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
    return await prisma.order.update({
      where: { id: orderId },
      data: { status: status as any },
    });
  }
}

export default new OrderService();
