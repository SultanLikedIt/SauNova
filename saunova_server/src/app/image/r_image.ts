import { Router } from "express";
import { res_error, res_success } from "../../models/res_functions";
import { verifyUid, AuthenticatedRequest } from "../../server/middleware";
import { UserModel } from "../../models/mongodb/m_user";
import { ResUser } from "../../models/res_models";

const router = Router();

// set user profile image
router.post("/profile", verifyUid, async (req: AuthenticatedRequest, res) => {
  try {
    const { image_url } = req.body;
    if (!image_url) {
      return res_error(res, "Image URL is required");
    }

    await UserModel.setProfileImage(req.requesterUid!, image_url);

    return res_success(res, "Profile image updated successfully");
  } catch (error) {
    console.error("Error setting profile image:", error);
    return res_error(res, "Internal server error", 500);
  }
});

// delete user profile image
router.delete("/profile", verifyUid, async (req: AuthenticatedRequest, res) => {
  try {
    await UserModel.setProfileImage(req.requesterUid!, null);

    return res_success(res, "Profile image deleted successfully");
  } catch (error) {
    console.error("Error deleting profile image:", error);
    return res_error(res, "Internal server error", 500);
  }
});

export default router;
