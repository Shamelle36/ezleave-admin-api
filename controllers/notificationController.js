import sql from "../config/db.js"; // PostgreSQL connection

// ================================
// MARK single notification as read
// ================================
export const markNotificationAsRead = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await sql`
      UPDATE notifications
      SET read = true
      WHERE id = ${id}
      RETURNING *
    `;

    if (result.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Notification not found"
      });
    }

    res.json({
      success: true,
      message: "Notification marked as read",
      data: result[0]
    });

  } catch (error) {
    console.error("Error marking notification as read:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// ================================
// MARK ALL notifications as read for a user
// ================================
export const markAllNotificationsAsRead = async (req, res) => {
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({
      success: false,
      message: "User ID is required"
    });
  }

  try {
    const result = await sql`
      UPDATE notifications
      SET read = true
      WHERE user_id = ${userId} AND read = false
      RETURNING COUNT(*) as updated_count
    `;

    res.json({
      success: true,
      message: `Marked ${result[0].updated_count} notifications as read`,
      data: {
        updatedCount: parseInt(result[0].updated_count)
      }
    });

  } catch (error) {
    console.error("Error marking all notifications as read:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};