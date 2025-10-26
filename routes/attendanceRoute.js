import express from "express";
import * as attendanceController from "../controllers/attendanceController.js";

const router = express.Router();

// GET /api/attendance?date=2025-09-26
router.get("/", attendanceController.getAttendanceLogs);

export default router;