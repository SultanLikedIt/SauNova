import * as admin from "firebase-admin";
import { logError, logInfo } from "./logger";
import serviceAccount = require("../../firebase.json");

export function initFirebase(): void {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
  });
}

export async function getUserIdFromFirebaseToken(
  token: string
): Promise<string | undefined> {
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    return decodedToken.uid;
  } catch (error) {
    logError(error, "firebase, getUserIdFromFirebaseToken");
    return undefined;
  }
}