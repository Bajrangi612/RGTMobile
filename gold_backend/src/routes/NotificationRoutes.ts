import { Router } from "express";
import { NotificationController } from "../controllers/NotificationController";
import { authenticate } from "../middleware/auth";

const router = Router();

router.use(authenticate);

router.get("/", NotificationController.getMyNotifications);
router.put("/read-all", NotificationController.markAllAsRead);
router.put("/:id/read", NotificationController.markAsRead);
router.post("/token", NotificationController.updateFcmToken);

export default router;
