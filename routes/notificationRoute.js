import express from 'express';
import sql from '../config/db.js';
import { getUserNotifications, markAsRead, markAllAsRead, deleteNotification } from '../utils/notificationService.js';

const router = express.Router();

// Get user notifications
router.get('/user/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;
    const { limit = 20, offset = 0 } = req.query;
    
    const result = await getUserNotifications(user_id, parseInt(limit), parseInt(offset));
    
    res.json(result);
  } catch (error) {
    console.error("❌ Error fetching notifications:", error);
    res.status(500).json({ error: "Failed to fetch notifications" });
  }
});

// Mark notification as read
router.patch('/:id/read', async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id } = req.body;
    
    if (!user_id) {
      return res.status(400).json({ error: "User ID is required" });
    }
    
    const updated = await markAsRead(id, user_id);
    
    if (!updated) {
      return res.status(404).json({ error: "Notification not found" });
    }
    
    res.json({ 
      success: true, 
      message: "Notification marked as read",
      notification: updated 
    });
  } catch (error) {
    console.error("❌ Error marking notification as read:", error);
    res.status(500).json({ error: "Failed to mark notification as read" });
  }
});

// Mark all notifications as read
router.patch('/mark-all-read', async (req, res) => {
  try {
    const { user_id } = req.body;
    
    if (!user_id) {
      return res.status(400).json({ error: "User ID is required" });
    }
    
    const updatedCount = await markAllAsRead(user_id);
    
    res.json({ 
      success: true, 
      message: `Marked ${updatedCount} notifications as read`,
      updated_count: updatedCount 
    });
  } catch (error) {
    console.error("❌ Error marking all notifications as read:", error);
    res.status(500).json({ error: "Failed to mark notifications as read" });
  }
});

// Delete notification
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id } = req.body;
    
    if (!user_id) {
      return res.status(400).json({ error: "User ID is required" });
    }
    
    const deleted = await deleteNotification(id, user_id);
    
    if (!deleted) {
      return res.status(404).json({ error: "Notification not found" });
    }
    
    res.json({ 
      success: true, 
      message: "Notification deleted",
      notification: deleted 
    });
  } catch (error) {
    console.error("❌ Error deleting notification:", error);
    res.status(500).json({ error: "Failed to delete notification" });
  }
});

// Get notification count (for badge)
router.get('/count/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;
    
    const [result] = await sql`
      SELECT COUNT(*) as unread_count
      FROM notifications
      WHERE user_id = ${user_id} AND read = false;  -- Use 'read' not 'is_read'
    `;
    
    res.json({ 
      unread_count: parseInt(result?.unread_count || 0)
    });
  } catch (error) {
    console.error("❌ Error fetching notification count:", error);
    res.status(500).json({ error: "Failed to fetch notification count" });
  }
});

export default router;