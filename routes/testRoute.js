// In your routes file (e.g., routes.js or index.js)
import express from 'express';
import { testExpoPush } from '../utils/fcm.js';

const router = express.Router();

// Add this test route
router.post('/test-push', async (req, res) => {
  try {
    console.log('🧪 Testing push notification...');
    
    // Use the test function
    const result = await testExpoPush();
    
    res.json({
      success: true,
      message: 'Test push sent',
      result: result
    });
  } catch (error) {
    console.error('❌ Test failed:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

export default router;