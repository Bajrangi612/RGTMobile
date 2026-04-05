import { Router } from "express";
import { CategoryController } from "../controllers/CategoryController";
import { authenticate, authorize } from "../middleware/auth";
import { Role } from "@prisma/client";

const router = Router();

router.get("/", CategoryController.listCategories);
router.post("/", authenticate, authorize([Role.ADMIN]), CategoryController.createCategory);
router.delete("/:id", authenticate, authorize([Role.ADMIN]), CategoryController.deleteCategory);

export default router;
