import { Request, Response, NextFunction } from "express";
import { prisma } from "../lib/prisma";
import { successResponse, errorResponse } from "../utils/response";
import { AuthRequest } from "../middleware/auth";

export class NotificationController {
  /**
   * Get all notifications for the authenticated user
   */
  static async getMyNotifications(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const notifications = await prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: "desc" },
      });

      return successResponse(res, { notifications }, "Notifications fetched successfully");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Mark a single notification as read
   */
  static async markAsRead(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      await prisma.notification.updateMany({
        where: { id: id as string, userId },
        data: { isRead: true }
      });

      return successResponse(res, null, "Notification marked as read");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Mark all notifications as read
   */
  static async markAllAsRead(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;

      await prisma.notification.updateMany({
        where: { userId },
        data: { isRead: true }
      });

      return successResponse(res, null, "All notifications marked as read");
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update User's FCM Token
   */
  static async updateFcmToken(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { token } = req.body;
      const userId = req.user!.id;

      if (!token) return errorResponse(res, "Token is required", 400);

      await prisma.user.update({
        where: { id: userId },
        data: { fcmToken: token }
      });

      return successResponse(res, null, "FCM token updated successfully");
    } catch (error) {
      next(error);
    }
  }
}
