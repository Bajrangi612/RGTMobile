import { Router } from "express";
import { UserController } from "../controllers/UserController";
import { authenticate, authorize } from "../middleware/auth";
import { UserRole } from "@prisma/client";

const router = Router();

router.get("/", authenticate, authorize([UserRole.ADMIN]), UserController.listAllUsers);
router.get("/stats", authenticate, authorize([UserRole.ADMIN]), UserController.getStats);
router.post("/kyc", authenticate, UserController.submitKyc); // Customer submits KYC
router.patch("/profile", authenticate, UserController.updateProfile); // Customer updates profile
router.patch("/:id/kyc", authenticate, authorize([UserRole.ADMIN]), UserController.updateKyc);

export default router;
