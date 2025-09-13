// backend/models/userModel.js
import sql from "../config/db.js";

export async function countUsers() {
  const result = await sql`SELECT COUNT(*) FROM userAdmin`;
  return parseInt(result[0].count);
}

export async function createAdmin(email, hashedPassword) {
  return await sql`
    INSERT INTO userAdmin (email, password, role)
    VALUES (${email}, ${hashedPassword}, 'admin')
    RETURNING id, email, role
  `;
}

export async function findUserByEmail(email) {
  const result = await sql`SELECT * FROM userAdmin WHERE email = ${email}`;
  return result[0];
}
