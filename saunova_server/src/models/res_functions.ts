import { Response } from "express";
import { logDebug, logError } from "../utils/logger";

export function res_success(res: Response, data: any = { success: true }) {
  logDebug(`Success ${res.statusCode}`, "response");
  return res.status(200).json(data);
}

export function res_error(res: Response, error: any, statusCode: number = 500) {
  logError(`Error ${statusCode}: ${error.message || error}`, "response");
  return res.status(statusCode).json({ error: error.message || error });
}
