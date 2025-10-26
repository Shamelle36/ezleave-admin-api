import sql from "../config/db.js";  // using postgres client

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

// 📌 Get all attendance logs
export const getAttendanceLogs = async (req, res) => {
  try {
    const { date } = req.query; // YYYY-MM-DD
    const formattedDate = date || new Date().toISOString().split("T")[0];

    // Fetch employees, attendance, and leave applications
    const result = await sql`
      SELECT el.id, el.id_number, el.first_name, el.last_name,
             CONCAT(el.first_name, ' ', el.last_name) AS name,
             al.attendance_date,
             al.am_checkin, al.am_checkout,
             al.pm_checkin, al.pm_checkout,
             la.id AS leave_id,
             la.leave_type
      FROM employee_list el
      LEFT JOIN attendance_logs al
      ON el.id_number = al.pin AND al.attendance_date = ${formattedDate}
      LEFT JOIN leave_applications la
      ON el.user_id = la.user_id 
         AND ${formattedDate}::date <@ la.inclusive_dates
         AND la.status = 'Approved'
      ORDER BY el.last_name ASC
    `;

    const logs = result.map(row => {
      // Determine status
      let status = "Absent";
      if (row.leave_id) {
        status = "On-Leave";
      } else if (row.am_checkin || row.pm_checkin) {
        status = "Present";
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
        status
      };
    });

    res.json(logs);
  } catch (err) {
    console.error("❌ Error fetching attendance logs:", err.message);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

