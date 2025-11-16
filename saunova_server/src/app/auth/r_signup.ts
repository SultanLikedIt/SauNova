import { Router } from "express";
import { res_error, res_success } from "../../models/res_functions";
import { verifyUid, AuthenticatedRequest } from "../../server/middleware";
import { UserModel } from "../../models/mongodb/m_user";
import { ResUser } from "../../models/res_models";
import { getRandomBadges } from "../../models/mock/data";
import { getMockFriends } from "../../models/res_models";

const router = Router();

router.post("/signup", verifyUid, async (req: AuthenticatedRequest, res) => {
  try {
    const requesterUid = req.requesterUid!;

    const user = await UserModel.createUser(
      requesterUid,
      req.body.email,
      req.body.image || null
    );

    const res_data: ResUser = {
      user: user,
      sessions: [],
      badges: getRandomBadges(3),
      friends: getMockFriends(),
    };

    return res_success(res, res_data);
  } catch (error) {
    console.error("Error during signup:", error);
    return res_error(res, "Internal server error", 500);
  }
});

router.post(
  "/finish-setup",
  verifyUid,
  async (req: AuthenticatedRequest, res) => {
    try {
      const requesterUid = req.requesterUid!;
      const { gender, height, weight, age, goals } = req.body;

      const updatedUser = await UserModel.finishSetup(
        requesterUid,
        gender,
        height,
        weight,
        age,
        goals
      );

      const res_data: ResUser = {
        user: updatedUser!,
        sessions: [],
        badges: getRandomBadges(3),
        friends: getMockFriends(),
      };

      return res_success(res, res_data);
    } catch (error) {
      return res_error(res, "Internal server error", 500);
    }
  }
);

export default router;
