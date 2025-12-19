import express from "express";
import { upload, uploadLeaveCard, getEmployeeWithLeaveBalances } from "../controllers/leaveCardController.js";

const router = express.Router();

// POST /api/leave-cards/upload
router.post("/upload", upload.single("file"), uploadLeaveCard);

router.get("/employeeLeave/:id", getEmployeeWithLeaveBalances);


export default router;
