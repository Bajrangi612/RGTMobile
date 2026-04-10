import { Router } from "express";
import { WithdrawalController } from "../controllers/WithdrawalController";
import { authenticate } from "../middleware/auth";

const router = Router();

router.post("/withdraw", authenticate, WithdrawalController.requestWithdrawal);

export default router;
