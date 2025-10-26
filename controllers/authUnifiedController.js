import bcrypt from "bcryptjs";
import sql from "../config/db.js";
import jwt from "jsonwebtoken";

const generateToken = (user) =>
  jwt.sign({ id: user.id, role: user.role, department: user.department }, process.env.JWT_SECRET, { expiresIn: "7d" });

export const unifiedLogin = async (req, res) => {
  const { email, password } = req.body;

  try {
    // 1️⃣ Check useradmin first (main admin)
    let users = await sql`SELECT * FROM useradmin WHERE email = ${email}`;
    let user = users[0];

    if (user) {
      // compare password
      const match = await bcrypt.compare(password, user.password);
      if (!match) return res.status(401).json({ message: "Invalid credentials" });

      const token = generateToken(user);
      return res.json({ message: "Login successful", token, user });
    }

    // 2️⃣ Check admin_accounts (heads/mayor)
    users = await sql`SELECT * FROM admin_accounts WHERE email = ${email}`;
    user = users[0];

    if (!user) return res.status(401).json({ message: "Account not found" });
    if (!user.password_hash) return res.status(400).json({ message: "Password not yet set. Check your email." });

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) return res.status(401).json({ message: "Invalid credentials" });

    const token = generateToken(user);
    return res.json({ message: "Login successful", token, user });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
};
