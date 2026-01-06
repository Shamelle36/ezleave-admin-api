// backend/controllers/adminAuthController.js
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { v4 as uuidv4 } from "uuid";
import sql from "../config/db.js"; // your Neon DB connection using postgres package
import nodemailer from "nodemailer";

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
      SELECT id, full_name, email, role, department
      FROM admin_accounts
      ORDER BY full_name ASC
    `;

    res.json({ accounts });
  } catch (err) {
    console.error("❌ Error fetching accounts:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

// 🟢 1. Admin creates new account for Head/Mayor
export const createAccount = async (req, res) => {
  try {
    let { full_name, email, role, department } = req.body;

    // Normalize role to match DB constraint
    role = role.toLowerCase().replace(" ", "_"); // "Office Head" → "office_head"

    // Check if email already exists
    const existing = await sql`
      SELECT * FROM admin_accounts WHERE email = ${email}
    `;

    if (existing.length > 0) {
      return res.status(400).json({ message: "Email already exists." });
    }

    // Insert new account (no password yet)
    const [user] = await sql`
      INSERT INTO admin_accounts (full_name, email, role, department)
      VALUES (${full_name}, ${email}, ${role}, ${department})
      RETURNING *
    `;

    // Generate setup token
    const token = uuidv4();
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24); // valid for 24 hours

    await sql`
      INSERT INTO password_tokens (user_id, token, type, expires_at)
      VALUES (${user.id}, ${token}, 'setup', ${expiresAt})
    `;

    // Setup password link
    const setupLink = `http://localhost:3001/setup-password?token=${token}`;

    // Send email
    await transporter.sendMail({
      from: `"EZLeave Admin" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: "Set up your EZLeave password",
      html: `<p>Hello ${full_name},</p>
             <p>An admin has created an account for you. Please set your password by clicking the link below:</p>
             <a href="${setupLink}">${setupLink}</a>
             <p>This link is valid for 24 hours.</p>`,
    });

    res.status(201).json({
      message: "✅ Account created! Email sent for password setup.",
    });
  } catch (err) {
    console.error("❌ Error creating account:", err);
    res.status(500).json({ message: "Internal server error" });
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

    if (!user.password_hash) {
      return res.status(400).json({ message: "Password not yet set. Check your email for setup link." });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ message: "Invalid credentials." });
    }

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
      SELECT id, full_name, email, role, department, profile_picture
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

    if (!user.password_hash) {
      return res.status(400).json({ 
        message: "Account not fully set up. Please check your email for setup link." 
      });
    }

    // Log successful Google login
    console.log(`✅ Google login successful for office user: ${email}, Role: ${user.role}`);

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
    await sql`
      UPDATE admin_accounts
      SET ${sql(updates)}
      WHERE id = ${id}
      RETURNING id, full_name, email, role, department
    `;

    console.log(`✅ Account ${id} updated successfully`);
    res.json({ 
      message: "✅ Account updated successfully!",
      account: updates
    });
  } catch (err) {
    console.error("❌ Error updating account:", err);
    res.status(500).json({ message: "Failed to update account." });
  }
};