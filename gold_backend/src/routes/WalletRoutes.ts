import { Router } from "express";
import { WalletController } from "../controllers/WalletController";
import { WithdrawalController } from "../controllers/WithdrawalController";
import { authenticate } from "../middleware/auth";

const router = Router();

router.get("/details", authenticate, WalletController.getWalletDetails);
router.post("/withdraw", authenticate, WalletController.requestWithdrawal);
router.get("/my-withdrawals", authenticate, WithdrawalController.myWithdrawals);

export default router;
