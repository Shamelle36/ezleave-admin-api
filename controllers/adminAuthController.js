// backend/controllers/adminAuthController.js
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { v4 as uuidv4 } from "uuid";
import sql from "../config/db.js";

// Utility: generate JWT token
const generateToken = (user) => {
  return jwt.sign(
    {
      id: user.id,
      role: user.role,
      department: user.department,
    },
    process.env.JWT_SECRET,
    { expiresIn: "7d" }
  );
};

// 🟢 Fetch all admin accounts
export const fetchAccounts = async (req, res) => {
  try {
    const accounts = await sql`
      SELECT id, full_name, email, role, department, status, created_at, last_login
      FROM admin_accounts
      ORDER BY full_name ASC
    `;

    res.json({ accounts });
  } catch (err) {
    console.error("❌ Error fetching accounts:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

// 🟢 Fetch inactive admin accounts
export const fetchInactiveAccounts = async (req, res) => {
  try {
    const accounts = await sql`
      SELECT id, full_name, email, role, department, status, created_at, last_login, deactivated_at
      FROM admin_accounts
      WHERE status = 'inactive'
      ORDER BY deactivated_at DESC
    `;

    res.json({ accounts });
  } catch (err) {
    console.error("❌ Error fetching inactive accounts:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

// 🟢 Create Account (plain password)
export const createAccount = async (req, res) => {
  try {
    let { full_name, email, role, department, password: tempPassword } = req.body;

    // Validate required fields
    if (!full_name || !email || !role || !tempPassword) {
      return res.status(400).json({ 
        message: "Missing required fields: full_name, email, role, or password" 
      });
    }

    // Normalize role for DB
    role = role.toLowerCase().replace(" ", "_");

    console.log(`🔵 Creating account for: ${email}, Role: ${role}, Department: ${department}`);

    // Check if email already exists
    const existing = await sql`
      SELECT * FROM admin_accounts WHERE email = ${email}
    `;
    
    if (existing.length > 0) {
      const existingAccount = existing[0];
      if (existingAccount.status === "inactive") {
        return res.status(400).json({
          message: "This email belongs to an inactive account. Please restore it instead.",
        });
      }
      return res.status(400).json({ message: "Email already exists." });
    }

    // Insert into DB with plain password (no hash)
    const [user] = await sql`
      INSERT INTO admin_accounts (full_name, email, role, department, status, password_hash)
      VALUES (${full_name}, ${email}, ${role}, ${department}, 'active', ${tempPassword})
      RETURNING *
    `;

    console.log(`✅ DB record created: ${user.id}`);

    res.status(201).json({
      message: "✅ Account created successfully!",
      details: `User can login with temporary password sent via Firebase.`,
      userId: user.id,
      email: user.email,
      temporaryPassword: tempPassword,
      note: "Please change password after first login",
    });

  } catch (err) {
    console.error("❌ Error creating account:", err);
    res.status(500).json({ 
      message: "Failed to create account",
      error: err.message 
    });
  }
};

// 🟢 Login (plain password comparison)
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const users = await sql`
      SELECT * FROM admin_accounts WHERE email = ${email}
    `;
    const user = users[0];

    if (!user) {
      return res.status(400).json({ message: "Account not found." });
    }

    // Check if account is inactive
    if (user.status === 'inactive') {
      return res.status(401).json({ 
        message: "Account is inactive. Please contact administrator to restore your account." 
      });
    }

    // Check password directly (no hashing)
    if (password !== user.password_hash) {
      return res.status(401).json({ message: "Invalid credentials." });
    }

    // Update last login timestamp
    await sql`
      UPDATE admin_accounts
      SET last_login = NOW()
      WHERE id = ${user.id}
    `;

    const token = generateToken(user);

    res.json({
      message: "Login successful.",
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        role: user.role,
        department: user.department,
        status: user.status,
      },
    });
  } catch (err) {
    console.error("❌ Error during login:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};


export const getUserById = async (req, res) => {
  const { id } = req.params;

  try {
    const user = await sql`
      SELECT id, full_name, email, role, department, profile_picture, status
      FROM admin_accounts
      WHERE id = ${id}
    `;

    if (user.length === 0)
      return res.status(404).json({ message: "User not found." });

    res.json(user[0]);
  } catch (err) {
    console.error("❌ Error fetching user by ID:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

// 🟢 5. Update admin profile
export const updateProfile = async (req, res) => {
  console.log("=== UPDATE OFFICE HEAD PROFILE REQUEST ===");
  console.log("Params:", req.params);
  console.log("Body:", req.body);

  const { id } = req.params;
  const { full_name, department, profile_picture } = req.body;

  try {
    if (!full_name && !department && !profile_picture) {
      return res.status(400).json({ message: "No fields to update." });
    }

    // Check if account is active
    const userCheck = await sql`
      SELECT status FROM admin_accounts WHERE id = ${id}
    `;
    
    if (userCheck.length === 0) {
      return res.status(404).json({ message: "Account not found." });
    }
    
    if (userCheck[0].status === 'inactive') {
      return res.status(400).json({ message: "Cannot update inactive account." });
    }

    // Only update fields that are defined
    const updates = {};
    if (full_name !== undefined) updates.full_name = full_name;
    if (department !== undefined) updates.department = department;
    if (profile_picture !== undefined) updates.profile_picture = profile_picture;

    await sql`
      UPDATE admin_accounts
      SET ${sql(updates)}
      WHERE id = ${id}
    `;

    res.json({ message: "✅ Office Head profile updated successfully!" });
  } catch (err) {
    console.error("❌ Error updating office head profile:", err);
    res.status(500).json({ message: "Failed to update profile." });
  }
};

export const googleLogin = async (req, res) => {
  try {
    const { credential } = req.body;
    
    if (!credential) {
      return res.status(400).json({ message: "No Google credential provided" });
    }

    // Decode JWT token from Google
    const payload = JSON.parse(Buffer.from(credential.split('.')[1], 'base64').toString());
    const { email, name, picture } = payload;

    console.log(`🔵 Google login attempt (Office): ${email} from IP: ${req.ip}`);

    // Check if user exists in admin_accounts table
    const users = await sql`
      SELECT * FROM admin_accounts WHERE email = ${email}
    `;
    const user = users[0];

    if (!user) {
      // User doesn't exist - don't create new account
      return res.status(401).json({ 
        message: "Google account not registered. Please sign in with your department credentials or contact admin." 
      });
    }

    // Check if account is inactive
    if (user.status === 'inactive') {
      return res.status(401).json({ 
        message: "Account is inactive. Please contact administrator to restore your account." 
      });
    }

    if (!user.password_hash) {
      return res.status(400).json({ 
        message: "Account not fully set up. Please check your email for setup link." 
      });
    }

    // Log successful Google login
    console.log(`✅ Google login successful for office user: ${email}, Role: ${user.role}`);

    // Update last login timestamp
    await sql`
      UPDATE admin_accounts
      SET last_login = NOW()
      WHERE id = ${user.id}
    `;

    // Generate JWT token
    const token = generateToken(user);

    res.json({
      message: "Google login successful",
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        role: user.role,
        department: user.department,
        status: user.status,
        profile_picture: user.profile_picture || picture,
      },
    });

  } catch (error) {
    console.error("❌ Google login error:", error);
    
    res.status(401).json({ 
      message: error.response?.data?.message || "Google authentication failed" 
    });
  }
};

// 🟢 6. Update admin account
export const updateAccount = async (req, res) => {
  console.log("=== UPDATE ADMIN ACCOUNT REQUEST ===");
  console.log("Params:", req.params);
  console.log("Body:", req.body);

  const { id } = req.params;
  const { full_name, email, role, department } = req.body;

  try {
    // Validate required fields
    if (!full_name || !email) {
      return res.status(400).json({ message: "Full name and email are required." });
    }

    // Check if email already exists (excluding current user)
    const existing = await sql`
      SELECT * FROM admin_accounts 
      WHERE email = ${email} AND id != ${id}
    `;

    if (existing.length > 0) {
      return res.status(400).json({ message: "Email already exists for another account." });
    }

    // Check if account is active
    const userCheck = await sql`
      SELECT status FROM admin_accounts WHERE id = ${id}
    `;
    
    if (userCheck.length === 0) {
      return res.status(404).json({ message: "Account not found." });
    }
    
    if (userCheck[0].status === 'inactive') {
      return res.status(400).json({ message: "Cannot update inactive account. Restore it first." });
    }

    // Normalize role if provided
    const normalizedRole = role ? role.toLowerCase().replace(" ", "_") : null;

    // Prepare updates
    const updates = {
      full_name,
      email
    };
    
    if (normalizedRole) updates.role = normalizedRole;
    if (department !== undefined) updates.department = department;

    // Update the account
    const [updatedAccount] = await sql`
      UPDATE admin_accounts
      SET ${sql(updates)}
      WHERE id = ${id}
      RETURNING id, full_name, email, role, department, status
    `;

    console.log(`✅ Account ${id} updated successfully`);
    res.json({ 
      message: "✅ Account updated successfully!",
      account: updatedAccount
    });
  } catch (err) {
    console.error("❌ Error updating account:", err);
    res.status(500).json({ message: "Failed to update account." });
  }
};

// 🟢 7. Deactivate admin account
export const deactivateAccount = async (req, res) => {
  console.log("=== DEACTIVATE ADMIN ACCOUNT REQUEST ===");
  console.log("Params:", req.params);

  const { id } = req.params;

  try {
    // Check if account exists
    const users = await sql`
      SELECT * FROM admin_accounts WHERE id = ${id}
    `;
    
    if (users.length === 0) {
      return res.status(404).json({ message: "Account not found." });
    }
    
    const user = users[0];
    
    // Check if account is already inactive
    if (user.status === 'inactive') {
      return res.status(400).json({ message: "Account is already inactive." });
    }
    
    // Prevent deactivating yourself
    const adminId = req.user?.id;
    if (adminId && adminId.toString() === id.toString()) {
      return res.status(400).json({ message: "You cannot deactivate your own account." });
    }

    // Deactivate the account
    await sql`
      UPDATE admin_accounts
      SET status = 'inactive', deactivated_at = NOW()
      WHERE id = ${id}
    `;

    console.log(`✅ Account ${id} deactivated successfully`);
    res.json({ 
      message: "✅ Account deactivated successfully!",
      account: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        status: 'inactive'
      }
    });
  } catch (err) {
    console.error("❌ Error deactivating account:", err);
    res.status(500).json({ message: "Failed to deactivate account." });
  }
};

// 🟢 8. Restore inactive admin account
export const restoreAccount = async (req, res) => {
  console.log("=== RESTORE ADMIN ACCOUNT REQUEST ===");
  console.log("Params:", req.params);

  const { id } = req.params;

  try {
    // Check if account exists
    const users = await sql`
      SELECT * FROM admin_accounts WHERE id = ${id}
    `;
    
    if (users.length === 0) {
      return res.status(404).json({ message: "Account not found." });
    }
    
    const user = users[0];
    
    // Check if account is already active
    if (user.status === 'active') {
      return res.status(400).json({ message: "Account is already active." });
    }

    // Restore the account
    await sql`
      UPDATE admin_accounts
      SET status = 'active', deactivated_at = NULL
      WHERE id = ${id}
    `;

    console.log(`✅ Account ${id} restored successfully`);
    res.json({ 
      message: "✅ Account restored successfully!",
      account: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        status: 'active'
      }
    });
  } catch (err) {
    console.error("❌ Error restoring account:", err);
    res.status(500).json({ message: "Failed to restore account." });
  }
};

// 🟢 9. Reset password for admin account (Simplified)
export const resetPassword = async (req, res) => {
  console.log("=== RESET PASSWORD REQUEST ===");
  console.log("Params:", req.params);

  const { id } = req.params;

  try {
    // Check if account exists
    const users = await sql`
      SELECT * FROM admin_accounts WHERE id = ${id}
    `;
    
    if (users.length === 0) {
      return res.status(404).json({ message: "Account not found." });
    }
    
    const user = users[0];
    
    // Check if account is active
    if (user.status === 'inactive') {
      return res.status(400).json({ 
        message: "Cannot reset password for inactive account. Restore the account first." 
      });
    }

    // Generate a new temporary password
    const tempPassword = Math.random().toString(36).slice(-8) + "A1!";
    const hashedPassword = await bcrypt.hash(tempPassword, 10);
    
    await sql`
      UPDATE admin_accounts
      SET password_hash = ${hashedPassword}
      WHERE id = ${user.id}
    `;

    console.log(`✅ Password reset for account ${id}`);
    
    return res.json({ 
      message: "✅ Password reset successfully!",
      temporaryPassword: tempPassword,
      note: "Share this temporary password with the user. They should change it after first login."
    });

  } catch (err) {
    console.error("❌ Error resetting password:", err);
    res.status(500).json({ message: "Failed to reset password." });
  }
};

// 🟢 10. Process password reset with token
export const processPasswordReset = async (req, res) => {
  try {
    const { token } = req.params;
    const { password } = req.body;

    const tokens = await sql`
      SELECT * FROM password_tokens
      WHERE token = ${token} AND type = 'reset' AND used = false
    `;

    if (tokens.length === 0) {
      return res.status(400).json({ message: "Invalid or expired token." });
    }

    const tokenData = tokens[0];
    const now = new Date();

    if (new Date(tokenData.expires_at) < now) {
      return res.status(400).json({ message: "Token expired." });
    }

    // Check if account is active
    const userCheck = await sql`
      SELECT status FROM admin_accounts WHERE id = ${tokenData.user_id}
    `;
    
    if (userCheck.length === 0) {
      return res.status(400).json({ message: "Account not found." });
    }
    
    if (userCheck[0].status === 'inactive') {
      return res.status(400).json({ message: "Account is inactive. Please contact administrator." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await sql`
      UPDATE admin_accounts
      SET password_hash = ${hashedPassword}
      WHERE id = ${tokenData.user_id}
    `;

    await sql`
      UPDATE password_tokens
      SET used = true
      WHERE id = ${tokenData.id}
    `;

    res.json({ message: "Password reset successful. You can now log in with your new password." });
  } catch (err) {
    console.error("❌ Error processing password reset:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

// Add to adminAuthController.js
export const changePassword = async (req, res) => {
  try {
    const { id } = req.params;
    const { currentPassword, newPassword } = req.body;

    // Find user
    const result = await sql`
      SELECT * FROM admin_accounts WHERE id = ${id}
    `;

    if (result.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    const user = result[0];

    // Check if account is active
    if (user.status === 'inactive') {
      return res.status(400).json({ message: "Account is inactive" });
    }

    // Verify current password
    const isValid = await bcrypt.compare(currentPassword, user.password_hash);
    if (!isValid) {
      return res.status(400).json({ message: "Current password is incorrect" });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password
    await sql`
      UPDATE admin_accounts
      SET password_hash = ${hashedPassword}
      WHERE id = ${id}
    `;

    res.json({ message: "Password updated successfully" });
  } catch (err) {
    console.error("Error changing password:", err);
    res.status(500).json({ message: "Server error" });
  }
};

export const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }

    console.log(`🔐 Forgot password request for: ${email}`);

    // Check if user exists
    const users = await sql`
      SELECT * FROM admin_accounts WHERE email = ${email}
    `;

    if (users.length === 0) {
      console.log(`❌ Email not found: ${email}`);
      return res.status(200).json({ 
        message: "If your email exists in our system, you will receive password reset instructions." 
      });
    }

    const user = users[0];
    console.log(`✅ User found: ${user.full_name} (${user.email})`);

    // Check if account is inactive
    if (user.status === 'inactive') {
      console.log(`⚠️ Account inactive: ${email}`);
      return res.status(400).json({ 
        message: "Account is inactive. Please contact administrator to restore your account." 
      });
    }

    // Generate a reset token
    const token = uuidv4();
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60);
    const resetLink = `https://ezleave-admin.vercel.app/reset-password?token=${token}`;

    // Delete any existing reset tokens
    await sql`
      DELETE FROM password_tokens 
      WHERE user_id = ${user.id} AND type = 'reset'
    `;

    // Insert new reset token
    await sql`
      INSERT INTO password_tokens (user_id, token, type, expires_at)
      VALUES (${user.id}, ${token}, 'reset', ${expiresAt})
    `;

    console.log(`🔗 Reset token generated for: ${email}`);
    
    return res.status(200).json({ 
      message: "Password reset token generated.",
      resetToken: token,
      resetLink: resetLink,
      note: "Use this token/link for password reset"
    });

  } catch (err) {
    console.error("❌ Forgot password error:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};