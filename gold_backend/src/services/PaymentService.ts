import { Cashfree } from "cashfree-pg";
import dotenv from "dotenv";

dotenv.config();

Cashfree.XClientId = process.env.CASHFREE_APP_ID;
Cashfree.XClientSecret = process.env.CASHfree_SECRET_KEY;
Cashfree.XEnvironment = process.env.CASHFREE_ENV === "PRODUCTION" ? Cashfree.Environment.PRODUCTION : Cashfree.Environment.SANDBOX;

class PaymentService {
  /**
   * Create a new Cashfree order
   * @param amount Amount in INR
   * @param orderId Our Database Order ID
   * @param customerId The user ID
   * @param customerPhone The user's phone number
   * @returns Cashfree Payment Session Information
   */
  async createOrder(amount: number, orderId: string, customerId: string, customerPhone: string) {
    const request = {
      order_id: orderId,
      order_amount: amount,
      order_currency: "INR",
      customer_details: {
        customer_id: customerId,
        customer_phone: customerPhone || "9999999999",
      },
    };

    const response = await Cashfree.PGCreateOrder("2023-08-01", request);
    return response.data;
  }

  /**
   * Verify the payment status from Cashfree
   * @param orderId The order ID to check
   * @returns boolean indicating if payment was successful
   */
  async verifyPayment(orderId: string): Promise<boolean> {
    const response = await Cashfree.PGOrderFetchPayments("2023-08-01", orderId);
    if (response.data && response.data.length > 0) {
      // Return true if any payment attempt was SUCCESS
      return response.data.some((payment: any) => payment.payment_status === "SUCCESS");
    }
    return false;
  }
}

export default new PaymentService();
