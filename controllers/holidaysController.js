import sql from "../config/db.js";

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

// Add new local holiday
export const addLocalHoliday = async (req, res) => {
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
        const [holiday] = await sql`
            INSERT INTO local_holidays 
            (date, name, description, is_recurring) 
            VALUES 
            (${formattedDate}, ${name}, ${sanitizedDescription}, ${is_recurring || false})
            RETURNING *
        `;

        res.status(201).json({
            message: 'Holiday added successfully',
            holiday
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

        if (!result || result.length === 0) {
            return res.status(404).json({ error: 'Holiday not found' });
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

// Delete local holiday
export const deleteLocalHoliday = async (req, res) => {
    try {
        const { id } = req.params;
        
        if (!id) {
            return res.status(400).json({ error: 'Holiday ID is required' });
        }

        // First, check if the holiday exists
        const [existingHoliday] = await sql`
            SELECT id FROM local_holidays 
            WHERE id = ${id}
        `;

        if (!existingHoliday) {
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
            res.json({ 
                message: 'Holiday deleted successfully',
                deletedId: id
            });
        } else {
            return res.status(404).json({ error: 'Holiday not found or already deleted' });
        }
    } catch (error) {
        console.error('Error deleting local holiday:', error);
        res.status(500).json({ error: 'Failed to delete local holiday' });
    }
};