import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { errorHandler } from './middleware/error';
import { successResponse } from './utils/response';
import authRoutes from './routes/AuthRoutes';
import productRoutes from './routes/ProductRoutes';
import orderRoutes from './routes/OrderRoutes';
import imageRoutes from './routes/ImageRoutes';
import userRoutes from './routes/UserRoutes';
import configRoutes from './routes/ConfigRoutes';
import categoryRoutes from './routes/CategoryRoutes';
import bankRoutes from './routes/BankRoutes';
import walletRoutes from './routes/WalletRoutes';
import adminRoutes from './routes/AdminRoutes';

dotenv.config();

const app = express();
const port = process.env.PORT || 4002;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

// Health Check
app.get('/health', (req, res) => {
  return successResponse(res, { status: 'OK' }, 'Server is healthy');
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/images', imageRoutes);
app.use('/api/users', userRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/bank', bankRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/admin', adminRoutes);

// Routes Placeholder
// Routes Placeholder
// app.use('/api/auth', authRoutes);
// app.use('/api/users', userRoutes);
// app.use('/api/wallet', walletRoutes);
// app.use('/api/gold', goldRoutes);
app.use('/api/configs', configRoutes);

// Global Error Handler
app.use(errorHandler);

app.listen(port, () => {
  console.log(`🚀 [SERVER] Gold Backend is running at http://localhost:${port}`);
});
