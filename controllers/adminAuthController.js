// backend/controllers/adminAuthController.js
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { v4 as uuidv4 } from "uuid";
import sql from "../config/db.js"; // your Neon DB connection using postgres package
import nodemailer from "nodemailer";
import admin from "firebase-admin";

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

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: "ezleave-admin",
      clientEmail: "firebase-adminsdk-fbsvc@ezleave-admin.iam.gserviceaccount.com",
      privateKey: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC1xptkahGhxfbr\nCjCqSNmA6Bb/piU37iXKkO7Y6TsfVLj+bPDnOrlONq+9jQAGuG3t9m+bcieKsvoT\nElbgnoYt63aDHukmVp2TQ/uBeTGMMmkQn/fLkPLpG58Fa/JjPNm5N8+OBwu1THtk\nONP/s6I+CzSzqnWHm6GMIw/+Lu6K1/WbPWhH2Jv4FZ1Bnm3AGlpLrvwmSQG/Xrqj\no6RCK16vOk35qKzcwa4yT2GlfqYf+sSbLnF2HSFnN+gOY1CpbRqekSNhDVJfsPso\n0Htm2aEfiRx09CHADlLU018pMJtaAp6TDk7izyKO4UBSUqGOC80iZC7FyBSQMm/g\nVEcnFoePAgMBAAECggEATEsD/HTCWr4+gO7hdw8lbwO6Z2lh9KQZK3iCLvtRC7jg\n/jRWNg7BKNEuGKYd7TQqO3az6C/U5dNxv2Byo0sVsR9DOgxWufcfouglHvXxdFDS\nJR6m/8MiGPG1YC6q6Ljo/uKsVAWkBd+IaIurewZ3oYfNgl0YgCazeqBavYoQJ6h/\n9N+7gD/7AidV8h2j94qibS3lii7wAIGznV/e5PApKdLhoelFRIewF5Qst81xhRp7\nydPoQY7Sz6mXp42WxupEF+HiaC6rs9NG9NJo1e0W5yMdhikrjpD6Vbvgs12X3tat\nwGG4N1JthcEvBtglkE7ZLDXBvhh2LCQ31x74pHibfQKBgQDpN50n1rro1LwXe6wo\nM6rpPJvZiJlXgb8fvvBCQEzI7WOXs5sBMWlIo+ZaXSA964nrlHcm08Y6s0vbyXbZ\n+BD5uNxxJYcgVMpmk6XYoWMhHRW81vYifZlAC3jb+DLZfTqsliKcurbw73zLSewz\nlFq3Lj8ft2C53xVMzAKP3s4duwKBgQDHiIarEjH48ELO43xTHce0LpInVEOrt2SW\nw9ooUgBUsV6offhYyeVE8nYl/bGE7OwGhSOTkWLe/gBL+Tp9Uu1W1YC0ij283TyT\n/tQ0tterk+J35qKjfc/LEM9VSsvoSVwDLV9kxPmLBK1pSFidRy6GMuufLMLKvvCy\nYQrVC9w2PQKBgQDYPUasT7+Sbt3P8E3aIL4R8K6Y7r0vlBAAgWwIIdKQYvv7Bv9s\nBcKXJdFKbBqfDywckNZB3A5rEx/9NDnNNOOYiD1tc9xsr/HTVodp64ocg/lJ1Q73\nP/m+lmSDoQiU/DZRHAwPwlgp4gSWAX7O/Hl4a5r/72nyLdR0Fp0xhOccTQKBgAdw\n4/TFPO/XpeYpPZ2r4qKpifHFhrCEqk+lBiGyzShbZPhLmlNVVCN6F0XbbB9U5ohn\ntqfuKA3A0yoCJVg/G3K9i4swDJVaesPaIPfGScywOyXViAMo0fL0sYawv2HuOmwz\n6PbNEbFJf14JwKQ831NJ2teYx7rf3AIK9Gh1hMTRAoGASoHVm9PDEAeE6hxDwVq3\nYou2GxqyEaZoYcoJOBR32EVdb3u2FdNRsD6njHngPP/cjsjREkRll43zeZJV0w0V\nh9Ev6q+rH1AqzZNGnlD/a42GTWyWFglQ5QMr9A5XPRLIgRvKiMRyg1B+rv6DVfVb\n1ThqDzo+HlpqS3pyd8Yne2c=\n-----END PRIVATE KEY-----\n".replace(/\\n/g, "\n"),
    }),
  });
}

