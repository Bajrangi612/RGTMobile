import { Router } from "express";
import { WalletController } from "../controllers/WalletController";
import { authenticate } from "../middleware/auth";

const router = Router();

router.get("/details", authenticate, WalletController.getWalletDetails);
router.post("/withdraw", authenticate, WalletController.requestWithdrawal);

export default router;
