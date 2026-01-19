import sql from "../config/db.js";

// Helper to format PH time
const formatPHTime = (date) => {
  if (!date) return null;
  return new Intl.DateTimeFormat("en-PH", {
    timeZone: "Asia/Manila",
    hour: "2-digit",
    minute: "2-digit",
    hour12: true,
  }).format(new Date(date));
};

// Helper to get time settings for a specific date
const getTimeSettingsForDate = async (dateString) => {
  try {
    const date = new Date(dateString);
    const dayOfWeek = date.getDay(); // 0 = Sunday, 1 = Monday, etc.
    
    const dayMapping = {
      0: 'sunday',
      1: 'monday',
      2: 'tuesday',
      3: 'wednesday',
      4: 'thursday',
      5: 'friday',
      6: 'saturday'
    };
    
    const dayName = dayMapping[dayOfWeek];
    
    const result = await sql`
      SELECT * FROM attendance_time_settings WHERE day_of_week = ${dayName}
    `;
    
    if (result.length === 0) {
      return null;
    }
    
    const setting = result[0];
    return {
      day: setting.day_of_week,
      start: setting.start_time.substring(0, 5),
      end: setting.end_time.substring(0, 5),
      is_active: setting.is_active
    };
  } catch (error) {
    console.error('❌ Error getting time settings:', error.message);
    return null;
  }
};

// Helper to check if checkin time is late
const isCheckinLate = (checkinTime, timeSettings) => {
  if (!checkinTime || !timeSettings || !timeSettings.is_active) return false;
  
  const [checkinHour, checkinMinute] = checkinTime.split(':').map(Number);
  const [startHour, startMinute] = timeSettings.start.split(':').map(Number);
  
  const checkinTotal = checkinHour * 60 + checkinMinute;
  const startTotal = startHour * 60 + startMinute;
  
  return checkinTotal > startTotal;
};

