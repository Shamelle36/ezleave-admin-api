// backend/routes/authRoute.js
import express from "express";
import { unifiedLogin } from "../controllers/authUnifiedController.js";

const router = express.Router();

router.post("/unified-login", unifiedLogin);

export default router;
