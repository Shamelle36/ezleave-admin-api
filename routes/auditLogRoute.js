import express from "express";
import sql from "../config/db.js";

const router = express.Router();

router.get("/", async (req, res) => {
  try {
    const result = await sql`
      SELECT a.id, a.created_at, a.activity, a.details, a.ip_address,
             u.email, u.full_name, u.role
      FROM audit_logs a
      JOIN userAdmin u ON a.user_id = u.id
      ORDER BY a.created_at DESC
    `;

    // Convert created_at to PH date + 12-hour time
    const formatted = result.map((log) => ({
      ...log,
      created_at: new Date(log.created_at).toLocaleString("en-PH", {
        year: "numeric",
        month: "short",
        day: "numeric",
        hour: "numeric",
        minute: "numeric",
        hour12: true,
        timeZone: "Asia/Manila",
      }),
    }));

    res.json(formatted);
  } catch (err) {
    console.error("Error fetching logs:", err);
    res.status(500).json({ error: "Error fetching logs" });
  }
});

export default router;
