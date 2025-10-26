// backend/routes/adminAuthRoute.js
import express from "express";
import {
  createAccount,
  setupPassword,
  login,
  fetchAccounts,
  getUserById,
  updateProfile,
} from "../controllers/adminAuthController.js";

const router = express.Router();

router.get("/accounts", fetchAccounts)
// Admin creates account (head or mayor)
router.post("/createAccount", createAccount);

// Setup password (for heads and mayor)
router.post("/setup-password/:token", setupPassword);

// Login (for admin, head, mayor)
router.post("/login", login);

router.get("/user/:id", getUserById);

router.put("/update/:id", updateProfile); 

export default router;
