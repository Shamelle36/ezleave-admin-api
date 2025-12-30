import sql from "../config/db.js";
import { cloudinary } from "../config/cloudinary.js";
import { formatPHDateTime } from "../utils/dateFormatter.js";
import multer from "multer";
import { CloudinaryStorage } from "multer-storage-cloudinary";

// Configure Multer with Cloudinary storage (images only)
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: "announcements",
    resource_type: "image", // Only images now
    allowed_formats: ["jpg", "jpeg", "png", "gif"], // Only image formats
    transformation: [
      { width: 1200, crop: "limit" }, // Optimize images
      { quality: "auto" },
      { format: "auto" }
    ]
  },
});

export const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit for images
  },
  fileFilter: (req, file, cb) => {
    // Only allow images now
    if (file.mimetype.startsWith("image/")) {
      cb(null, true);
    } else {
      cb(new Error("Invalid file type. Only images are allowed."), false);
    }
  },
});

export const getAnnouncements = async (req, res) => {
  try {
    const result = await sql`
      SELECT 
        a.id, 
        a.title, 
        a.details, 
        a.created_at, 
        a.updated_at,
        u.full_name AS posted_by, 
        u.role AS position,
        u.profile_picture,
        a.images
      FROM announcements a
      JOIN useradmin u ON a.created_by = u.id
      ORDER BY a.created_at DESC
    `;

    // Process announcements with image handling only
    const formatted = result.map((a) => {
      let images = [];
      if (Array.isArray(a.images)) {
        images = a.images;
      } else if (a.images) {
        try {
          const parsed = JSON.parse(a.images);
          images = Array.isArray(parsed) ? parsed : [parsed];
        } catch (e) {
          images = [a.images];
        }
      }

      // Process profile picture
      let profilePicture = a.profile_picture;
      if (profilePicture && !profilePicture.startsWith('http')) {
        profilePicture = `${process.env.API_URL || 'http://localhost:3000'}/uploads/${profilePicture}`;
      }

      return {
        id: a.id,
        title: a.title,
        details: a.details,
        created_at: formatPHDateTime(a.created_at),
        updated_at: formatPHDateTime(a.updated_at),
        posted_by: a.posted_by,
        position: a.position,
        profile_picture: profilePicture,
        images: images,
      };
    });

    console.log("Processed announcements:", formatted.length);
    res.json(formatted);
  } catch (err) {
    console.error("Error fetching announcements:", err);
    res.status(500).json({ error: "Failed to fetch announcements" });
  }
};

export const createAnnouncement = async (req, res) => {
  try {
    const { created_by } = req.body;

    // Validate admin exists
    const adminCheck = await sql`
      SELECT id, role, full_name, profile_picture FROM useradmin WHERE id = ${created_by}
    `;
    if (adminCheck.length === 0) {
      return res.status(404).json({ error: "Admin not found" });
    }

    const admin = adminCheck[0];
    const { title, details } = req.body;

    // Process images only
    let imageUrls = [];

    if (req.files && req.files.images) {
      const images = Array.isArray(req.files.images) ? req.files.images : [req.files.images];
      imageUrls = images.map((image) => image.path);
    }

    console.log("Creating announcement with:", {
      title,
      images: imageUrls,
    });

    // Insert announcement with images only
    const result = await sql`
      INSERT INTO announcements (title, details, created_by, images)
      VALUES (${title}, ${details}, ${created_by}, ${sql.array(imageUrls)})
      RETURNING id, title, details, created_by, created_at, images
    `;

    const announcementId = result[0].id;

    // Insert audit log
    const ipAddress = req.headers["x-forwarded-for"]?.split(",").shift() || req.socket.remoteAddress;

    await sql`
      INSERT INTO audit_logs (user_id, role, activity, details, ip_address, created_at)
      VALUES (
        ${created_by},
        ${admin.role},
        'CREATE ANNOUNCEMENT',
        ${`Posted announcement: "${title}"`},
        ${ipAddress},
        NOW()
      )
    `;

    // Return full announcement info
    const fullAnnouncement = await sql`
      SELECT 
        a.id, 
        a.title, 
        a.details, 
        a.created_at, 
        a.updated_at,
        a.images,
        u.full_name AS posted_by, 
        u.role AS position,
        u.profile_picture
      FROM announcements a
      JOIN useradmin u ON a.created_by = u.id
      WHERE a.id = ${announcementId}
    `;

    const data = fullAnnouncement[0];

    // Process response data
    let responseImages = [];
    if (Array.isArray(data.images)) {
      responseImages = data.images;
    } else if (data.images) {
      responseImages = [data.images];
    }

    const responseData = {
      ...data,
      created_at: formatPHDateTime(data.created_at),
      updated_at: formatPHDateTime(data.updated_at),
      images: responseImages,
    };

    console.log("Created announcement response:", {
      id: responseData.id,
      images: responseData.images,
    });

    res.status(200).json(responseData);
  } catch (err) {
    console.error("Error creating announcement:", err);
    
    if (err instanceof multer.MulterError) {
      if (err.code === "LIMIT_FILE_SIZE") {
        return res.status(400).json({ error: "Image too large. Maximum size is 10MB." });
      }
      return res.status(400).json({ error: `Upload error: ${err.message}` });
    }
    
    res.status(500).json({ error: "Failed to create announcement" });
  }
};

