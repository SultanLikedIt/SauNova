import { Router } from "express";
import { res_error, res_success } from "../../models/res_functions";
import { verifyUid, AuthenticatedRequest } from "../../server/middleware";
import { Bridge } from "../../python_bridge/bridge";

const router = Router();

router.post("/ask", verifyUid, async (req: AuthenticatedRequest, res) => {
  try {
    const { question } = req.body;
    const requesterUid = req.requesterUid!;

    if (!question) {
      return res_error(res, "Question is required", 400);
    }

    const answerData = await Bridge.ask(question);

    return res_success(res, answerData);
  } catch (error) {
    return res_error(res, "Internal server error", 500);
  }
});

export default router;
