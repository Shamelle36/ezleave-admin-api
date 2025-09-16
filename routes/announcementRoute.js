import express from "express";
import { createAnnouncement, getAnnouncements, updateAnnouncement, deleteAnnouncement } from "../controllers/announcementController.js";
import multer from "multer";
import cloudinary from "../config/cloudinary.js";
import fs from "fs";

const router = express.Router();

const upload = multer({ dest: "temp/" });

const uploadToCloudinary = async (file, folder, resource_type = "image") => {
  const result = await cloudinary.uploader.upload(file.path, {
    folder,
    resource_type,
  });

  fs.unlinkSync(file.path);

  return result.secure_url;
};

router.get("/", getAnnouncements);

router.post(
  "/",
  upload.fields([
    { name: "files", maxCount: 10 },
    { name: "images", maxCount: 10 },
  ]),
  async (req, res, next) => {
    try {
      const { title, details, priority, created_by } = req.body;

      let imageUrls = [];
      let fileUrls = [];

      if (req.files?.images) {
        for (const img of req.files.images) {
          const url = await uploadToCloudinary(img, "ezleave/announcements", "image");
          imageUrls.push(url);
        }
      }

      if (req.files?.files) {
        for (const file of req.files.files) {
          const url = await uploadToCloudinary(file, "ezleave/files", "raw");
          fileUrls.push(url);
        }
      }

      req.body.images = imageUrls;
      req.body.files = fileUrls;

      return createAnnouncement(req, res);
    } catch (err) {
      next(err);
    }
  }
);

router.put(
  "/:id",
  upload.fields([
    { name: "files", maxCount: 10 },
    { name: "images", maxCount: 10 },
  ]),
  async (req, res, next) => {
    try {
      let imageUrls = [];
      let fileUrls = [];

      if (req.files?.images) {
        for (const img of req.files.images) {
          const url = await uploadToCloudinary(img, "ezleave/announcements", "image");
          imageUrls.push(url);
        }
      }

      if (req.files?.files) {
        for (const file of req.files.files) {
          const url = await uploadToCloudinary(file, "ezleave/files", "raw");
          fileUrls.push(url);
        }
      }

      req.body.images = imageUrls;
      req.body.files = fileUrls;

      return updateAnnouncement(req, res);
    } catch (err) {
      next(err);
    }
  }
);

router.delete("/:id", deleteAnnouncement);

export default router;
