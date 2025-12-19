// File: routes/pushRoutes.js
import express from "express";

const router = express.Router();


// Test sending notification to a user
router.post('/test-send-notification', async (req, res) => {
  try {
    const { user_id, title, message } = req.body;
    
    console.log('🧪 Testing push notification for user:', user_id);
    
    if (!user_id) {
      return res.status(400).json({ 
        success: false, 
        message: 'User ID is required' 
      });
    }
    
    // Import your fcm functions
    const { sendPushToUser } = await import('../utils/fcm.js');
    
    // Send test notification
    const result = await sendPushToUser(
      user_id,
      title || 'Test Notification 🧪',
      message || 'This is a test notification from admin!',
      {
        type: 'test',
        timestamp: new Date().toISOString(),
        test: true
      }
    );
    
    console.log('📤 Test notification result:', result);
    
    res.json({
      success: true,
      message: 'Test notification sent',
      result
    });
    
  } catch (error) {
    console.error('❌ Error sending test notification:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to send test notification',
      error: error.message 
    });
  }
});

export default router;