import { Router } from "express";
import { BankController } from "../controllers/BankController";
import { authenticate, authorize } from "../middleware/auth";
import { UserRole } from "@prisma/client";

const router = Router();

// Customer routes
router.get("/my", authenticate, BankController.getBankDetails);
router.post("/submit", authenticate, BankController.submitBankDetails);

// Admin routes
router.patch("/:userId/status", authenticate, authorize([UserRole.ADMIN]), BankController.updateBankStatus);

export default router;
