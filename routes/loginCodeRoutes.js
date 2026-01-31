// routes/loginCodeRoutes.js
import express from 'express';
import {
  generateLoginCode,
  getAllLoginCodes,
  getLoginCodesByEmployee,
  verifyLoginCode,
  revokeLoginCode,
  cleanupExpiredCodes,
  getCodeStatistics,
  testEmail
} from '../controllers/loginCodeController.js';

const router = express.Router();

// Generate new login code
router.post('/generate', generateLoginCode);

// Get all login codes
router.get('/', getAllLoginCodes);

// Get codes by employee ID
router.get('/employee/:employeeId', getLoginCodesByEmployee);

// Verify login code (for employee app)
router.post('/verify', verifyLoginCode);

// Revoke login code
router.delete('/:id', revokeLoginCode);

// Clean up expired codes (admin only)
router.post('/cleanup', cleanupExpiredCodes);

// Get statistics
router.get('/statistics', getCodeStatistics);

router.post('/test-email', testEmail);

export default router;