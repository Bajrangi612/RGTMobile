import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { errorResponse } from "../utils/response";

export interface AuthRequest extends Request {
  user?: {
    id: string;
    role: string;
  };
}

import { prisma } from "../lib/prisma";

export const authenticate = async (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return errorResponse(res, "Access denied. No token provided.", 401);
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as {
      id: string;
      role: string;
    };

    // Verify user still exists in DB (to prevent stale tokens after DB wipe)
    // console.log(`🔍 [Auth] Checking existence for UID: ${decoded.id}`);
    const userExists = await prisma.user.findUnique({
      where: { id: decoded.id },
      select: { id: true, role: true }
    });

    if (!userExists) {
      // console.log(`❌ [Auth] Stale token detected. User ${decoded.id} not found.`);
      return errorResponse(res, "Account no longer exists. Please log in again.", 401);
    }

    // console.log(`✅ [Auth] User verified: ${decoded.id}`);

    req.user = decoded;
    next();
  } catch (error) {
    return errorResponse(res, "Invalid or expired token.", 401);
  }
};

export const authorize = (roles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return errorResponse(res, "Forbidden. Insufficient permissions.", 403);
    }
    next();
  };
};
