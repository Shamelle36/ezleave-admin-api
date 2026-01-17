import sql from "../config/db.js";
import { sendPushToUser } from "../utils/fcm.js";

// Get all local holidays
export const getLocalHolidays = async (req, res) => {
    try {
        const holidays = await sql`
            SELECT * FROM local_holidays 
            ORDER BY date
        `;
        res.json(holidays);
    } catch (error) {
        console.error('Error fetching local holidays:', error);
        res.status(500).json({ error: 'Failed to fetch local holidays' });
    }
};

// Helper function to send holiday notifications to all employees - CHUNKED VERSION
const sendHolidayNotificationToAllEmployees = async (holiday, action = 'added') => {
    try {
        console.log(`📢 [CHUNKED] Sending holiday ${action} notification for: ${holiday.name} (${holiday.date})`);
        const startTime = Date.now();
        
        // Get all active employees
        const employees = await sql`
            SELECT user_id, first_name, last_name 
            FROM employee_list 
            WHERE status = 'active'
        `;
        
        if (!employees || employees.length === 0) {
            console.log('No active employees found for notification');
            return 0;
        }
        
        console.log(`📊 Found ${employees.length} employees to notify`);
        
        const actionText = action === 'added' ? 'added' : (action === 'updated' ? 'updated' : 'deleted');
        let notificationTitle, notificationBody;
        
        if (action === 'deleted') {
            notificationTitle = "🗑️ Holiday Removed";
            notificationBody = `${holiday.name} (${holiday.date}) has been removed from local holidays`;
        } else {
            notificationTitle = `🎉 Holiday ${action === 'added' ? 'Added' : 'Updated'}`;
            notificationBody = `${holiday.name} has been ${actionText} to local holidays on ${holiday.date}`;
        }
        
        let totalNotificationsSent = 0;
        const CHUNK_SIZE = 10; // Process 10 employees at a time (adjust as needed)
        const totalChunks = Math.ceil(employees.length / CHUNK_SIZE);
        
        console.log(`🔄 Processing in ${totalChunks} chunks of ${CHUNK_SIZE} employees each`);
        
        // Process in chunks
        for (let chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
            const start = chunkIndex * CHUNK_SIZE;
            const end = start + CHUNK_SIZE;
            const chunk = employees.slice(start, end);
            
            console.log(`📦 Processing chunk ${chunkIndex + 1}/${totalChunks} (employees ${start + 1}-${end})`);
            
            // Create promises for this chunk
            const chunkPromises = chunk.map(employee => 
                (async () => {
                    try {
                        // Send push notification
                        const pushResult = await sendPushToUser(
                            employee.user_id,
                            notificationTitle,
                            notificationBody,
                            {
                                type: 'holiday_update',
                                holiday_id: holiday.id,
                                holiday_name: holiday.name,
                                holiday_date: holiday.date,
                                action: action,
                                screen: 'holidays',
                                chunk_index: chunkIndex
                            }
                        );
                        
                        // Save notification to database
                        await sql`
                            INSERT INTO notifications (user_id, message)
                            VALUES (${employee.user_id}, ${`Holiday ${actionText}: ${holiday.name} on ${holiday.date}`})
                        `;
                        
                        return pushResult?.success ? 1 : 0;
                    } catch (empError) {
                        console.error(`   Error for employee ${employee.user_id}:`, empError.message);
                        return 0;
                    }
                })()
            );
            
            // Process this chunk in parallel
            const chunkResults = await Promise.allSettled(chunkPromises);
            const chunkSuccess = chunkResults.reduce((sum, result) => {
                return sum + (result.value || 0);
            }, 0);
            
            totalNotificationsSent += chunkSuccess;
            console.log(`   ✅ Chunk ${chunkIndex + 1} completed: ${chunkSuccess}/${chunk.length} successful`);
            
            // Small delay between chunks to prevent overwhelming the system
            if (chunkIndex < totalChunks - 1) {
                await new Promise(resolve => setTimeout(resolve, 100)); // 100ms delay
            }
        }
        
        const timeElapsed = Date.now() - startTime;
        console.log(`🏁 Total time: ${timeElapsed}ms (${(timeElapsed/1000).toFixed(1)}s)`);
        console.log(`✅ Sent holiday ${action} notifications to ${totalNotificationsSent}/${employees.length} employees`);
        
        return totalNotificationsSent;
        
    } catch (error) {
        console.error('Error in sendHolidayNotificationToAllEmployees:', error);
        // Don't throw - just log and return 0 so it doesn't break the main operation
        return 0;
    }
};

