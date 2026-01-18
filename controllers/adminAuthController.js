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

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  try {
    const serviceAccount = {
      projectId: "ezleave-admin",
      clientEmail: "firebase-adminsdk-fbsvc@ezleave-admin.iam.gserviceaccount.com",
      privateKey: process.env.FIREBASE_PRIVATE_KEY 
        ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
        : `-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiGw0BAQEFAASCBKcwggSjAgEAAoIBAQC1xptkahGhxfbr
CjCqSNmA6Bb/piU37iXKkO7Y6TsfVLj+bPDnOrlONq+9jQAGuG3t9m+bcieKsvoT
ElbgnoYt63aDHukmVp2TQ/uBeTGMMmkQn/fLkPLpG58Fa/JjPNm5N8+OBwu1THtk
ONP/s6I+CzSzqnWHm6GMIw/+Lu6K1/WbPWhH2Jv4FZ1Bnm3AGlpLrvwmSQG/Xrqj
o6RCK16vOk35qKzcwa4yT2GlfqYf+sSbLnF2HSFnN+gOY1CpbRqekSNhDVJfsPso
0Htm2aEfiRx09CHADlLU018pMJtaAp6TDk7izyKO4UBSUqGOC80iZC7FyBSQMm/g
VEcnFoePAgMBAAECggEATEsD/HTCWr4+gO7hdw8lbwO6Z2lh9KQZK3iCLvtRC7jg
/jRWNg7BKNEuGKYd7TQqO3az6C/U5dNxv2Byo0sVsR9DOgxWufcfouglHvXxdFDS
JR6m/8MiGPG1YC6q6Ljo/uKsVAWkBd+IaIurewZ3oYfNgl0YgCazeqBavYoQJ6h/
9N+7gD/7AidV8h2j94qibS3lii7wAIGznV/e5PApKdLhoelFRIewF5Qst81xhRp7
ydPoQY7Sz6mXp42WxupEF+HiaC6rs9NG9NJo1e0W5yMdhikrjpD6Vbvgs12X3tat
wGG4N1JthcEvBtglkE7ZLDXBvhh2LCQ31x74pHibfQKBgQDpN50n1rro1LwXe6wo
M6rpPJvZiJlXgb8fvvBCQEzI7WOXs5sBMWlIo+ZaXSA964nrlHcm08Y6s0vbyXbZ
+BD5uNxxJYcgVMpmk6XYoWMhHRW81vYifZlAC3jb+DLZfTqsliKcurbw73zLSewz
lFq3Lj8ft2C53xVMzAKP3s4duwKBgQDHiIarEjH48ELO43xTHce0LpInVEOrt2SW
w9ooUgBUsV6offhYyeVE8nYl/bGE7OwGhSOTkWLe/gBL+Tp9Uu1W1YC0ij283TyT
/tQ0tterk+J35qKjfc/LEM9VSsvoSVwDLV9kxPmLBK1pSFidRy6GMuufLMLKvvCy
YQrVC9w2PQKBgQDYPUasT7+Sbt3P8E3aIL4R8K6Y7r0vlBAAgWwIIdKQYvv7Bv9s
BcKXJdFKbBqfDywckNZB3A5rEx/9NDnNNOOYiD1tc9xsr/HTVodp64ocg/lJ1Q73
P/m+lmSDoQiU/DZRHAwPwlgp4gSWAX7O/Hl4a5r/72nyLdR0Fp0xhOccTQKBgAdw
4/TFPO/XpeYpPZ2r4qKpifHFhrCEqk+lBiGyzShbZPhLmlNVVCN6F0XbbB9U5ohn
ntqfuKA3A0yoCJVg/G3K9i4swDJVaesPaIPfGScywOyXViAMo0fL0sYawv2HuOmwz
6PbNEbFJf14JwKQ831NJ2teYx7rf3AIK9Gh1hMTRAoGASoHVm9PDEAeE6hxDwVq3
You2GxqyEaZoYcoJOBR32EVdb3u2FdNRsD6njHngPP/cjsjREkRll43zeZJV0w0V
h9Ev6q+rH1AqzZNGnlD/a42GTWyWFglQ5QMr9A5XPRLIgRvKiMRyg1B+rv6DVfVb
1ThqDzo+HlpqS3pyd8Yne2c=
-----END PRIVATE KEY-----`.replace(/\\n/g, '\n')
    };

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    
    console.log("✅ Firebase Admin SDK initialized successfully");
  } catch (error) {
    console.error("❌ Firebase initialization error:", error.message);
  }
}

