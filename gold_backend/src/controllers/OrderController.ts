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
      const { productId, quantity } = req.body;
      const userId = req.user!.id;

      if (!productId || !quantity) {
        return errorResponse(res, "Product ID and Quantity are required", 400);
      }

      const orderData = await OrderService.createPurchaseOrder(userId, productId, Number(quantity));
      
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
      const { orderId } = req.body;
      const userId = req.user!.id;

      if (!orderId) {
        return errorResponse(res, "Order ID is required to verify payment", 400);
      }

      const order = await OrderService.verifyAndFinalizeOrder(
        userId,
        orderId
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
}