// Helper function specifically for delete notifications (to handle status case)
const sendDeleteHolidayNotifications = async (holidayToDelete) => {
    try {
        console.log(`🗑️ [DELETE] Sending holiday delete notification for: ${holidayToDelete.name} (${holidayToDelete.date})`);
        const startTime = Date.now();
        
        // Get all active employees - try both case variations
        const employees = await sql`
            SELECT user_id, first_name, last_name 
            FROM employee_list 
            WHERE status = 'active'
        `;
        
        if (!employees || employees.length === 0) {
            console.log('No active employees found for delete notification');
            return 0;
        }
        
        console.log(`📊 Found ${employees.length} employees to notify about deletion`);
        
        const notificationTitle = "🗑️ Holiday Removed";
        const notificationBody = `${holidayToDelete.name} (${holidayToDelete.date}) has been removed from local holidays`;
        
        let totalNotificationsSent = 0;
        const CHUNK_SIZE = 10;
        const totalChunks = Math.ceil(employees.length / CHUNK_SIZE);
        
        console.log(`🔄 Processing delete in ${totalChunks} chunks`);
        
        // Process in chunks
        for (let chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
            const start = chunkIndex * CHUNK_SIZE;
            const end = start + CHUNK_SIZE;
            const chunk = employees.slice(start, end);
            
            // Create promises for this chunk
            const chunkPromises = chunk.map(employee => 
                (async () => {
                    try {
                        // Send push notification
                        const pushResult = await sendPushToUser(
                            employee.user_id,
                            notificationTitle,
                            notificationBody,
                            {
                                type: 'holiday_deleted',
                                holiday_name: holidayToDelete.name,
                                holiday_date: holidayToDelete.date,
                                action: 'deleted',
                                screen: 'holidays',
                                chunk_index: chunkIndex
                            }
                        );
                        
                        // Save notification to database
                        await sql`
                            INSERT INTO notifications (user_id, message)
                            VALUES (${employee.user_id}, ${`Holiday Removed: ${holidayToDelete.name} on ${holidayToDelete.date}`}, 'holiday')
                        `;
                        
                        return pushResult?.success ? 1 : 0;
                    } catch (empError) {
                        console.error(`   Error for employee ${employee.user_id}:`, empError.message);
                        return 0;
                    }
                })()
            );
            
            // Process this chunk in parallel
            const chunkResults = await Promise.allSettled(chunkPromises);
            const chunkSuccess = chunkResults.reduce((sum, result) => {
                return sum + (result.value || 0);
            }, 0);
            
            totalNotificationsSent += chunkSuccess;
            console.log(`   ✅ Delete chunk ${chunkIndex + 1} completed: ${chunkSuccess}/${chunk.length} successful`);
            
            // Small delay between chunks
            if (chunkIndex < totalChunks - 1) {
                await new Promise(resolve => setTimeout(resolve, 100));
            }
        }
        
        const timeElapsed = Date.now() - startTime;
        console.log(`🏁 Delete time: ${timeElapsed}ms`);
        console.log(`✅ Sent delete notifications to ${totalNotificationsSent}/${employees.length} employees`);
        
        return totalNotificationsSent;
        
    } catch (error) {
        console.error('Error in sendDeleteHolidayNotifications:', error);
        return 0;
    }
};

// Add new local holiday
export const addLocalHoliday = async (req, res) => {
    let holiday;
    try {
        const { date, name, description, is_recurring } = req.body;
        
        // Validate required fields
        if (!date || !name) {
            return res.status(400).json({ error: 'Date and name are required' });
        }

        // Format date if needed
        let formattedDate = date;
        if (typeof date === 'string') {
            const parsedDate = new Date(date);
            if (!isNaN(parsedDate)) {
                formattedDate = parsedDate.toISOString().split('T')[0];
            }
        }

        // Sanitize description
        const sanitizedDescription = description?.trim() || null;
        
        // Insert holiday
        const [result] = await sql`
            INSERT INTO local_holidays 
            (date, name, description, is_recurring) 
            VALUES 
            (${formattedDate}, ${name}, ${sanitizedDescription}, ${is_recurring || false})
            RETURNING *
        `;

        holiday = result;
        
        // Send notification to all employees about the new holiday - CHUNKED VERSION
        // Don't await this so the API response is not delayed
        sendHolidayNotificationToAllEmployees(holiday, 'added')
            .then(count => {
                console.log(`🎯 [ADD] Chunked notification process completed: ${count} sent`);
            })
            .catch(err => {
                console.error('Error in chunked holiday notification:', err);
            });

        res.status(201).json({
            message: 'Holiday added successfully',
            holiday,
            notification_started: true,
            method: 'chunked_parallel',
            response_time: 'instant'
        });
    } catch (error) {
        console.error('Error adding local holiday:', error);
        
        // Handle duplicate entry error
        if (error.code === '23505' || error.message.includes('duplicate')) {
            return res.status(400).json({ 
                error: 'Holiday for this date already exists' 
            });
        }
        
        res.status(500).json({ error: 'Failed to add local holiday' });
    }
};