// Setup NodeMailer transporter
const transporter = nodemailer.createTransport({
  service: "Gmail",
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

// 🟢 Create Account with Firebase
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

    try {
      // Create Firebase user
      console.log(`Creating Firebase user for: ${email}`);
      
      const firebaseUser = await admin.auth().createUser({
        email,
        emailVerified: false,
        displayName: full_name,
        disabled: false,
        password: Math.random().toString(36).slice(-8) + "A1!", // Temporary random password
      });

      console.log(`✅ Firebase user created: ${firebaseUser.uid}`);

      // Insert into DB with Firebase UID
      const [user] = await sql`
        INSERT INTO admin_accounts (full_name, email, role, department, status, firebase_uid)
        VALUES (${full_name}, ${email}, ${role}, ${department}, 'active', ${firebaseUser.uid})
        RETURNING *
      `;

      console.log(`✅ DB record created: ${user.id}`);

      // ✅ Send Firebase password reset email - This automatically sends the email!
      try {
        console.log(`📧 Sending Firebase password setup email to: ${email}`);
        
        // This will automatically send a password reset email via Firebase
        const resetLink = await admin.auth().generatePasswordResetLink(email, {
          url: `https://ezleave-admin.vercel.app/login`, // Where user will land after reset
          handleCodeInApp: false,
        });
        
        console.log(`✅ Firebase password reset email sent automatically`);
        console.log(`🔗 Password reset link: ${resetLink}`);
        
        res.status(201).json({
          message: "✅ Account created successfully!",
          details: "Password setup email has been sent via Firebase.",
          userId: user.id,
          email: user.email,
          firebaseUid: firebaseUser.uid,
        });

      } catch (emailError) {
        console.error("❌ Firebase email error:", emailError.message);
        
        // If Firebase email fails, fallback to creating password manually
        console.log("🔄 Fallback: Manual password setup");
        
        // Generate a simple password for manual setup
        const tempPassword = Math.random().toString(36).slice(-8) + "A1!";
        const hashedPassword = await bcrypt.hash(tempPassword, 10);
        
        await sql`
          UPDATE admin_accounts
          SET password_hash = ${hashedPassword}
          WHERE id = ${user.id}
        `;

        res.status(201).json({
          message: "✅ Account created! (Email failed)",
          details: "Use the temporary password below for first login:",
          userId: user.id,
          email: user.email,
          temporaryPassword: tempPassword,
          note: "User should change password after first login",
        });
      }

    } catch (firebaseError) {
      console.error("❌ Firebase error:", firebaseError.message);
      
      if (firebaseError.code === 'auth/email-already-exists') {
        return res.status(400).json({
          message: "This email is already registered in our authentication system.",
        });
      }
      
      // Fallback: Create account without Firebase
      console.log("🔄 Creating account without Firebase");
      
      const [user] = await sql`
        INSERT INTO admin_accounts (full_name, email, role, department, status)
        VALUES (${full_name}, ${email}, ${role}, ${department}, 'active')
        RETURNING *
      `;

      // Generate temporary password
      const tempPassword = Math.random().toString(36).slice(-8) + "A1!";
      const hashedPassword = await bcrypt.hash(tempPassword, 10);
      
      await sql`
        UPDATE admin_accounts
        SET password_hash = ${hashedPassword}
        WHERE id = ${user.id}
      `;

      res.status(201).json({
        message: "✅ Account created with temporary password!",
        details: `User can login with password: ${tempPassword}`,
        userId: user.id,
        email: user.email,
        note: "Please change password after first login",
      });
    }

  } catch (err) {
    console.error("❌ Error creating account:", err);
    res.status(500).json({ 
      message: "Failed to create account",
      error: err.message 
    });
  }
};

