import { Router } from "express";
import { CategoryController } from "../controllers/CategoryController";
import { authenticate, authorize } from "../middleware/auth";
import { UserRole } from "@prisma/client";

const router = Router();

router.get("/", CategoryController.listCategories);
router.post("/", authenticate, authorize([UserRole.ADMIN]), CategoryController.createCategory);
router.delete("/:id", authenticate, authorize([UserRole.ADMIN]), CategoryController.deleteCategory);

export default router;
