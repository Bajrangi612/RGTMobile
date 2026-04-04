import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { errorResponse } from '../utils/response';

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  console.error(`[ERROR] ${err.message}`, err);

  if (err instanceof ZodError) {
    return errorResponse(
      res,
      'Validation Error',
      400,
      err.issues.map((e: any) => ({
        path: e.path.join('.'),
        message: e.message,
      }))
    );
  }

  // Handle Prisma Unique Constraint Errors
  if (err.code === 'P2002') {
    const field = err.meta?.target || 'unknown';
    return errorResponse(res, `Unique constraint failed on field: ${field}`, 409);
  }

  const statusCode = err.status || err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  return errorResponse(res, message, statusCode);
};
