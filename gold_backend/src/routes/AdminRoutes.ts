import { Router } from "express";
import { AdminController } from "../controllers/AdminController";
import { WithdrawalController } from "../controllers/WithdrawalController";
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
router.put("/stock", AdminController.updateStock);
router.get("/transactions", AdminController.getAllTransactions);
router.post("/settings", AdminController.updateSettings);

// Withdrawal Management
router.get("/withdrawals", WithdrawalController.listWithdrawals);
router.patch("/withdrawals/:id/status", WithdrawalController.updateStatus);

export default router;
