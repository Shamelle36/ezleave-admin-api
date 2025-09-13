// backend/controllers/authController.js
import bcrypt from "bcrypt";
import { findUserByEmail } from "../models/userModels.js";
import sql from "../config/db.js";
import { logActivity } from "../utils/logger.js";

// One-time signup
export const signup = async (req, res) => {
  try {
    const { email, fullName, password } = req.body;

    // check if admin already exists
    const result = await sql`SELECT * FROM userAdmin WHERE role = 'admin' LIMIT 1`;
    if (result.length > 0) {
      return res.status(400).json({ message: "Admin account already exists." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await sql`
      INSERT INTO userAdmin (email, full_name, password, role)
      VALUES (${email}, ${fullName}, ${hashedPassword}, 'admin')
      RETURNING id, email, full_name, role
    `;

    // log signup activity
    await logActivity(
      newUser[0].id,
      newUser[0].role,
      "Signup",
      `Admin ${newUser[0].email} registered`,
      req.ip
    );

    res.status(201).json({
      message: "Admin account created successfully",
      user: newUser[0],
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};

// Login
export async function login(req, res) {
  const { email, password } = req.body;

  try {
    const user = await findUserByEmail(email);
    if (!user) {
      await logActivity(null, "unknown", "Failed Login", `No account found for ${email}`, req.ip);
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      await logActivity(user.id, user.role, "Failed Login", "Incorrect password", req.ip);
      return res.status(401).json({ message: "Invalid credentials" });
    }

    // successful login
    await logActivity(user.id, user.role, "Login", "Successful login", req.ip);

    res.json({
      message: "Login successful",
      user: { id: user.id, email: user.email, role: user.role },
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
}

export async function logout(req, res) {
  try {
    const { userId, role } = req.body;

    await logActivity(userId, role, "Logout", "User logged out", req.ip);

    res.json({ message: "Logout successful" });
  } catch (error) {
    console.error("Logout error:", error);
    res.status(500).json({ message: "Server error" });
  }
}
