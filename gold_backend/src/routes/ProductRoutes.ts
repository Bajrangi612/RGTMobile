import { Router } from "express";
import { ProductController } from "../controllers/ProductController";
import { authenticate, authorize } from "../middleware/auth";
import { UserRole } from "@prisma/client";

const router = Router();

router.get("/", ProductController.listProducts);
router.get("/price", ProductController.getGoldPrice);
router.get("/:id", ProductController.getProduct);

// Admin only routes
router.post(
  "/",
  authenticate,
  authorize([UserRole.ADMIN]),
  ProductController.createProduct
);

router.patch(
  "/:id",
  authenticate,
  authorize([UserRole.ADMIN]),
  ProductController.updateProduct
);

router.delete(
  "/:id",
  authenticate,
  authorize([UserRole.ADMIN]),
  ProductController.deleteProduct
);

export default router;
