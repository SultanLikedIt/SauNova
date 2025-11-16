import { Router } from "express";
import { res_error, res_success } from "../../models/res_functions";
import { verifyUid, AuthenticatedRequest } from "../../server/middleware";
import { UserModel } from "../../models/mongodb/m_user";
import { getMockFriends, ResUser } from "../../models/res_models";
import { Session } from "inspector";
import { SessionModel } from "../../models/mongodb/m_session";
import { getRandomBadges } from "../../models/mock/data";

const router = Router();

router.get("/login", verifyUid, async (req: AuthenticatedRequest, res) => {
  try {
    console.log("Login request received");
    const requesterUid = req.requesterUid!;

    const user = await UserModel.findByFirebaseID(requesterUid);

    if (!user) {
      return res_error(res, "User not found", 404);
    }

    const sessions = await SessionModel.findByUserID(req.requesterUid!);

    const res_data: ResUser = {
      user: user,
      sessions: sessions,
      badges: getRandomBadges(3),
      friends: getMockFriends(),
    };

    return res_success(res, res_data);
  } catch (error) {
    return res_error(res, "Internal server error", 500);
  }
});

export default router;
