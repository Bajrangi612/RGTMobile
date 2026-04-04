import { Router } from "express";
import { ConfigController } from "../controllers/ConfigController";
import { authenticate, authorize } from "../middleware/auth";
import { Role } from "@prisma/client";

const router = Router();

router.get("/", authenticate, authorize([Role.ADMIN]), ConfigController.getConfigs);
router.put("/", authenticate, authorize([Role.ADMIN]), ConfigController.updateConfigs);

export default router;
