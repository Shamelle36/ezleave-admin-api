// holiday.js
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

// Helper function to send holiday notifications to all employees
const sendHolidayNotificationToAllEmployees = async (holiday, action = 'added') => {
    try {
        console.log(`📢 Sending holiday ${action} notification for: ${holiday.name} (${holiday.date})`);
        
        // Get all active employees
        const employees = await sql`
            SELECT user_id, first_name, last_name 
            FROM employee_list 
            WHERE status = 'Active'
        `;
        
        if (!employees || employees.length === 0) {
            console.log('No active employees found for notification');
            return;
        }
        
        const actionText = action === 'added' ? 'added' : 'updated';
        const notificationTitle = `🎉 Holiday ${action === 'added' ? 'Added' : 'Updated'}`;
        const notificationBody = `${holiday.name} has been ${actionText} to local holidays on ${holiday.date}`;
        
        let totalNotificationsSent = 0;
        
        // Send notifications to all employees
        for (const employee of employees) {
            try {
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
                        screen: 'holidays'
                    }
                );
                
                if (pushResult?.success) {
                    totalNotificationsSent++;
                }
                
                // Save notification to database
                await sql`
                    INSERT INTO notifications (user_id, message)
                    VALUES (${employee.user_id}, ${`Holiday ${actionText.charAt(0).toUpperCase() + actionText.slice(1)}: ${holiday.name} on ${holiday.date}`})
                `;
                
            } catch (empError) {
                console.error(`Error sending notification to employee ${employee.user_id}:`, empError);
                // Continue with other employees even if one fails
            }
        }
        
        console.log(`✅ Sent holiday ${action} notifications to ${totalNotificationsSent}/${employees.length} employees`);
        return totalNotificationsSent;
        
    } catch (error) {
        console.error('Error in sendHolidayNotificationToAllEmployees:', error);
        throw error;
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
        
        // Send notification to all employees about the new holiday
        // Don't await this so the API response is not delayed
        sendHolidayNotificationToAllEmployees(holiday, 'added')
            .catch(err => console.error('Error sending holiday notification:', err));

        res.status(201).json({
            message: 'Holiday added successfully',
            holiday,
            notification_sent: true
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
        
        // Send notification to all employees about the updated holiday
        if (significantChange) {
            // Don't await this so the API response is not delayed
            sendHolidayNotificationToAllEmployees(updatedHoliday, 'updated')
                .catch(err => console.error('Error sending holiday update notification:', err));
        }

        res.json({ 
            message: 'Holiday updated successfully',
            holiday: updatedHoliday,
            notification_sent: significantChange
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
            // Send notification about deleted holiday
            try {
                // Get all active employees
                const employees = await sql`
                    SELECT user_id FROM employee_list 
                    WHERE status = 'Active'
                `;
                
                if (employees && employees.length > 0) {
                    const notificationTitle = "🗑️ Holiday Removed";
                    const notificationBody = `${holidayToDelete.name} (${holidayToDelete.date}) has been removed from local holidays`;
                    
                    // Send notifications in the background
                    for (const employee of employees) {
                        try {
                            await sendPushToUser(
                                employee.user_id,
                                notificationTitle,
                                notificationBody,
                                {
                                    type: 'holiday_deleted',
                                    holiday_name: holidayToDelete.name,
                                    holiday_date: holidayToDelete.date,
                                    action: 'deleted',
                                    screen: 'holidays'
                                }
                            );
                            
                            // Save to database
                            await sql`
                                INSERT INTO notifications (user_id, message)
                                VALUES (${employee.user_id}, ${`Holiday Removed: ${holidayToDelete.name} on ${holidayToDelete.date}`})
                            `;
                            
                        } catch (empError) {
                            console.error(`Error notifying employee ${employee.user_id}:`, empError);
                        }
                    }
                }
            } catch (notifError) {
                console.error('Error sending delete notifications:', notifError);
                // Don't fail the delete operation if notifications fail
            }

            res.json({ 
                message: 'Holiday deleted successfully',
                deletedId: id,
                holiday: holidayToDelete,
                notification_sent: true
            });
        } else {
            return res.status(404).json({ error: 'Holiday not found or already deleted' });
        }
    } catch (error) {
        console.error('Error deleting local holiday:', error);
        res.status(500).json({ error: 'Failed to delete local holiday' });
    }
};