// 📌 Get all attendance logs for a specific employee
export const getEmployeeAttendance = async (req, res) => {
  try {
    const { id } = req.params;

    // Fetch employee details
    const employee = await sql`
      SELECT id, id_number, first_name, last_name, middle_name
      FROM employee_list 
      WHERE id = ${id}
    `;

    if (employee.length === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    // Fetch all attendance logs for this employee
    const result = await sql`
      SELECT 
        al.attendance_date,
        al.am_checkin,
        al.am_checkout,
        al.pm_checkin,
        al.pm_checkout,
        la.leave_type,
        la.status as leave_status
      FROM attendance_logs al
      LEFT JOIN leave_applications la ON 
        al.pin = ${employee[0].id_number}
        AND al.attendance_date <@ la.inclusive_dates
        AND la.status = 'Approved'
      WHERE al.pin = ${employee[0].id_number}
      ORDER BY al.attendance_date DESC
    `;

    // Fetch time settings for all dates
    const logs = await Promise.all(result.map(async (row) => {
      // Get time settings for this date
      const timeSettings = await getTimeSettingsForDate(row.attendance_date);
      
      // Helper function to extract time from timestamp
      const extractTime = (timestamp) => {
        if (!timestamp) return null;
        return timestamp.toString().substring(11, 16); // Get HH:MM
      };
      
      // Check if AM checkin is late
      const amCheckinTime = extractTime(row.am_checkin);
      const isAmLate = amCheckinTime ? isCheckinLate(amCheckinTime, timeSettings) : false;
      
      // Check if PM checkin is late (only if no AM checkin)
      const pmCheckinTime = extractTime(row.pm_checkin);
      const isPmLate = !row.am_checkin && pmCheckinTime ? isCheckinLate(pmCheckinTime, timeSettings) : false;
      
      const isLate = isAmLate || isPmLate;

      // Determine status
      let status = "Absent";
      if (row.leave_status === 'Approved') {
        status = "On-Leave";
      } else if (row.am_checkin || row.pm_checkin) {
        status = isLate ? "Late" : "Present";
      }

      return {
        attendance_date: row.attendance_date,
        am_checkin: row.am_checkin ? formatPHTime(row.am_checkin) : null,
        am_checkout: row.am_checkout ? formatPHTime(row.am_checkout) : null,
        pm_checkin: row.pm_checkin ? formatPHTime(row.pm_checkin) : null,
        pm_checkout: row.pm_checkout ? formatPHTime(row.pm_checkout) : null,
        status: status,
        is_late: isLate,
        leave_type: row.leave_type || null
      };
    }));

    res.json({
      employee: employee[0],
      attendanceLogs: logs
    });
  } catch (err) {
    console.error("❌ Error fetching employee attendance:", err.message);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

// 📌 Get all attendance logs (for main attendance page)
export const getAttendanceLogs = async (req, res) => {
  try {
    const { date } = req.query; // YYYY-MM-DD
    const formattedDate = date || new Date().toISOString().split("T")[0];

    // Get time settings for this date
    const timeSettings = await getTimeSettingsForDate(formattedDate);

    // Fetch employees, attendance, and leave applications
    const result = await sql`
      SELECT el.id, el.id_number, el.first_name, el.last_name,
       CONCAT(el.first_name, ' ', el.last_name) AS name,
       al.attendance_date,
       al.am_checkin, al.am_checkout,
       al.pm_checkin, al.pm_checkout,
       MAX(la.leave_type) AS leave_type
        FROM employee_list el
        LEFT JOIN attendance_logs al
          ON el.id_number = al.pin AND al.attendance_date = ${formattedDate}
        LEFT JOIN leave_applications la
          ON el.user_id = la.user_id 
            AND ${formattedDate}::date <@ la.inclusive_dates
            AND la.status = 'Approved'
        GROUP BY el.id, el.id_number, el.first_name, el.last_name, 
                al.attendance_date, al.am_checkin, al.am_checkout,
                al.pm_checkin, al.pm_checkout
        ORDER BY el.last_name ASC
    `;

    const logs = result.map(row => {
      // Helper function to extract time from timestamp
      const extractTime = (timestamp) => {
        if (!timestamp) return null;
        return timestamp.toString().substring(11, 16); // Get HH:MM
      };
      
      // Check if AM checkin is late
      const amCheckinTime = extractTime(row.am_checkin);
      const isAmLate = amCheckinTime ? isCheckinLate(amCheckinTime, timeSettings) : false;
      
      // Check if PM checkin is late (only if no AM checkin)
      const pmCheckinTime = extractTime(row.pm_checkin);
      const isPmLate = !row.am_checkin && pmCheckinTime ? isCheckinLate(pmCheckinTime, timeSettings) : false;
      
      const isLate = isAmLate || isPmLate;

      // Determine status
      let status = "Absent";
      if (row.leave_id) {
        status = "On-Leave";
      } else if (row.am_checkin || row.pm_checkin) {
        status = isLate ? "Late" : "Present";
      }

      return {
        id: row.id,
        pin: row.id_number,
        name: row.name,
        attendance_date: formattedDate,
        am_checkin: row.am_checkin ? formatPHTime(row.am_checkin) : null,
        am_checkout: row.am_checkout ? formatPHTime(row.am_checkout) : null,
        pm_checkin: row.pm_checkin ? formatPHTime(row.pm_checkin) : null,
        pm_checkout: row.pm_checkout ? formatPHTime(row.pm_checkout) : null,
        status: status,
        is_late: isLate,
        leave_type: row.leave_type || null
      };
    });

    res.json(logs);
  } catch (err) {
    console.error("❌ Error fetching attendance logs:", err.message);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

// ==================== ATTENDANCE TIME SETTINGS CONTROLLERS ====================

// 📌 Get all attendance time settings
export const getAllTimeSettings = async (req, res) => {
  try {
    const result = await sql`
      SELECT * FROM attendance_time_settings 
      ORDER BY 
        CASE day_of_week
          WHEN 'monday' THEN 1
          WHEN 'tuesday' THEN 2
          WHEN 'wednesday' THEN 3
          WHEN 'thursday' THEN 4
          WHEN 'friday' THEN 5
          WHEN 'saturday' THEN 6
          WHEN 'sunday' THEN 7
        END
    `;
    
    // Format the response
    const formattedSettings = result.reduce((acc, setting) => {
      acc[setting.day_of_week] = {
        start: setting.start_time.substring(0, 5), // Convert HH:MM:SS to HH:MM
        end: setting.end_time.substring(0, 5),
        is_active: setting.is_active
      };
      return acc;
    }, {});
    
    res.json(formattedSettings);
  } catch (error) {
    console.error('❌ Error fetching time settings:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// 📌 Update or create attendance time settings
export const updateTimeSettings = async (req, res) => {
  try {
    const settings = req.body;
    
    // Validate input
    if (!settings || typeof settings !== 'object') {
      return res.status(400).json({ error: 'Invalid settings data' });
    }
    
    // Use transaction for multiple updates/inserts
    await sql.begin(async (sql) => {
      for (const [day, config] of Object.entries(settings)) {
        if (config.start && config.end) {
          // Ensure time format has seconds
          const startTime = config.start.includes(':') ? 
            (config.start.split(':').length === 2 ? config.start + ':00' : config.start) : 
            config.start + ':00';
          
          const endTime = config.end.includes(':') ? 
            (config.end.split(':').length === 2 ? config.end + ':00' : config.end) : 
            config.end + ':00';
          
          // Check if the day already exists
          const existing = await sql`
            SELECT id FROM attendance_time_settings WHERE day_of_week = ${day}
          `;
          
          if (existing.length > 0) {
            // Update existing
            await sql`
              UPDATE attendance_time_settings 
              SET start_time = ${startTime}, end_time = ${endTime}, 
                  is_active = ${config.is_active !== undefined ? config.is_active : true},
                  updated_at = CURRENT_TIMESTAMP
              WHERE day_of_week = ${day}
            `;
          } else {
            // Insert new
            await sql`
              INSERT INTO attendance_time_settings (day_of_week, start_time, end_time, is_active)
              VALUES (${day}, ${startTime}, ${endTime}, ${config.is_active !== undefined ? config.is_active : true})
            `;
          }
        }
      }
    });
    
    res.json({ 
      success: true, 
      message: 'Time settings saved successfully' 
    });
  } catch (error) {
    console.error('❌ Error updating time settings:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// 📌 Get time setting for a specific day
export const getTimeSettingByDay = async (req, res) => {
  try {
    const { day } = req.params;
    
    const result = await sql`
      SELECT * FROM attendance_time_settings WHERE day_of_week = ${day.toLowerCase()}
    `;
    
    if (result.length === 0) {
      return res.status(404).json({ error: 'Time setting not found' });
    }
    
    const setting = result[0];
    res.json({
      day: setting.day_of_week,
      start: setting.start_time.substring(0, 5),
      end: setting.end_time.substring(0, 5),
      is_active: setting.is_active
    });
  } catch (error) {
    console.error('❌ Error fetching time setting:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// 📌 Reset to default settings
export const resetToDefault = async (req, res) => {
  try {
    const defaultSettings = [
      ['monday', '08:00:00', '17:00:00', true],
      ['tuesday', '08:00:00', '17:00:00', true],
      ['wednesday', '08:00:00', '17:00:00', true],
      ['thursday', '08:00:00', '17:00:00', true],
      ['friday', '08:00:00', '17:00:00', true],
      ['saturday', '08:00:00', '12:00:00', false],
      ['sunday', '08:00:00', '12:00:00', false]
    ];
    
    await sql.begin(async (sql) => {
      for (const [day, start, end, is_active] of defaultSettings) {
        const existing = await sql`
          SELECT id FROM attendance_time_settings WHERE day_of_week = ${day}
        `;
        
        if (existing.length > 0) {
          await sql`
            UPDATE attendance_time_settings 
            SET start_time = ${start}, end_time = ${end}, 
                is_active = ${is_active}, updated_at = CURRENT_TIMESTAMP
            WHERE day_of_week = ${day}
          `;
        } else {
          await sql`
            INSERT INTO attendance_time_settings (day_of_week, start_time, end_time, is_active)
            VALUES (${day}, ${start}, ${end}, ${is_active})
          `;
        }
      }
    });
    
    res.json({ 
      success: true, 
      message: 'Reset to default settings successful' 
    });
  } catch (error) {
    console.error('❌ Error resetting settings:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// 📌 Toggle day active/inactive
export const toggleDayActive = async (req, res) => {
  try {
    const { day } = req.params;
    const { is_active } = req.body;
    
    const result = await sql`
      UPDATE attendance_time_settings 
      SET is_active = ${is_active}, updated_at = CURRENT_TIMESTAMP
      WHERE day_of_week = ${day}
      RETURNING *
    `;
    
    if (result.length === 0) {
      return res.status(404).json({ error: 'Time setting not found' });
    }
    
    res.json({ 
      success: true, 
      message: 'Day status updated',
      setting: result[0]
    });
  } catch (error) {
    console.error('❌ Error toggling day active:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// 📌 Helper function to check if employee is late (to be used in other controllers)
export const checkIfLate = async (checkinTime, dayOfWeek) => {
  if (!checkinTime) return false;
  
  const dayMapping = {
    0: 'sunday',
    1: 'monday',
    2: 'tuesday',
    3: 'wednesday',
    4: 'thursday',
    5: 'friday',
    6: 'saturday'
  };
  
  const day = dayMapping[dayOfWeek];
  
  try {
    const result = await sql`
      SELECT * FROM attendance_time_settings WHERE day_of_week = ${day}
    `;
    
    if (result.length === 0 || !result[0].is_active) {
      return false;
    }
    
    const timeSetting = result[0];
    
    // Extract HH:MM from checkinTime (could be timestamp or string)
    const checkinStr = typeof checkinTime === 'string' ? checkinTime : checkinTime.toString();
    const checkinMatch = checkinStr.match(/(\d{1,2}):(\d{1,2})/);
    if (!checkinMatch) return false;
    
    const checkinHour = parseInt(checkinMatch[1]);
    const checkinMinute = parseInt(checkinMatch[2]);
    
    const [startHour, startMinute] = timeSetting.start_time.substring(0, 5).split(':').map(Number);
    
    const checkinTotal = checkinHour * 60 + checkinMinute;
    const startTotal = startHour * 60 + startMinute;
    
    return checkinTotal > startTotal;
  } catch (error) {
    console.error('❌ Error checking if late:', error.message);
    return false;
  }
};

// 📌 Get current day's time settings
export const getCurrentDaySettings = async () => {
  try {
    const today = new Date();
    const dayOfWeek = today.getDay(); // 0 = Sunday, 1 = Monday, etc.
    
    const dayMapping = {
      0: 'sunday',
      1: 'monday',
      2: 'tuesday',
      3: 'wednesday',
      4: 'thursday',
      5: 'friday',
      6: 'saturday'
    };
    
    const day = dayMapping[dayOfWeek];
    
    const result = await sql`
      SELECT * FROM attendance_time_settings WHERE day_of_week = ${day}
    `;
    
    if (result.length === 0) {
      return null;
    }
    
    const setting = result[0];
    return {
      day: setting.day_of_week,
      start: setting.start_time.substring(0, 5),
      end: setting.end_time.substring(0, 5),
      is_active: setting.is_active
    };
  } catch (error) {
    console.error('❌ Error getting current day settings:', error.message);
    return null;
  }
};

// 📌 Calculate late employees for today
export const calculateLateEmployees = async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const dayOfWeek = new Date().getDay();
    
    // Get today's time settings
    const dayMapping = {
      0: 'sunday',
      1: 'monday',
      2: 'tuesday',
      3: 'wednesday',
      4: 'thursday',
      5: 'friday',
      6: 'saturday'
    };
    
    const day = dayMapping[dayOfWeek];
    
    const timeSettingResult = await sql`
      SELECT * FROM attendance_time_settings WHERE day_of_week = ${day}
    `;
    
    if (timeSettingResult.length === 0) {
      return res.json({ lateEmployees: [], count: 0 });
    }
    
    const timeSetting = timeSettingResult[0];
    
    // If day is inactive, no one is late
    if (!timeSetting.is_active) {
      return res.json({ lateEmployees: [], count: 0 });
    }
    
    // Get attendance logs for today
    const attendanceResult = await sql`
      SELECT 
        al.pin,
        el.first_name,
        el.last_name,
        al.am_checkin,
        al.pm_checkin
      FROM attendance_logs al
      JOIN employee_list el ON al.pin = el.id_number
      WHERE al.attendance_date = ${today}
        AND (al.am_checkin IS NOT NULL OR al.pm_checkin IS NOT NULL)
    `;
    
    const [startHour, startMinute] = timeSetting.start_time.substring(0, 5).split(':').map(Number);
    const startTotalMinutes = startHour * 60 + startMinute;
    
    const lateEmployees = attendanceResult.filter(emp => {
      // Helper to extract HH:MM from timestamp
      const extractTime = (timestamp) => {
        if (!timestamp) return null;
        return timestamp.toString().substring(11, 16);
      };
      
      // Check AM checkin
      if (emp.am_checkin) {
        const checkinTime = extractTime(emp.am_checkin);
        if (checkinTime) {
          const [checkinHour, checkinMinute] = checkinTime.split(':').map(Number);
          const checkinTotalMinutes = checkinHour * 60 + checkinMinute;
          return checkinTotalMinutes > startTotalMinutes;
        }
      }
      
      // Check PM checkin (if no AM checkin)
      if (!emp.am_checkin && emp.pm_checkin) {
        const checkinTime = extractTime(emp.pm_checkin);
        if (checkinTime) {
          const [checkinHour, checkinMinute] = checkinTime.split(':').map(Number);
          const checkinTotalMinutes = checkinHour * 60 + checkinMinute;
          return checkinTotalMinutes > startTotalMinutes;
        }
      }
      
      return false;
    }).map(emp => ({
      id: emp.pin,
      name: `${emp.first_name} ${emp.last_name}`,
      checkinTime: formatPHTime(emp.am_checkin || emp.pm_checkin),
      checkinType: emp.am_checkin ? 'AM' : 'PM'
    }));
    
    res.json({
      lateEmployees,
      count: lateEmployees.length,
      daySettings: {
        day: timeSetting.day_of_week,
        startTime: timeSetting.start_time.substring(0, 5),
        endTime: timeSetting.end_time.substring(0, 5)
      }
    });
    
  } catch (error) {
    console.error('❌ Error calculating late employees:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
};

