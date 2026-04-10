import { Router } from "express";
import { ConfigController } from "../controllers/ConfigController";
import { authenticate, authorize } from "../middleware/auth";
import { UserRole } from "@prisma/client";

const router = Router();

router.get("/public", authenticate, ConfigController.getPublicConfigs);
router.get("/", authenticate, authorize([UserRole.ADMIN]), ConfigController.getConfigs);
router.put("/", authenticate, authorize([UserRole.ADMIN]), ConfigController.updateConfigs);

export default router;
