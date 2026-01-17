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

// Add new local holiday with notifications
export const addLocalHoliday = async (req, res) => {
    console.log("🟢 START: addLocalHoliday function called");
    console.log("📦 Request body:", JSON.stringify(req.body, null, 2));
    
    try {
        const { date, name, description, is_recurring } = req.body;
        
        // Validate required fields
        if (!date || !name) {
            console.log("❌ Validation failed: Date and name are required");
            return res.status(400).json({ error: 'Date and name are required' });
        }

        // Format date
        let formattedDate = date;
        if (typeof date === 'string') {
            const parsedDate = new Date(date);
            if (!isNaN(parsedDate)) {
                formattedDate = parsedDate.toISOString().split('T')[0];
            }
        }
        
        console.log("📅 Formatted date:", formattedDate);

        // Sanitize description
        const sanitizedDescription = description?.trim() || null;
        
        // Insert holiday
        console.log("💾 Inserting holiday into database...");
        const [holiday] = await sql`
            INSERT INTO local_holidays 
            (date, name, description, is_recurring) 
            VALUES 
            (${formattedDate}, ${name}, ${sanitizedDescription}, ${is_recurring || false})
            RETURNING *
        `;
        
        console.log("✅ Holiday inserted with ID:", holiday.id);

        // Format date for display
        const holidayDate = new Date(formattedDate);
        const formattedDateDisplay = holidayDate.toLocaleDateString('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
        
        console.log("📝 Formatted display date:", formattedDateDisplay);

        // Send notifications to all active employees
        console.log("🔔 Starting notification process...");
        try {
            // Get all active employees
            console.log("👥 Fetching active employees...");
            const allActiveEmployees = await sql`
                SELECT user_id, fcm_token, email
                FROM employee_list 
                WHERE status = 'Active'
            `;

            console.log(`📊 Found ${allActiveEmployees.length} active employees`);
            
            if (allActiveEmployees.length === 0) {
                console.log("⚠️ No active employees found. Skipping notifications.");
            }

            let notificationCount = 0;
            let pushNotificationCount = 0;

            // Process each employee
            for (const employee of allActiveEmployees) {
                try {
                    // Create notification message
                    const message = `New Holiday: ${name} on ${formattedDateDisplay}`;
                    
                    // Save notification to database
                    const notificationResult = await sql`
                        INSERT INTO notifications (user_id, message)
                        VALUES (${employee.user_id}, ${message})
                        RETURNING id
                    `;
                    
                    if (notificationResult && notificationResult.length > 0) {
                        notificationCount++;
                        console.log(`✅ Notification saved for ${employee.email}`);
                    }
                    
                    // Send push notification if employee has FCM token
                    if (employee.fcm_token) {
                        try {
                            const pushResult = await sendPushToUser(
                                employee.user_id,
                                "📅 New Local Holiday Added",
                                `${name} has been added as a local holiday on ${formattedDateDisplay}.`,
                                {
                                    type: 'new_holiday',
                                    holiday_id: holiday.id,
                                    holiday_name: name,
                                    holiday_date: formattedDate,
                                    screen: 'holidays'
                                }
                            );
                            
                            if (pushResult && pushResult.success) {
                                pushNotificationCount++;
                                console.log(`✅ Push sent to ${employee.email}`);
                            }
                        } catch (pushError) {
                            console.error(`❌ Push error for ${employee.email}:`, pushError);
                        }
                    }
                    
                } catch (employeeError) {
                    console.error(`❌ Error for employee ${employee.email}:`, employeeError);
                }
            }

            console.log(`\n📊 NOTIFICATION SUMMARY:`);
            console.log(`   Total employees: ${allActiveEmployees.length}`);
            console.log(`   DB notifications: ${notificationCount}`);
            console.log(`   Push notifications: ${pushNotificationCount}`);

        } catch (notificationError) {
            console.error("❌ Error in notification process:", notificationError);
        }

        console.log("\n✅ Holiday creation completed");
        res.status(201).json({
            message: 'Holiday added successfully',
            holiday
        });
        
    } catch (error) {
        console.error('❌ Error adding local holiday:', error);
        
        if (error.code === '23505' || error.message.includes('duplicate')) {
            return res.status(400).json({ 
                error: 'Holiday for this date already exists' 
            });
        }
        
        res.status(500).json({ error: 'Failed to add local holiday' });
    }
};

// Update local holiday with notifications
export const updateLocalHoliday = async (req, res) => {
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
        
        // Get old holiday data for comparison
        const [oldHoliday] = await sql`
            SELECT name, date FROM local_holidays WHERE id = ${id}
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

        // Send notifications if holiday was significantly changed
        if (oldHoliday.name !== name || oldHoliday.date !== formattedDate) {
            try {
                const formattedDateDisplay = new Date(formattedDate).toLocaleDateString('en-US', {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                });

                const oldDateDisplay = new Date(oldHoliday.date).toLocaleDateString('en-US', {
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                });

                // Get all active employees
                const allActiveEmployees = await sql`
                    SELECT user_id, fcm_token
                    FROM employee_list 
                    WHERE status = 'Active'
                `;

                console.log(`📊 Sending update notifications to ${allActiveEmployees.length} employees`);

                // Save update notifications to database
                for (const employee of allActiveEmployees) {
                    try {
                        const message = `Holiday Updated: ${oldHoliday.name} (${oldDateDisplay}) changed to ${name} (${formattedDateDisplay})`;
                        
                        await sql`
                            INSERT INTO notifications (user_id, message)
                            VALUES (${employee.user_id}, ${message})
                        `;
                        
                        // Send push notification if employee has FCM token
                        if (employee.fcm_token) {
                            await sendPushToUser(
                                employee.user_id,
                                "📅 Holiday Updated",
                                `${oldHoliday.name} has been updated to ${name} on ${formattedDateDisplay}`,
                                {
                                    type: 'holiday_updated',
                                    holiday_id: id,
                                    old_name: oldHoliday.name,
                                    new_name: name,
                                    holiday_date: formattedDate,
                                    screen: 'holidays'
                                }
                            );
                        }
                    } catch (employeeError) {
                        console.error(`Error processing employee ${employee.user_id}:`, employeeError);
                    }
                }
                
                console.log(`✅ Update notifications sent`);

            } catch (notificationError) {
                console.error("Error sending update notifications:", notificationError);
            }
        }

        res.json({ 
            message: 'Holiday updated successfully',
            holiday: result
        });
        
    } catch (error) {
        console.error('Error updating local holiday:', error);
        
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
        
        if (!id) {
            return res.status(400).json({ error: 'Holiday ID is required' });
        }

        // First, get holiday details before deletion
        const [holiday] = await sql`
            SELECT name, date FROM local_holidays 
            WHERE id = ${id}
        `;

        if (!holiday) {
            return res.status(404).json({ error: 'Holiday not found' });
        }

        // Format date for display
        const formattedDateDisplay = new Date(holiday.date).toLocaleDateString('en-US', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });

        // Send notifications BEFORE deletion
        try {
            // Get all active employees
            const allActiveEmployees = await sql`
                SELECT user_id, fcm_token
                FROM employee_list 
                WHERE status = 'Active'
            `;

            console.log(`📊 Sending deletion notifications to ${allActiveEmployees.length} employees`);

            // Save deletion notifications to database
            for (const employee of allActiveEmployees) {
                try {
                    const message = `Holiday Removed: ${holiday.name} (${formattedDateDisplay}) has been removed`;
                    
                    await sql`
                        INSERT INTO notifications (user_id, message)
                        VALUES (${employee.user_id}, ${message})
                    `;
                    
                    // Send push notification if employee has FCM token
                    if (employee.fcm_token) {
                        await sendPushToUser(
                            employee.user_id,
                            "📅 Holiday Removed",
                            `${holiday.name} (${formattedDateDisplay}) has been removed as a local holiday.`,
                            {
                                type: 'holiday_deleted',
                                holiday_name: holiday.name,
                                holiday_date: holiday.date,
                                screen: 'holidays'
                            }
                        );
                    }
                } catch (employeeError) {
                    console.error(`Error processing employee ${employee.user_id}:`, employeeError);
                }
            }
            
            console.log(`✅ Deletion notifications sent`);

        } catch (notificationError) {
            console.error("Error sending deletion notifications:", notificationError);
        }

        // Delete holiday
        const result = await sql`
            DELETE FROM local_holidays 
            WHERE id = ${id}
        `;

        if (result && result.count > 0) {
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