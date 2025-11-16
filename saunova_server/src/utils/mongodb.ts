import mongoose from "mongoose";
import { logError, logInfo } from "../utils/logger";
import { MONGODB_URI } from "./config";

export async function connectDB(): Promise<boolean> {
  try {
    await mongoose.connect(MONGODB_URI);
    logInfo("✅ Connected to MongoDB");
    return true;
  } catch (err) {
    logError(err, "MongoDB connectDB");
    return false;
  }
}

export async function disconnectDB(): Promise<void> {
  try {
    await mongoose.disconnect();
    logInfo("✅ Disconnected from MongoDB");
  } catch (err) {
    logError(err, "MongoDB disconnectDB");
  }
}
