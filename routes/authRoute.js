// backend/routes/authRoute.js
import express from "express";
import { signup, login, logout, getAdminById, updateAdminProfile, googleLogin, changePassword, forgotPassword, resetPassword } from "../controllers/authController.js";

const router = express.Router();

router.post("/signup", signup); // Only works once
router.post("/login", login);
router.post("/logout", logout);
router.get("/useradmin/:id", getAdminById);
router.put("/updateProfile/:id", updateAdminProfile);
router.post('/google-login', googleLogin);
// Add to authRoute.js
router.put("/change-password/:id", changePassword);

router.post("/forgot-password", forgotPassword);
router.post("/reset-password/:token", resetPassword);

export default router;
