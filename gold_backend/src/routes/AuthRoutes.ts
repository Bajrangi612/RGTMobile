import { Router } from 'express';
import { AuthController } from '../controllers/AuthController';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/me', authenticate, AuthController.me);
router.post('/send-otp', AuthController.sendOtp);
router.post('/verify-otp', AuthController.verifyOtp);
router.post('/admin-login', AuthController.adminLogin);
router.get('/referral-check/:code', AuthController.verifyReferralCode);

export default router;
