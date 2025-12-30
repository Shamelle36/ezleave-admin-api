import express from 'express';
import {
    getLocalHolidays,
    addLocalHoliday,
    updateLocalHoliday,
    deleteLocalHoliday
} from '../controllers/holidaysController.js';

const router = express.Router();

// Local holidays routes
router.get('/local', getLocalHolidays);
router.post('/local', addLocalHoliday);
router.put('/local/:id', updateLocalHoliday);
router.delete('/local/:id', deleteLocalHoliday);

export default router;