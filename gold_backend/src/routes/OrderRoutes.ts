import { Router } from "express";
import { OrderController } from "../controllers/OrderController";
import { authenticate, authorize } from "../middleware/auth";
import { UserRole } from "@prisma/client";

const router = Router();

router.post("/start", authenticate, OrderController.startPurchase);
router.post("/verify", authenticate, OrderController.verifyPayment);
router.get("/my", authenticate, OrderController.myOrders);
router.put("/:id/cancel", authenticate, OrderController.cancel);
router.put("/:id/sell-back", authenticate, OrderController.sellBack);

// Admin only routes
router.get("/", authenticate, authorize([UserRole.ADMIN]), OrderController.listAllOrders);
router.patch("/:id/status", authenticate, authorize([UserRole.ADMIN]), OrderController.updateStatus);

export default router;
