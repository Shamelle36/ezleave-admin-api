import express from 'express';
import {
  markNotificationAsRead,
  markAllNotificationsAsRead
} from '../controllers/notificationController.js';

const router = express.Router();

// Mark a single notification as read
router.put('/:id/read', markNotificationAsRead);

// Mark all notifications as read for a user
router.put('/mark-all-read', markAllNotificationsAsRead);

export default router;