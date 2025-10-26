import { Router } from "express";
import { exportAttendance } from "../controllers/exportController.js";

const router = Router();

// ✅ GET /api/attendance/export?date=YYYY-MM-DD&format=excel|word|pdf
router.get("/", exportAttendance);

export default router;
