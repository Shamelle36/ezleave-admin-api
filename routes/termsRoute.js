import express from "express";
import {
  getActiveTerms,
  getAllTerms,
  createTerms,
  updateTerms,
  deleteTerms,
} from "../controllers/termsController.js";

const router = express.Router();

// Public (Employees)
router.get("/active", getActiveTerms);

// Admin (You will secure these in the Admin System)
router.get("/", getAllTerms);
router.post("/", createTerms);
router.put("/:id", updateTerms);
router.delete("/:id", deleteTerms);

export default router;
