import express from "express";
import {
  getLeaveRequests,
  getLeaveRequestsCount,
  approveLeaveRequest,
  rejectLeaveRequest,
  getMonthlyLeaveCounts,
  getLeaveCalendarByDay,
  getLeaveCalendarByMonth,
  checkOverlappingLeavesForOfficeHead,
  testOverlapCheck,
  markNotificationAsRead,
  markAllNotificationsAsRead
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

router.get('/leave-calendar/day/:date', getLeaveCalendarByDay);

router.get('/leave-calendar/month/:year/:month', getLeaveCalendarByMonth);

router.post('/check-overlapping-leaves', checkOverlappingLeavesForOfficeHead);

router.get("/test-overlap", testOverlapCheck);

// In your routes file (e.g., routes/leaveRoutes.js or server.js)
router.put('/notifications/:id/read', markNotificationAsRead);
router.put('/notifications/mark-all-read', markAllNotificationsAsRead);

export default router;
