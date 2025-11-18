import express from "express";
import {
  getLeaveRequests,
  getLeaveRequestsCount,
  approveLeaveRequest,
  rejectLeaveRequest,
  getMonthlyLeaveCounts
} from "../controllers/leaveRequestController.js";

const router = express.Router();

// 📌 Get all leave requests
router.get("/", getLeaveRequests);

// 📌 Get leave requests count by status
router.get("/count", getLeaveRequestsCount);

// 📌 Get monthly leave request counts (optional leave type filter)
router.get("/monthly", getMonthlyLeaveCounts);

// 📌 Approve a leave request
router.patch("/:id/approve", approveLeaveRequest);

// 📌 Reject a leave request
router.patch("/:id/reject", rejectLeaveRequest);

export default router;
