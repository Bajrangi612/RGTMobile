import { Request, Response, NextFunction } from 'express';
import { errorResponse } from '../utils/response';

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  console.error(`[ERROR] ${err.stack || err.message}`);

  const statusCode = err.statusCode || 500;
  const message = process.env.NODE_ENV === 'production' 
    ? 'An unexpected error occurred. Please try again later.' 
    : err.message || 'Internal Server Error';

  return errorResponse(res, message, statusCode);
};
