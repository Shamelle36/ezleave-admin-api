// backend/config/cloudinary.js
import { v2 as cloudinary } from "cloudinary";
import { CloudinaryStorage } from "multer-storage-cloudinary";

cloudinary.config({
  cloud_name: process.env.CLOUD_NAME,
  api_key: process.env.API_KEY,
  api_secret: process.env.API_SECRET,
});

// Storage for announcements
const announcementStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: "announcements",
    resource_type: "auto",
  },
});

// Storage for signatures (with specific settings)
const signatureStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: "employee-signatures",
    resource_type: "image",
    allowed_formats: ["jpg", "jpeg", "png", "svg"],
    transformation: [
      { width: 500, height: 200, crop: "limit" } // Resize for consistency
    ]
  },
});

export { cloudinary, announcementStorage, signatureStorage };