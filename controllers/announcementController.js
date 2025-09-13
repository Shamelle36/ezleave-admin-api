// backend/controllers/announcementController.js
import sql from "../config/db.js";
import fs from "fs";
import { formatPHDateTime } from "../utils/dateFormatter.js"

export const getAnnouncements = async (req, res) => {
  try {
    const result = await sql`
      SELECT a.id, a.title, a.details, a.priority, a.created_at, a.updated_at,
             u.full_name AS posted_by, u.role AS position,
             a.files, a.images
      FROM announcements a
      JOIN userAdmin u ON a.created_by = u.id
      ORDER BY a.created_at DESC
    `;

    const formatted = result.map(a => ({
      ...a,
      created_at: formatPHDateTime(a.created_at),
      updated_at: formatPHDateTime(a.updated_at),
    }));

    res.json(formatted);

  } catch (err) {
    console.error("Error fetching announcements:", err);
    res.status(500).json({ error: "Failed to fetch announcements" });
  }
};



export const createAnnouncement = async (req, res) => {
  try {
    const { title, details, priority, created_by } = req.body;

    // Handle uploads
    const filePaths = req.files?.files
      ? req.files.files.map((f) => `/uploads/${f.filename}`)
      : [];
    const imagePaths = req.files?.images
      ? req.files.images.map((f) => `/uploads/${f.filename}`)
      : [];

    const user = await sql`
      SELECT role
      FROM userAdmin
      WHERE id = ${created_by}
    `;

    const userRole = user[0]?.role || 'Unknown';

    //Insert into announcements
    const result = await sql`
      INSERT INTO announcements (title, details, priority, created_by, files, images)
      VALUES (${title}, ${details}, ${priority}, ${created_by}, ${filePaths}, ${imagePaths})
      RETURNING id, title, details, priority, created_by, created_at, files, images
    `;

    const announcementId = result[0].id;

     const ipAddress =
      req.headers['x-forwarded-for']?.split(',').shift() || req.socket.remoteAddress;

    //Insert into audit logs
    await sql`
      INSERT INTO audit_logs (user_id, role, activity, details, ip_address, created_at)
      VALUES (${created_by}, ${userRole}, 'CREATE ANNOUNCEMENT', ${`Posted announcement: "${title}"`},${ipAddress}, NOW())
    `;

    //Fetch full announcement info
    const fullAnnouncement = await sql`
      SELECT a.id, a.title, a.details, a.priority, a.created_at,
             a.files, a.images,
             u.full_name AS posted_by, u.role AS position
      FROM announcements a
      JOIN userAdmin u ON a.created_by = u.id
      WHERE a.id = ${announcementId}
    `;

    const announcementData = fullAnnouncement[0];

    res.status(200).json({
      ...announcementData,
      created_at: formatPHDateTime(announcementData.created_at),
      updated_at: formatPHDateTime(announcementData.updated_at),
    });

  } catch (err) {
    console.error("Error creating announcement:", err);
    res.status(500).json({ error: "Failed to create announcement" });
  }
};

export const updateAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, details, priority, created_by } = req.body;

    // Handle uploaded files/images
    const filePaths = req.files?.files?.map(f => `/uploads/${f.filename}`) || null;
    const imagePaths = req.files?.images?.map(f => `/uploads/${f.filename}`) || null;

    // Fetch current announcement first (to use existing values if undefined)
    const current = await sql`
      SELECT * FROM announcements WHERE id = ${id}
    `;
    if (!current[0]) return res.status(404).json({ error: "Announcement not found" });

    await sql`
      UPDATE announcements
      SET
        title = ${title ?? current[0].title},
        details = ${details ?? current[0].details},
        priority = ${priority ?? current[0].priority},
        files = ${filePaths ?? current[0].files},
        images = ${imagePaths ?? current[0].images},
        updated_at = NOW()
      WHERE id = ${id}
    `;

    // Fetch full announcement info with user details
    const updatedAnnouncement = await sql`
      SELECT a.id, a.title, a.details, a.priority, a.created_at, a.updated_at,
             a.files, a.images,
             u.full_name AS posted_by, u.role AS position
      FROM announcements a
      JOIN userAdmin u ON a.created_by = u.id
      WHERE a.id = ${id}
    `;

    const announcementData = updatedAnnouncement[0];

    // --- Audit log ---
    const ip = req.ip || req.connection?.remoteAddress || 'Unknown';
    const userRole = announcementData?.position || 'Unknown';

    await sql`
      INSERT INTO audit_logs (user_id, role, activity, details, ip_address, created_at)
      VALUES (
        ${created_by ?? current[0].created_by}, 
        ${userRole},
        'UPDATE ANNOUNCEMENT',
        ${`Updated announcement: "${title ?? announcementData.title}"`},
        ${ip},
        NOW()
      )
    `;

    res.status(200).json({
      ...announcementData,
      created_at: formatPHDateTime(announcementData.created_at),
      updated_at: formatPHDateTime(announcementData.updated_at),
    });

  } catch (err) {
    console.error("Error updating announcement:", err);
    res.status(500).json({ error: "Failed to update announcement" });
  }
};

export const deleteAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;

    // Fetch the announcement first to get files/images and created_by
    const announcement = await sql`
      SELECT * FROM announcements WHERE id = ${id}
    `;
    if (!announcement[0]) return res.status(404).json({ error: "Announcement not found" });

    const { files, images, created_by, title } = announcement[0];

    // Delete files from server
    if (files) {
      files.forEach((f) => {
        const path = `.${f}`; // assuming file paths are like /uploads/filename
        if (fs.existsSync(path)) fs.unlinkSync(path);
      });
    }
    if (images) {
      images.forEach((img) => {
        const path = `.${img}`;
        if (fs.existsSync(path)) fs.unlinkSync(path);
      });
    }

    // Delete announcement from DB
    await sql`
      DELETE FROM announcements WHERE id = ${id}
    `;

    // Audit log
    const ip = req.ip || req.connection?.remoteAddress || "Unknown";
    await sql`
      INSERT INTO audit_logs (user_id, role, activity, details, ip_address, created_at)
      VALUES (
        ${created_by ?? 1},
        'Admin', 
        'DELETE ANNOUNCEMENT',
        ${`Deleted announcement: "${title}"`},
        ${ip},
        NOW()
      )
    `;

    res.status(200).json({ message: "Announcement deleted successfully" });
  } catch (err) {
    console.error("Error deleting announcement:", err);
    res.status(500).json({ error: "Failed to delete announcement" });
  }
};


