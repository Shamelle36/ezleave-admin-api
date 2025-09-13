// backend/utils/logger.js
import sql from "../config/db.js";

export async function logActivity(userId, role, activity, details, ip) {
  await sql`
    INSERT INTO audit_logs (user_id, role, activity, details, ip_address)
    VALUES (${userId}, ${role}, ${activity}, ${details}, ${ip})
  `;
}
