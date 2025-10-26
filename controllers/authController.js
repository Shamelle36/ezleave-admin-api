import bcrypt from "bcrypt";
import { findUserByEmail } from "../models/userModels.js";
import sql from "../config/db.js";
import { logActivity } from "../utils/logger.js";
import multer from "multer";
import { CloudinaryStorage } from "multer-storage-cloudinary";
import { cloudinary } from "../config/cloudinary.js";

// ==============================
// ☁️ Cloudinary + Multer Setup
// ==============================
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: "admin_profiles",
    allowed_formats: ["jpg", "jpeg", "png"],
    transformation: [{ width: 300, height: 300, crop: "fill" }],
  },
});
export const upload = multer({ storage });

// ==============================
// 🧩 Signup (One-time only)
// ==============================
export const signup = async (req, res) => {
  try {
    const { email, fullName, password } = req.body;

    // check if admin already exists
    const result = await sql`SELECT * FROM useradmin WHERE role = 'admin' LIMIT 1`;
    if (result.length > 0) {
      return res.status(400).json({ message: "Admin account already exists." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await sql`
      INSERT INTO useradmin (email, full_name, password, role)
      VALUES (${email}, ${fullName}, ${hashedPassword}, 'admin')
      RETURNING id, email, full_name, role
    `;

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

// ==============================
// 🔐 Login
// ==============================
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

// ==============================
// 🚪 Logout
// ==============================
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

// ==============================
// 👤 Get Admin by ID
// ==============================
export const getAdminById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await sql`
      SELECT id, email, full_name, role, created_at, profile_picture
      FROM useradmin
      WHERE id = ${id}
    `;

    if (result.length === 0) {
      return res.status(404).json({ message: "Admin not found" });
    }

    res.json(result[0]);
  } catch (err) {
    console.error("Error fetching admin:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ==============================
// ✏️ Update Admin Profile (Cloudinary version)
// ==============================
export const updateAdminProfile = async (req, res) => {
  try {
    console.log("=== UPDATE PROFILE REQUEST RECEIVED ===");
    console.log("Params:", req.params);
    console.log("Body:", req.body);

    const { id } = req.params;
    const { full_name, email, profile_picture } = req.body;

    if (!id) {
      console.error("❌ Missing admin ID in request params");
      return res.status(400).json({ message: "Missing admin ID" });
    }

    console.log("➡️ Executing SQL UPDATE for ID:", id);
    const result = await sql`
      UPDATE useradmin
      SET
        full_name = ${full_name},
        email = ${email},
        profile_picture = ${profile_picture}
      WHERE id = ${id}
      RETURNING id, email, full_name, role, profile_picture, created_at
    `;

    console.log("✅ SQL update result:", result);

    if (result.length === 0) {
      console.warn("⚠️ Admin not found with ID:", id);
      return res.status(404).json({ message: "Admin not found" });
    }

    console.log("✅ Updated admin profile:", result[0]);
    res.json(result[0]);

  } catch (err) {
    console.error("❌ Error updating profile:", err.message);
    console.error("Full error object:", err);
    res.status(500).json({ 
      message: "Server error while updating profile", 
      error: err.message 
    });
  }
};
