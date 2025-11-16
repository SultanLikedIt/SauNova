import { NextFunction, Request, Response } from "express";
import multer from "multer";
import { getUserIdFromFirebaseToken } from "../utils/firebase";
import { res_error } from "../models/res_functions";

// Multer memory storage
const storage = multer.memoryStorage();
export const upload = multer({ storage });

export interface AuthenticatedRequest extends Request {
  requesterUid?: string;
}

export async function verifyUid(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const token = req.headers.authorization?.split("Bearer ")[1];

    if (!token) {
      return res_error(res, "Missing authorization header", 401);
    }

    const uid = await getUserIdFromFirebaseToken(token);
    if (!uid) {
      return res_error(res, "Invalid token", 401);
    }

    req.requesterUid = uid;
    next();
  } catch (err) {
    return res_error(res, "Invalid or missing authorization header", 401);
  }
}
