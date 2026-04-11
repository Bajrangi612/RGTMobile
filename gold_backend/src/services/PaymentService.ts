import Razorpay from "razorpay";
import dotenv from "dotenv";

dotenv.config();

const instance = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || "",
  key_secret: process.env.RAZORPAY_KEY_SECRET || "",
});

class PaymentService {
  async createOrder(amount: number, orderId: string, customerId: string, customerPhone: string, orderDetails: any) {
    const options = {
      amount: Math.round(amount * 100), // amount in paise
      currency: "INR",
      receipt: orderId,
      notes: { ...orderDetails, customerId, customerPhone },
    };

    const order = await instance.orders.create(options);
    return order;
  }

  async fetchOrder(orderId: string) {
    return await instance.orders.fetch(orderId);
  }



  async verifyPayment(razorpayOrderId: string): Promise<boolean> {
    try {
      const payments = await instance.orders.fetchPayments(razorpayOrderId);
      if (payments && payments.items && payments.items.length > 0) {
        return payments.items.some((p: any) => p.status === 'captured');
      }
      return false;
    } catch (error) {
      console.error("Error verifying payment:", error);
      return false;
    }
  }

  /**
   * Verify signature from Razorpay response
   */
  verifySignature(orderId: string, paymentId: string, signature: string): boolean {
    const crypto = require("crypto");
    const secret = process.env.RAZORPAY_KEY_SECRET || "";
    const generatedSignature = crypto
      .createHmac("sha256", secret)
      .update(orderId + "|" + paymentId)
      .digest("hex");

    return generatedSignature === signature;
  }
}

export default new PaymentService();