// Update local holiday
export const updateLocalHoliday = async (req, res) => {
    let updatedHoliday;
    try {
        const { id } = req.params;
        const { date, name, description, is_recurring } = req.body;
        
        // Validate required fields
        if (!date || !name) {
            return res.status(400).json({ error: 'Date and name are required' });
        }

        // Format date if needed
        let formattedDate = date;
        if (typeof date === 'string') {
            const parsedDate = new Date(date);
            if (!isNaN(parsedDate)) {
                formattedDate = parsedDate.toISOString().split('T')[0];
            }
        }

        // Sanitize description
        const sanitizedDescription = description?.trim() || null;
        
        // Get old holiday data first for comparison
        const [oldHoliday] = await sql`
            SELECT * FROM local_holidays 
            WHERE id = ${id}
        `;

        if (!oldHoliday) {
            return res.status(404).json({ error: 'Holiday not found' });
        }

        // Update holiday
        const [result] = await sql`
            UPDATE local_holidays 
            SET 
                date = ${formattedDate},
                name = ${name},
                description = ${sanitizedDescription},
                is_recurring = ${is_recurring || false},
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ${id}
            RETURNING *
        `;

        if (!result) {
            return res.status(404).json({ error: 'Holiday not found' });
        }

        updatedHoliday = result;
        
        // Check if there were significant changes that warrant a notification
        const significantChange = 
            oldHoliday.name !== name || 
            oldHoliday.date !== formattedDate;
        
        // Send notification to all employees about the updated holiday - CHUNKED VERSION
        if (significantChange) {
            // Don't await this so the API response is not delayed
            sendHolidayNotificationToAllEmployees(updatedHoliday, 'updated')
                .then(count => {
                    console.log(`🎯 [UPDATE] Chunked notification process completed: ${count} sent`);
                })
                .catch(err => {
                    console.error('Error in chunked update notification:', err);
                });
        }

        res.json({ 
            message: 'Holiday updated successfully',
            holiday: updatedHoliday,
            notification_sent: significantChange,
            method: significantChange ? 'chunked_parallel' : 'none',
            response_time: 'instant'
        });
    } catch (error) {
        console.error('Error updating local holiday:', error);
        
        // Handle duplicate entry error
        if (error.code === '23505' || error.message.includes('duplicate')) {
            return res.status(400).json({ 
                error: 'Holiday for this date already exists' 
            });
        }
        
        res.status(500).json({ error: 'Failed to update local holiday' });
    }
};

// Delete local holiday
export const deleteLocalHoliday = async (req, res) => {
    try {
        const { id } = req.params;
        
        if (!id) {
            return res.status(400).json({ error: 'Holiday ID is required' });
        }

        // First, get the holiday info before deleting for notification
        const [holidayToDelete] = await sql`
            SELECT * FROM local_holidays 
            WHERE id = ${id}
        `;

        if (!holidayToDelete) {
            return res.status(404).json({ error: 'Holiday not found' });
        }

        // Delete holiday
        const result = await sql`
            DELETE FROM local_holidays 
            WHERE id = ${id}
        `;

        // For postgres.js, the result object has a 'count' property
        // that shows how many rows were affected
        if (result && result.count > 0) {
            // Send notification about deleted holiday - CHUNKED VERSION
            // Don't await this so the API response is not delayed
            sendDeleteHolidayNotifications(holidayToDelete)
                .then(count => {
                    console.log(`🎯 [DELETE] Chunked notification process completed: ${count} sent`);
                })
                .catch(err => {
                    console.error('Error in chunked delete notification:', err);
                });

            res.json({ 
                message: 'Holiday deleted successfully',
                deletedId: id,
                holiday: holidayToDelete,
                notification_started: true,
                method: 'chunked_parallel',
                response_time: 'instant'
            });
        } else {
            return res.status(404).json({ error: 'Holiday not found or already deleted' });
        }
    } catch (error) {
        console.error('Error deleting local holiday:', error);
        res.status(500).json({ error: 'Failed to delete local holiday' });
    }
};