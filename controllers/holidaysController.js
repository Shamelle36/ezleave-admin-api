import sql from "../config/db.js";
import { sendPushToUser } from "../utils/fcm.js";
import { sendAndSaveNotification } from "../utils/notificationService.js";

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

// Add new local holiday with push notifications
export const addLocalHoliday = async (req, res) => {
    try {
        const { date, name, description, is_recurring, addedBy } = req.body;
        
        // Validate required fields
        if (!date || !name) {
            return res.status(400).json({ error: 'Date and name are required' });
        }

        // Get admin info if addedBy is provided
        let adminName = "Administrator";
        if (addedBy) {
            try {
                const [admin] = await sql`
                    SELECT full_name 
                    FROM admin_accounts 
                    WHERE email = ${addedBy} OR id::text = ${addedBy}
                    LIMIT 1
                `;
                if (admin) {
                    adminName = admin.full_name;
                }
            } catch (adminError) {
                console.log("Could not fetch admin details, using default name");
            }
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
        const [holiday] = await sql`
            INSERT INTO local_holidays 
            (date, name, description, is_recurring, added_by) 
            VALUES 
            (${formattedDate}, ${name}, ${sanitizedDescription}, ${is_recurring || false}, ${adminName})
            RETURNING *
        `;

        // Format date for display
        const holidayDate = new Date(formattedDate);
        const formattedDateDisplay = holidayDate.toLocaleDateString('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });

        // Send push notifications to all active employees
        try {
            // Get all active employees with FCM tokens
            const activeEmployees = await sql`
                SELECT user_id, email, CONCAT(first_name, ' ', last_name) as full_name, fcm_token
                FROM employee_list 
                WHERE status = 'Active' AND fcm_token IS NOT NULL
            `;

            console.log(`📢 Sending holiday notification to ${activeEmployees.length} employees`);

            // Send push notification to each employee
            for (const employee of activeEmployees) {
                try {
                    if (employee.fcm_token) {
                        await sendPushToUser(
                            employee.user_id,
                            "📅 New Local Holiday Added",
                            `${name} has been added as a local holiday on ${formattedDateDisplay}.`,
                            {
                                type: 'new_holiday',
                                holiday_id: holiday.id,
                                holiday_name: name,
                                holiday_date: formattedDate,
                                added_by: adminName,
                                screen: 'holidays'
                            }
                        );
                    }
                } catch (employeeError) {
                    console.error(`Error sending notification to ${employee.email}:`, employeeError);
                    // Continue with other employees
                }
            }

            // Also save notifications to database for all active employees
            await sql`
                INSERT INTO notifications (user_id, type, message, data)
                SELECT 
                    user_id,
                    'new_holiday' as type,
                    ${`New Holiday: ${name} on ${formattedDateDisplay}`} as message,
                    ${JSON.stringify({
                        holiday_id: holiday.id,
                        holiday_name: name,
                        holiday_date: formattedDate,
                        added_by: adminName
                    })} as data
                FROM employee_list 
                WHERE status = 'Active'
            `;

            console.log(`✅ Notifications saved to database for all active employees`);

        } catch (notificationError) {
            console.error("❌ Error in notification process:", notificationError);
            // Don't fail the holiday creation if notifications fail
        }

        res.status(201).json({
            message: 'Holiday added successfully',
            holiday,
            notifications_sent: true
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

// Update local holiday with notifications (optional)
export const updateLocalHoliday = async (req, res) => {
    try {
        const { id } = req.params;
        const { date, name, description, is_recurring, updatedBy } = req.body;
        
        // Validate required fields
        if (!date || !name) {
            return res.status(400).json({ error: 'Date and name are required' });
        }

        // Get admin info if updatedBy is provided
        let adminName = "Administrator";
        if (updatedBy) {
            try {
                const [admin] = await sql`
                    SELECT full_name 
                    FROM admin_accounts 
                    WHERE email = ${updatedBy} OR id::text = ${updatedBy}
                    LIMIT 1
                `;
                if (admin) {
                    adminName = admin.full_name;
                }
            } catch (adminError) {
                console.log("Could not fetch admin details, using default name");
            }
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
        
        // Get old holiday data for comparison
        const [oldHoliday] = await sql`
            SELECT name, date FROM local_holidays WHERE id = ${id}
        `;

        // Update holiday
        const [result] = await sql`
            UPDATE local_holidays 
            SET 
                date = ${formattedDate},
                name = ${name},
                description = ${sanitizedDescription},
                is_recurring = ${is_recurring || false},
                updated_at = CURRENT_TIMESTAMP,
                updated_by = ${adminName}
            WHERE id = ${id}
            RETURNING *
        `;

        if (!result || result.length === 0) {
            return res.status(404).json({ error: 'Holiday not found' });
        }

        // Send notifications if holiday was significantly changed
        if (oldHoliday && (oldHoliday.name !== name || oldHoliday.date !== formattedDate)) {
            try {
                const formattedDateDisplay = new Date(formattedDate).toLocaleDateString('en-US', {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                });

                // Save notification to database for all active employees
                await sql`
                    INSERT INTO notifications (user_id, type, message, data)
                    SELECT 
                        user_id,
                        'holiday_updated' as type,
                        ${`Holiday Updated: ${name} on ${formattedDateDisplay}`} as message,
                        ${JSON.stringify({
                            holiday_id: id,
                            old_name: oldHoliday.name,
                            new_name: name,
                            holiday_date: formattedDate,
                            updated_by: adminName
                        })} as data
                    FROM employee_list 
                    WHERE status = 'Active'
                `;

                console.log(`✅ Update notifications saved to database`);
            } catch (notificationError) {
                console.error("❌ Error sending update notifications:", notificationError);
            }
        }

        res.json({ 
            message: 'Holiday updated successfully',
            holiday: result[0]
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

// Delete local holiday with notifications
export const deleteLocalHoliday = async (req, res) => {
    try {
        const { id } = req.params;
        const { deletedBy } = req.body;
        
        if (!id) {
            return res.status(400).json({ error: 'Holiday ID is required' });
        }

        // Get admin info if deletedBy is provided
        let adminName = "Administrator";
        if (deletedBy) {
            try {
                const [admin] = await sql`
                    SELECT full_name 
                    FROM admin_accounts 
                    WHERE email = ${deletedBy} OR id::text = ${deletedBy}
                    LIMIT 1
                `;
                if (admin) {
                    adminName = admin.full_name;
                }
            } catch (adminError) {
                console.log("Could not fetch admin details, using default name");
            }
        }

        // First, get holiday details before deletion
        const [holiday] = await sql`
            SELECT name, date FROM local_holidays 
            WHERE id = ${id}
        `;

        if (!holiday) {
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
            // Send notifications about deleted holiday
            try {
                const formattedDateDisplay = new Date(holiday.date).toLocaleDateString('en-US', {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                });

                // Save notification to database for all active employees
                await sql`
                    INSERT INTO notifications (user_id, type, message, data)
                    SELECT 
                        user_id,
                        'holiday_deleted' as type,
                        ${`Holiday Removed: ${holiday.name} (${formattedDateDisplay}) has been removed`} as message,
                        ${JSON.stringify({
                            holiday_name: holiday.name,
                            holiday_date: holiday.date,
                            deleted_by: adminName
                        })} as data
                    FROM employee_list 
                    WHERE status = 'Active'
                `;

                console.log(`✅ Deletion notifications saved to database`);
            } catch (notificationError) {
                console.error("❌ Error sending deletion notifications:", notificationError);
                // Continue with successful deletion even if notifications fail
            }

            res.json({ 
                message: 'Holiday deleted successfully',
                deletedId: id,
                holiday_name: holiday.name
            });
        } else {
            return res.status(404).json({ error: 'Holiday not found or already deleted' });
        }
    } catch (error) {
        console.error('Error deleting local holiday:', error);
        res.status(500).json({ error: 'Failed to delete local holiday' });
    }
};