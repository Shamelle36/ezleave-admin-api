// backend/routes/authRoute.js
import express from "express";
import { signup, login, logout, getAdminById, updateAdminProfile } from "../controllers/authController.js";

const router = express.Router();

router.post("/signup", signup); // Only works once
router.post("/login", login);
router.post("/logout", logout);
router.get("/useradmin/:id", getAdminById);
router.put("/updateProfile/:id", updateAdminProfile);

export default router;