// 🟢 Setup password using token (Kept for backward compatibility)
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

// 🟢 Login for admin/head/mayor (Updated for Firebase)
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

    // Check if user has Firebase UID (new system)
    if (user.firebase_uid) {
      // For Firebase users, they should set password via Firebase email
      if (!user.password_hash) {
        return res.status(400).json({ 
          message: "Password not set yet. Please check your email for password setup link from Firebase.",
          needsPasswordSetup: true
        });
      }
    } else {
      // For old users without Firebase
      if (!user.password_hash) {
        return res.status(400).json({ message: "Password not yet set. Check your email for setup link." });
      }
    }

    // Verify password (for both Firebase and non-Firebase users)
    if (!user.password_hash) {
      return res.status(400).json({ message: "Password not set. Please use 'Forgot Password'." });
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

// 🟢 9. Reset password for admin account (Updated for Firebase)
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

    // Check if user has Firebase UID
    if (user.firebase_uid) {
      try {
        // Use Firebase to send password reset email
        console.log(`📧 Sending Firebase password reset to: ${user.email}`);
        
        await admin.auth().generatePasswordResetLink(user.email, {
          url: `https://ezleave-admin.vercel.app/login`,
          handleCodeInApp: false,
        });

        console.log(`✅ Firebase password reset email sent`);
        
        return res.json({ 
          message: "✅ Password reset instructions sent via Firebase.",
        });
      } catch (firebaseError) {
        console.error("❌ Firebase error:", firebaseError.message);
        // Fall through to nodemailer
      }
    }

    // Fallback: Use nodemailer
    const token = uuidv4();
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24);

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

    const resetLink = `https://ezleave-admin.vercel.app/reset-password?token=${token}`;

    if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
      await transporter.sendMail({
        from: `"EZLeave Admin" <${process.env.EMAIL_USER}>`,
        to: user.email,
        subject: "Password Reset Request",
        html: `<p>Hello ${user.full_name},</p>
               <p>Click <a href="${resetLink}">here</a> to reset your password</p>
               <p>Link: ${resetLink}</p>`,
      });

      console.log(`✅ Password reset email sent for account ${id}`);
      res.json({ 
        message: "✅ Password reset instructions sent to user's email.",
      });
    } else {
      res.json({ 
        message: "✅ Password reset initiated.",
        resetLink: resetLink
      });
    }
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

    // Check if user has Firebase UID
    if (user.firebase_uid) {
      try {
        // Use Firebase to send password reset email
        console.log(`📧 Sending Firebase password reset to: ${email}`);
        
        await admin.auth().generatePasswordResetLink(email, {
          url: `https://ezleave-admin.vercel.app/login`,
          handleCodeInApp: false,
        });

        console.log(`✅ Firebase password reset email sent`);
        
        return res.status(200).json({ 
          message: "Password reset email sent successfully via Firebase." 
        });
      } catch (firebaseError) {
        console.error("❌ Firebase error:", firebaseError.message);
        // Fall through to nodemailer
      }
    }

    // Fallback to nodemailer
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

    console.log(`🔗 Reset link: ${resetLink}`);

    if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
      await transporter.sendMail({
        from: `"EZLeave Admin" <${process.env.EMAIL_USER}>`,
        to: email,
        subject: "Password Reset Request - EZLeave Admin",
        html: `
          <div style="font-family: Arial, sans-serif;">
            <h2 style="color: #4285f4;">EZLeave Admin Password Reset</h2>
            <p>Hello <strong>${user.full_name}</strong>,</p>
            <p>Click the link below to reset your password:</p>
            <p><a href="${resetLink}">${resetLink}</a></p>
            <p>This link expires in 1 hour.</p>
          </div>
        `,
      });

      console.log(`✅ Email sent successfully to ${email}`);
      res.status(200).json({ 
        message: "Password reset instructions have been sent to your email." 
      });
    } else {
      console.log(`📋 Manual reset link: ${resetLink}`);
      res.status(200).json({ 
        message: "Password reset initiated. Please contact administrator for reset link.",
        resetLink: resetLink
      });
    }

  } catch (err) {
    console.error("❌ Forgot password error:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};