// Setup NodeMailer transporter
const transporter = nodemailer.createTransport({
  service: "Gmail", // or any SMTP service
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// 🟢 4. Fetch all admin accounts
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

export const createAccount = async (req, res) => {
  try {
    let { full_name, email, role, department } = req.body;

    // Validate required fields
    if (!full_name || !email || !role) {
      return res.status(400).json({ 
        message: "Missing required fields: full_name, email, role" 
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

    // --- Step 1: Insert into DB ---
    const [user] = await sql`
      INSERT INTO admin_accounts (full_name, email, role, department, status)
      VALUES (${full_name}, ${email}, ${role}, ${department}, 'active')
      RETURNING *
    `;

    console.log(`✅ DB record created for user: ${user.id}`);

    try {
      // --- Step 2: Create Firebase user WITH a temporary password ---
      const tempPassword = uuidv4().slice(0, 12) + "Aa1!"; // Strong temporary password
      console.log(`Creating Firebase user for: ${email}`);
      
      const firebaseUser = await admin.auth().createUser({
        uid: `admin-${user.id}`,
        email,
        emailVerified: false,
        password: tempPassword, // Add a temporary password
        displayName: full_name,
        disabled: false,
      });

      console.log(`✅ Firebase user created: ${firebaseUser.uid}`);

      // --- Step 3: Generate Firebase password reset link ---
      console.log(`Generating password reset link for: ${email}`);
      
      // This will automatically send a password reset email using Firebase's email service
      const resetLink = await admin.auth().generatePasswordResetLink(email, {
        // URL where user will be redirected after clicking the email link
        url: `https://ezleave-admin.vercel.app/setup-password`,
        handleCodeInApp: false,
        // Optional: Customize the email template
        // dynamicLinkDomain: "ezleave.page.link",
      });

      console.log(`✅ Firebase password reset email sent to: ${email}`);
      console.log(`Reset link generated (first 50 chars): ${resetLink.substring(0, 50)}...`);

      res.status(201).json({
        message: "✅ Account created successfully!",
        details: "Firebase has sent a password setup email to the user.",
        userId: user.id,
        email: user.email,
        firebaseUid: firebaseUser.uid,
        note: "The user will receive an email from Firebase to set their password."
      });

    } catch (firebaseError) {
      console.error("❌ Firebase operation failed:", firebaseError);
      console.error("Firebase error details:", {
        code: firebaseError.code,
        message: firebaseError.message,
        stack: firebaseError.stack
      });
      
      // Rollback DB insertion if Firebase fails
      await sql`DELETE FROM admin_accounts WHERE id = ${user.id}`;
      
      // Check specific Firebase error codes
      if (firebaseError.code === 'auth/email-already-exists') {
        return res.status(400).json({
          message: "Email already exists in Firebase Authentication",
          error: "This email is already registered in the authentication system"
        });
      }
      
      // Provide more specific error messages
      let errorMessage = "Failed to create authentication account";
      if (firebaseError.code === 'auth/invalid-email') {
        errorMessage = "Invalid email address format";
      } else if (firebaseError.code === 'auth/weak-password') {
        errorMessage = "Password is too weak";
      } else if (firebaseError.code === 'auth/operation-not-allowed') {
        errorMessage = "Email/password accounts are not enabled in Firebase";
      }
      
      res.status(500).json({ 
        message: errorMessage,
        error: firebaseError.message || "Firebase authentication error",
        code: firebaseError.code
      });
    }

  } catch (err) {
    console.error("❌ Error creating account:", err);
    console.error("General error details:", {
      message: err.message,
      stack: err.stack
    });
    
    res.status(500).json({ 
      message: "Internal server error",
      error: err.message 
    });
  }
};

// 🟢 2. Setup password using token
export const setupPassword = async (req, res) => {
  try {
    const { token } = req.params;
    const { password } = req.body;

    const tokens = await sql`
      SELECT * FROM password_tokens
      WHERE token = ${token} AND type = 'setup' AND used = false
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

    res.json({ message: "Password setup successful. You can now log in." });
  } catch (err) {
    console.error("❌ Error setting password:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

// 🟢 3. Login for admin/head/mayor
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

    if (!user.password_hash) {
      return res.status(400).json({ message: "Password not yet set. Check your email for setup link." });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
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

// 🟢 5. Update admin profile (name, email, department, profile picture)
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
        profile_picture: user.profile_picture || picture, // Use Google picture if user doesn't have one
      },
    });

  } catch (error) {
    console.error("❌ Google login error:", error);
    
    res.status(401).json({ 
      message: error.response?.data?.message || "Google authentication failed" 
    });
  }
};

// 🟢 6. Update admin account (for admin to edit other accounts)
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

// 🟢 9. Reset password for admin account
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

    // Generate reset token
    const token = uuidv4();
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24); // valid for 24 hours

    // Delete any existing reset tokens for this user
    await sql`
      DELETE FROM password_tokens
      WHERE user_id = ${id} AND type = 'reset'
    `;

    // Insert new reset token
    await sql`
      INSERT INTO password_tokens (user_id, token, type, expires_at)
      VALUES (${user.id}, ${token}, 'reset', ${expiresAt})
    `;

    // Setup password reset link
    const resetLink = `http://localhost:3001/reset-password?token=${token}`;

    // Send email
    await transporter.sendMail({
      from: `"EZLeave Admin" <${process.env.EMAIL_USER}>`,
      to: user.email,
      subject: "Password Reset Request",
      html: `<p>Hello ${user.full_name},</p>
             <p>You have requested to reset your password. Please click the link below to set a new password:</p>
             <a href="${resetLink}">${resetLink}</a>
             <p>This link is valid for 24 hours.</p>
             <p>If you didn't request this, please ignore this email.</p>`,
    });

    console.log(`✅ Password reset email sent for account ${id}`);
    res.json({ 
      message: "✅ Password reset instructions sent to user's email.",
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
      // For security, don't reveal if email exists or not
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

    // Generate reset token
    const token = uuidv4();
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60); // 1 hour

    // Delete any existing reset tokens for this user
    await sql`
      DELETE FROM password_tokens 
      WHERE user_id = ${user.id} AND type = 'reset'
    `;

    // Insert new reset token
    await sql`
      INSERT INTO password_tokens (user_id, token, type, expires_at)
      VALUES (${user.id}, ${token}, 'reset', ${expiresAt})
    `;

    // Create reset link - USE YOUR ACTUAL FRONTEND URL
    const resetLink = `https://ezleave-admin.vercel.app/reset-password?token=${token}`;
    // OR if you're on Render: 
    // const resetLink = `https://ezleave-admin.onrender.com/reset-password?token=${token}`;

    console.log(`📧 Sending reset email to: ${email}`);
    console.log(`🔗 Reset link: ${resetLink}`);

    // Send email - make sure transporter is configured
    try {
      // Check if email credentials are configured
      if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
        console.error("❌ Email credentials not configured in environment variables");
        console.log(`📋 Manual reset link for ${user.full_name}: ${resetLink}`);
        
        // Return success but mention email wasn't sent
        return res.status(200).json({ 
          message: "Password reset initiated. Please contact administrator for reset link.",
          debug_link: process.env.NODE_ENV === 'development' ? resetLink : undefined
        });
      }

      // Send actual email
      const mailOptions = {
        from: `"EZLeave Admin" <${process.env.EMAIL_USER}>`,
        to: email,
        subject: "Password Reset Request - EZLeave Admin",
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
            <h2 style="color: #4285f4; text-align: center;">EZLeave Admin Password Reset</h2>
            <p>Hello <strong>${user.full_name}</strong>,</p>
            <p>You have requested to reset your password for the EZLeave Admin system.</p>
            <p>Please click the button below to set a new password:</p>
            <div style="text-align: center; margin: 30px 0;">
              <a href="${resetLink}" style="background-color: #4285f4; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;">
                Reset Password
              </a>
            </div>
            <p>Or copy and paste this link in your browser:</p>
            <p style="background-color: #f5f5f5; padding: 10px; border-radius: 5px; word-break: break-all;">
              ${resetLink}
            </p>
            <p>This link will expire in <strong>1 hour</strong>.</p>
            <p>If you didn't request this password reset, please ignore this email or contact your administrator.</p>
            <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
            <p style="color: #666; font-size: 12px; text-align: center;">
              This is an automated message from EZLeave Admin System.
            </p>
          </div>
        `,
        text: `Hello ${user.full_name},\n\nYou requested a password reset for EZLeave Admin.\n\nReset link: ${resetLink}\n\nThis link expires in 1 hour.\n\nIf you didn't request this, please ignore this email.`
      };

      const info = await transporter.sendMail(mailOptions);
      console.log(`✅ Email sent successfully to ${email}:`, info.messageId);

      res.status(200).json({ 
        message: "Password reset instructions have been sent to your email address." 
      });

    } catch (emailError) {
      console.error("❌ Email sending failed:", emailError);
      
      // Log the reset link for debugging
      console.log(`📋 Reset link that would have been sent: ${resetLink}`);
      
      // Still return success but mention email might fail
      res.status(200).json({ 
        message: "Password reset initiated. If you don't receive an email, please contact administrator.",
        debug_note: process.env.NODE_ENV === 'development' ? 'Email service error: ' + emailError.message : undefined
      });
    }

  } catch (err) {
    console.error("❌ Forgot password error:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};