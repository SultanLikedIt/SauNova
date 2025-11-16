import * as dotenv from "dotenv";
dotenv.config();

function getEnvVarOrThrow(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

export const MONGODB_URI = getEnvVarOrThrow("MONGODB_URI");
export const PORT = parseInt(getEnvVarOrThrow("PORT"), 10);
export const IP = getEnvVarOrThrow("IP");
export const SECRET = getEnvVarOrThrow("SECRET");
// export const BRIDGE_URL = getEnvVarOrThrow("BRIDGE_URL");