export const updateAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, details, created_by } = req.body;

    // Process new images only
    let imageUrls = null;

    if (req.files && req.files.images) {
      const images = Array.isArray(req.files.images) ? req.files.images : [req.files.images];
      imageUrls = images.map((image) => image.path);
    }

    // Fetch current announcement
    const current = await sql`
      SELECT * FROM announcements WHERE id = ${id}
    `;
    if (!current[0]) return res.status(404).json({ error: "Announcement not found" });

    // Prepare images for database
    let imagesForDb = current[0].images;

    if (imageUrls) {
      imagesForDb = imageUrls;
    }

    // Update announcement
    await sql`
      UPDATE announcements
      SET
        title = ${title ?? current[0].title},
        details = ${details ?? current[0].details},
        images = ${sql.array(imagesForDb)},
        updated_at = NOW()
      WHERE id = ${id}
    `;

    const updatedAnnouncement = await sql`
      SELECT 
        a.id, 
        a.title, 
        a.details, 
        a.created_at, 
        a.updated_at,
        a.images,
        u.full_name AS posted_by, 
        u.role AS position,
        u.profile_picture
      FROM announcements a
      JOIN useradmin u ON a.created_by = u.id
      WHERE a.id = ${id}
    `;

    const announcementData = updatedAnnouncement[0];

    // Process response data
    let responseImages = [];
    if (Array.isArray(announcementData.images)) {
      responseImages = announcementData.images;
    } else if (announcementData.images) {
      responseImages = [announcementData.images];
    }

    const formattedResponse = {
      ...announcementData,
      created_at: formatPHDateTime(announcementData.created_at),
      updated_at: formatPHDateTime(announcementData.updated_at),
      images: responseImages,
    };

    // Audit log
    const ip = req.ip || req.connection?.remoteAddress || "Unknown";
    const userRole = announcementData?.position || "Unknown";

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

    res.status(200).json(formattedResponse);
  } catch (err) {
    console.error("Error updating announcement:", err);
    
    if (err instanceof multer.MulterError) {
      if (err.code === "LIMIT_FILE_SIZE") {
        return res.status(400).json({ error: "Image too large. Maximum size is 10MB." });
      }
      return res.status(400).json({ error: `Upload error: ${err.message}` });
    }
    
    res.status(500).json({ error: "Failed to update announcement" });
  }
};

export const deleteAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;

    const announcement = await sql`SELECT * FROM announcements WHERE id = ${id}`;
    if (!announcement[0]) return res.status(404).json({ error: "Announcement not found" });

    const { created_by, title } = announcement[0];

    await sql`DELETE FROM announcements WHERE id = ${id}`;

    // Audit log
    const ip = req.ip || req.connection?.remoteAddress || "Unknown";
    await sql`
      INSERT INTO audit_logs (user_id, role, activity, details, ip_address, created_at)
      VALUES (${created_by ?? 1}, 'Admin', 'DELETE ANNOUNCEMENT', ${`Deleted announcement: "${title}"`}, ${ip}, NOW())
    `;

    res.status(200).json({ message: "Announcement deleted successfully" });
  } catch (err) {
    console.error("Error deleting announcement:", err);
    res.status(500).json({ error: "Failed to delete announcement" });
  }
};