import express from "express";
import { createAnnouncement, getAnnouncements, updateAnnouncement, deleteAnnouncement } from "../controllers/announcementController.js";
import multer from "multer";
import { CloudinaryStorage } from "multer-storage-cloudinary";
import { cloudinary } from "../config/cloudinary.js";

const router = express.Router();

const storage = new CloudinaryStorage({
  cloudinary,
  params: async (req, file) => {
    const isImage = file.mimetype.startsWith("image/");

    return {
      folder: "announcements",
      resource_type: isImage ? "image" : "raw",  
      public_id: Date.now() + "-" + file.originalname, 
    };
  },
});

const upload = multer({ storage });

router.get("/", getAnnouncements);

router.post(
  "/",
  upload.fields([
    { name: "files", maxCount: 10 },
    { name: "images", maxCount: 10 },
  ]),
  createAnnouncement
);

router.put(
  "/:id",
  upload.fields([
    { name: "files", maxCount: 10 },
    { name: "images", maxCount: 10 },
  ]),
  updateAnnouncement
);

router.delete("/:id", deleteAnnouncement);

export default router;
