import { Router } from "express";
import { ProductController } from "../controllers/ProductController";
import { authenticate, authorize } from "../middleware/auth";
import { Role } from "@prisma/client";

const router = Router();

router.get("/", ProductController.listProducts);
router.get("/:id", ProductController.getProduct);

// Admin only routes
router.post(
  "/",
  authenticate,
  authorize([Role.ADMIN]),
  ProductController.createProduct
);

router.patch(
  "/:id",
  authenticate,
  authorize([Role.ADMIN]),
  ProductController.updateProduct
);

router.delete(
  "/:id",
  authenticate,
  authorize([Role.ADMIN]),
  ProductController.deleteProduct
);

export default router;
