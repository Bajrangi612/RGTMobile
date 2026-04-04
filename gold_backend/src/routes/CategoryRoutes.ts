import { Router } from "express";
import { CategoryController } from "../controllers/CategoryController";

const router = Router();

router.get("/", CategoryController.listCategories);
router.post("/", CategoryController.createCategory); // Admin needed

export default router;
