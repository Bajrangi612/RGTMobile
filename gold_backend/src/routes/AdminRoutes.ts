import { Router } from "express";
import { AdminController } from "../controllers/AdminController";
import { authenticate, authorize } from "../middleware/auth";
import { UserRole } from "@prisma/client";

const router = Router();

// Middleware: All routes require authentication and Admin role
router.use(authenticate, authorize([UserRole.ADMIN]));

/**
 * @route GET /api/admin/stats
 * @desc Get basic business metrics
 */
router.get("/stats", AdminController.getDashboardStats);

/**
 * @route POST /api/admin/gold-price
 * @desc Update the global gold buy/sell rates
 */
router.post("/gold-price", AdminController.updateGoldPrice);

export default router;
