import sql from "../config/db.js";
import { sendFcmPush } from "./fcm.js";

// Create notification for a user
export async function createNotification({ user_id, title, message, type = 'general', data = {} }) {
  try {
    const combinedMessage = `${title || 'Notification'}: ${message}`;

    const [notification] = await sql`
      INSERT INTO notifications (user_id, message)
      VALUES (${user_id}, ${combinedMessage})
      RETURNING *;
    `;

    console.log("📝 Notification created:", notification.id);
    return notification;
  } catch (error) {
    console.error("❌ Error creating notification:", error);
    throw error;
  }
}

// Send push notification + save to database
export async function sendAndSaveNotification({ user_id, title, message, type, data = {} }) {
  try {
    // 1. Get user's FCM token
    const [tokenRow] = await sql`
      SELECT fcm_token
      FROM employee_push_tokens
      WHERE user_id = ${user_id}
      LIMIT 1;
    `;

    // 2. Combine message
    const combinedMessage = `${title || 'Notification'}: ${message}`;

    // 3. Save to DB
    const [notification] = await sql`
      INSERT INTO notifications (user_id, message)
      VALUES (${user_id}, ${combinedMessage})
      RETURNING *;
    `;

    console.log("✅ Saved notification:", notification.id);

    // 4. Send push notification through FCM
    if (tokenRow?.fcm_token) {
      await sendFcmPush(
        tokenRow.fcm_token,
        title || "Notification",
        message,
        {
          ...data,
          notification_id: notification.id,
          type: type || "general"
        }
      );
    } else {
      console.log("⚠️ User has no FCM token saved.");
    }

    return notification;
  } catch (error) {
    console.error("❌ Error in sendAndSaveNotification:", error);
    throw error;
  }
}

// Fetch notifications (unchanged)
export async function getUserNotifications(user_id, limit = 20, offset = 0) {
  try {
    const notifications = await sql`
      SELECT 
        id,
        title,
        message,
        type,
        is_read,
        data,
        TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI') as created_at
      FROM notifications
      WHERE user_id = ${user_id}
      ORDER BY created_at DESC
      LIMIT ${limit}
      OFFSET ${offset};
    `;

    const [unreadCount] = await sql`
      SELECT COUNT(*) as count
      FROM notifications
      WHERE user_id = ${user_id} AND is_read = false;
    `;

    return {
      notifications,
      unread_count: parseInt(unreadCount?.count || 0),
      total: notifications.length
    };
  } catch (error) {
    console.error("❌ Error fetching notifications:", error);
    throw error;
  }
}

export async function markAsRead(notification_id, user_id) {
  try {
    const [updated] = await sql`
      UPDATE notifications
      SET is_read = true
      WHERE id = ${notification_id} AND user_id = ${user_id}
      RETURNING *;
    `;

    return updated;
  } catch (error) {
    console.error("❌ Error marking notification as read:", error);
    throw error;
  }
}

export async function markAllAsRead(user_id) {
  try {
    const result = await sql`
      UPDATE notifications
      SET is_read = true
      WHERE user_id = ${user_id} AND is_read = false
      RETURNING COUNT(*) as updated_count;
    `;

    return result[0]?.updated_count || 0;
  } catch (error) {
    console.error("❌ Error marking all notifications as read:", error);
    throw error;
  }
}

export async function deleteNotification(notification_id, user_id) {
  try {
    const [deleted] = await sql`
      DELETE FROM notifications
      WHERE id = ${notification_id} AND user_id = ${user_id}
      RETURNING *;
    `;

    return deleted;
  } catch (error) {
    console.error("❌ Error deleting notification:", error);
    throw error;
  }
}
