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
  async createPurchaseOrder(userId: string, productId: string, quantity: number) {
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
        status: "PENDING",
      },
    });

    // 4. Create Cashfree Order
    const user = await prisma.user.findUnique({ where: { id: userId } });
    const cashfreeOrder = await PaymentService.createOrder(
      pricing.total * quantity,
      order.id,
      userId,
      user?.phone || "9999999999"
    );

    // 5. Link Payment Session ID to our local Order (Optional depending on usage, we just map the order.id to Cashfree)
    await prisma.order.update({
      where: { id: order.id },
      data: { paymentId: cashfreeOrder.payment_session_id },
    });

    return {
      orderId: order.id,
      cashfreeSessionId: cashfreeOrder.payment_session_id,
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
    // 1. Verify Payment via Cashfree
    const isPaid = await PaymentService.verifyPayment(orderId);

    if (!isPaid) throw new Error("Payment could not be verified successfully");

    // 2. Fetch Order
    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: { product: true }
    });

    if (!order || order.userId !== userId) throw new Error("Order not found");
    if (order.status === "PAID") return order; // Already processed

    // 3. Update Order Status
    return await prisma.$transaction(async (tx) => {
      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: {
          status: "PAID",
          paymentStatus: "SUCCESS",
        },
      });

      // Reduce Stock
      await tx.product.update({
        where: { id: order.productId },
        data: { stock: { decrement: order.quantity } },
      });

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
}

export default new OrderService();
