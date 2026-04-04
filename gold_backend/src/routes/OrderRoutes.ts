import { Router } from "express";
import { OrderController } from "../controllers/OrderController";
import { authenticate, authorize } from "../middleware/auth";
import { Role } from "@prisma/client";

const router = Router();

router.post("/start", authenticate, OrderController.startPurchase);
router.post("/verify", authenticate, OrderController.verifyPayment);
router.get("/my", authenticate, OrderController.myOrders);

// Admin only routes
router.get("/", authenticate, authorize([Role.ADMIN]), OrderController.listAllOrders);

export default router;
