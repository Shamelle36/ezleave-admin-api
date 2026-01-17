// backend/routes/adminAuthRoute.js
import express from "express";
import {
  createAccount,
  setupPassword,
  login,
  fetchAccounts,
  getUserById,
  updateProfile,
  googleLogin,
  updateAccount,
  fetchInactiveAccounts,
  deactivateAccount,
  restoreAccount,
  resetPassword,
  processPasswordReset,
  changePassword
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

router.post("/google-login", googleLogin);

router.put("/accounts/:id", updateAccount);

// In adminAuthRoutes.js or similar
router.get('/accounts/inactive', fetchInactiveAccounts);
router.put('/accounts/:id/deactivate', deactivateAccount);
router.put('/accounts/:id/restore', restoreAccount);
router.post('/reset-password/:id', resetPassword);
router.post('/process-reset/:token', processPasswordReset);

// Add to adminAuthRoute.js
router.put("/change-password/:id", changePassword);

export default router;
