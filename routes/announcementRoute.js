import express from "express";
import { createAnnouncement, getAnnouncements, updateAnnouncement, deleteAnnouncement } from "../controllers/announcementController.js";
import multer from "multer";
import path from "path";

const router = express.Router();

// Configure storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads/"), // store in uploads folder
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)), // unique filename
});

// Multer instance
const upload = multer({ storage });

// Get all announcements
router.get("/", getAnnouncements);

// Post new announcement
// Accepts multiple files under two different fields: "files" and "images"
router.post(
  "/",
  upload.fields([
    { name: "files", maxCount: 10 },   // e.g., PDF, DOCX, etc.
    { name: "images", maxCount: 10 },  // e.g., JPG, PNG, etc.
  ]),
  createAnnouncement
);

// Update announcement
// Handle optional files and images
router.put(
  "/:id",
  upload.fields([{ name: "files" }, { name: "images" }]),
  updateAnnouncement
);

router.delete("/:id", deleteAnnouncement);



export default router;
