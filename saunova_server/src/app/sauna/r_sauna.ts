import { Router } from "express";
import { res_error, res_success } from "../../models/res_functions";
import { verifyUid, AuthenticatedRequest } from "../../server/middleware";
import { Bridge } from "../../python_bridge/bridge";
const router = Router();

router.get(
  "/recommendations",
  verifyUid,
  async (req: AuthenticatedRequest, res) => {
    try {
      const data = await Bridge.getRecommendations(req.requesterUid!);
      if (data) {
        return res_success(res, data);
      } else {
        return res_error(res, "No recommendations found", 404);
      }
    } catch (error) {
      return res_error(res, "Failed to get sauna recommendations", 500);
    }
  }
);

router.post(
  "/start_session",
  verifyUid,
  async (req: AuthenticatedRequest, res) => {
    try {
      const { temperature, humidity, session_length } = req.body;
      if (
        typeof temperature !== "number" ||
        typeof humidity !== "number" ||
        typeof session_length !== "number"
      ) {
        return res_error(res, "Invalid input data", 400);
      }

      Bridge.start_session(
        temperature,
        humidity,
        session_length,
        req.requesterUid!
      );
      return res_success(res, { status: "sauna session started" });
    } catch (error) {
      return res_error(res, "Failed to start sauna session", 500);
    }
  }
);

router.post(
  "/end_session",
  verifyUid,
  async (req: AuthenticatedRequest, res) => {
    try {
      const data = await Bridge.end_session();
      if (data) {
        return res_success(res, data);
      } else {
        return res_error(res, "Failed to end sauna session", 500);
      }
    } catch (error) {
      return res_error(res, "Failed to end sauna session", 500);
    }
  }
);

export default router;
