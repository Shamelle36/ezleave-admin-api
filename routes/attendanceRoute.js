import express from "express";
import * as attendanceController from "../controllers/attendanceController.js";

const router = express.Router();

// GET /api/attendance?date=2025-09-26
router.get("/", attendanceController.getAttendanceLogs);

// GET /api/attendance/employee/:id - Get all attendance for specific employee
router.get("/employee/:id", attendanceController.getEmployeeAttendance);

// ==================== ATTENDANCE TIME SETTINGS ROUTES ====================

// GET /api/attendance/settings/time - Get all attendance time settings
router.get("/settings/time", attendanceController.getAllTimeSettings);

// POST /api/attendance/settings/time - Update attendance time settings
router.post("/settings/time", attendanceController.updateTimeSettings);

// GET /api/attendance/settings/time/:day - Get time setting for specific day
router.get("/settings/time/:day", attendanceController.getTimeSettingByDay);

// POST /api/attendance/settings/time/reset - Reset to default time settings
router.post("/settings/time/reset", attendanceController.resetToDefault);

// PUT /api/attendance/settings/time/:day/toggle - Toggle day active/inactive
router.put("/settings/time/:day/toggle", attendanceController.toggleDayActive);

// GET /api/attendance/late-today - Calculate late employees for today
router.get("/late-today", attendanceController.calculateLateEmployees);

export default router;