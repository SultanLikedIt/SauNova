import { Router } from "express";
import r_login from "./r_login";
import r_signup from "./r_signup";

const router = Router();

router.use(r_login);
router.use(r_signup);

export default router;
