import { Response, NextFunction } from "express";
import OrderService from "../services/OrderService";
import { AuthRequest } from "../middleware/auth";
import { successResponse, errorResponse } from "../utils/response";

export class OrderController {
  /**
   * Start a purchase (Create Order + Razorpay Order)
   */
  static async startPurchase(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { productId, quantity, referralCode } = req.body;
      const userId = req.user!.id;

      if (!productId || !quantity) {
        return errorResponse(res, "Product ID and Quantity are required", 400);
      }

      const orderData = await OrderService.createPurchaseOrder(
        userId, 
        productId, 
        Number(quantity),
        referralCode
      );
      
      return successResponse(res, orderData, "Order initiated successfully", 201);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Verify the payment from the mobile app via Cashfree
   */
  static async verifyPayment(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { orderId, razorpayPaymentId, razorpaySignature } = req.body;
      const userId = req.user!.id;

      if (!orderId || !razorpayPaymentId || !razorpaySignature) {
        return errorResponse(res, "Order ID, Payment ID, and Signature are required", 400);
      }

      const order = await OrderService.verifyAndFinalizeOrder(
        userId,
        orderId,
        razorpayPaymentId,
        razorpaySignature
      );

      return successResponse(res, { order }, "Payment verified and order completed");
    } catch (error) {
      next(error);
    }
  }

  /**
   * List all orders for the current user
   */
  static async myOrders(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const orders = await OrderService.getUserOrders(userId);

      return successResponse(res, { orders }, "Orders fetched successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * List all orders in the system (Admin only)
   */
  static async listAllOrders(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const orders = await OrderService.getAllOrders();
      return successResponse(res, { orders }, "All orders fetched successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update order status (Admin only)
   */
  static async updateStatus(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const id = req.params.id as string;
      const { status } = req.body;
      const order = await OrderService.updateOrderStatus(id, status);
      return successResponse(res, { order }, "Order status updated successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Cancel an order
   */
  static async cancel(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const orderId = req.params.id as string;
      const userId = req.user!.id as string;
      const order = await OrderService.cancelOrder(orderId, userId);
      return successResponse(res, { order }, "Order cancelled successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Sell back an order
   */
  static async sellBack(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const orderId = req.params.id as string;
      const userId = req.user!.id as string;
      const order = await OrderService.initiateBuyback(orderId, userId);
      return successResponse(res, { order }, "Order sold back successfully");
    } catch (error) {
      next(error);
    }
  }
}
