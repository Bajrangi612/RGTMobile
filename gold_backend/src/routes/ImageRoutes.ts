import { Router } from "express";
import multer from "multer";
import { ImageController } from "../controllers/ImageController";
import { authenticate } from "../middleware/auth";

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post("/upload", authenticate, upload.single("image"), ImageController.uploadImage);

export default router;
