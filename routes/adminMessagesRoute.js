import express from 'express';
import {
  getAllAccountsForAdmin,
  getAdminMessages,
  getAdminContacts,
  getAdminConversation,
  sendAdminMessage,
  togglePinMessage,
  getMessageStats,
  markMessagesAsRead
} from '../controllers/adminMessagesController.js';

const router = express.Router();

// Get all accounts from all tables
router.get('/accounts', getAllAccountsForAdmin);

// Get messages for specific admin
router.get('/messages/:admin_id/:admin_type', getAdminMessages);

// Get conversation between admin and contact
router.get('/conversation/:admin_id/:admin_type/:contact_id/:contact_type', getAdminConversation);

// Get contacts for specific admin
router.get('/contacts/:admin_id/:admin_type', getAdminContacts);

// Send message
router.post('/send', sendAdminMessage);

// Toggle pin status
router.patch('/pin/:message_id', togglePinMessage);

// Mark messages as read
router.post('/mark-read', markMessagesAsRead);

// Get message statistics
router.get('/stats', getMessageStats);

export default router;