// controllers/employeeController.js
import sql from "../config/db.js";

export const addEmployee = async (req, res) => {
  try {
    let { 
      first_name, 
      last_name, 
      email, 
      position, 
      id_number, 
      contact_number, 
      civil_status, 
      department, 
      status, 
      date_hired, 
      gender, 
      employment_status 
    } = req.body;

    // Convert empty id_number and email to null
    id_number = id_number?.trim() || null;
    email = email?.trim() || null;  // <-- allow multiple employees without email

    // Sanitize date_hired
    const parsedDate = new Date(date_hired);
    if (isNaN(parsedDate)) {
      date_hired = new Date().toISOString().split('T')[0]; // fallback to today
    } else {
      date_hired = parsedDate.toISOString().split('T')[0]; // format as YYYY-MM-DD
    }

    const [employee] = await sql`
      INSERT INTO employee_list (
        first_name, 
        last_name, 
        email, 
        position, 
        id_number, 
        contact_number, 
        civil_status, 
        department, 
        status, 
        date_hired,
        gender,
        employment_status
      ) VALUES (
        ${first_name}, 
        ${last_name}, 
        ${email}, 
        ${position}, 
        ${id_number}, 
        ${contact_number}, 
        ${civil_status}, 
        ${department}, 
        ${status}, 
        ${date_hired},
        ${gender},
        ${employment_status}
      )
      RETURNING *
    `;

    // AFTER employee insert
    const eligibleStatuses = ["Temporary", "Permanent", "Contractual", "Casual", "Coterminous"];

    if (eligibleStatuses.includes(employment_status)) {
      const year = new Date().getFullYear();

      // Neutral leaves for everyone
      const neutralLeaves = [
        { type: "ML", days: 5 },
        { type: "SPL", days: 3 },
        { type: "SOLO", days: 7 },
        { type: "VAWC", days: 10 },
        { type: "RL", days: 0 },
        { type: "STUDY", days: 180 },
        { type: "CALAMITY", days: 5 },
        { type: "MOL", days: 0 },
        { type: "TL", days: 0 },
        { type: "AL", days: 0 },
      ];

      // Insert neutral leaves
      for (const leave of neutralLeaves) {
        await sql`
          INSERT INTO leave_entitlements (
            user_id,
            leave_type,
            year,
            total_days,
            used_days
          ) VALUES (
            ${employee.id},
            ${leave.type},
            ${year},
            ${leave.days},
            0
          )
          ON CONFLICT (user_id, leave_type, year) DO NOTHING;
        `;
      }

      // Female-only leave
      // Female-only leaves
      if (gender === "Female") {
        await sql`
          INSERT INTO leave_entitlements (
            user_id,
            leave_type,
            year,
            total_days,
            used_days
          ) VALUES
            (${employee.id}, 'MAT', ${year}, 105, 0),
            (${employee.id}, 'MCW', ${year}, 60, 0)
          ON CONFLICT (user_id, leave_type, year) DO NOTHING;
        `;
      }


      // Male-only leave
      if (gender === "Male" && civil_status === "Married") {
        await sql`
          INSERT INTO leave_entitlements (
            user_id,
            leave_type,
            year,
            total_days,
            used_days
          ) VALUES (
            ${employee.id},
            'PAT',
            ${year},
            7,
            0
          )
          ON CONFLICT (user_id, leave_type, year) DO NOTHING;
        `;
      }
    }

    res.status(201).json(employee);
  } catch (error) {
    console.error("Error adding employee:", error);
    res.status(500).json({ error: "Failed to add employee" });
  }
};


// 📌 Get all employees
export const getEmployees = async (req, res) => {
  try {
    const role = req.query.role || "admin";
    const department = req.query.department || "";

    let result;
    
    if (role === "admin" || role === "mayor") {
      // Both admin and mayor can see all employees
      result = await sql`SELECT * FROM employee_list ORDER BY id DESC;`;
    } else {
      // Office heads can only see their department employees
      result = await sql`
        SELECT *
        FROM employee_list
        WHERE department = ${department}
        ORDER BY id DESC;
      `;
    }

    res.json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch employees" });
  }
};


// 📌 Get single employee by ID
// Reverse map: short code -> full name
const leaveTypeFullNameMap = {
  "VL": "Vacation Leave",
  "ML": "Mandatory/Forced Leave",
  "SL": "Sick Leave",
  "MAT": "Maternity Leave",
  "PAT": "Paternity Leave",
  "SPL": "Special Privilege Leave",
  "SOLO": "Solo Parent Leave",
  "STUDY": "Study Leave",
  "VAWC": "VAWC Leave",
  "RL": "Rehabilitation Leave",
  "SLBW": "Special Leave Benefits for Women",
  "CALAMITY": "Special Emergency (Calamity) Leave",
  "MOL": "Monetization of Leave Credits",
  "TL": "Terminal Leave",
  "AL": "Adoption Leave",
};

export const getEmployeeById = async (req, res) => {
  const { id } = req.params;
  try {
    // 🟢 Get employee details
    const result = await sql`
      SELECT 
        e.id,
        e.first_name,
        e.last_name,
        (e.first_name || ' ' || e.last_name) AS full_name,
        e.email,
        e.position,
        e.department,
        e.employment_status,
        e.gender,
        e.civil_status,
        e.status,
        e.date_hired,
        e.id_number,
        e.contact_number,
        e.profile_picture,
        e.created_at,
        e.updated_at,
        e.inactive_reason
      FROM employee_list e
      WHERE e.id = ${id};
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    const employee = result[0];

    // 🟢 Get leave balances
    let leaveBalances = await sql`
      SELECT leave_type, total_days, used_days, balance_days AS remaining, year
      FROM leave_entitlements
      WHERE user_id = ${employee.id};
    `;

    // Map short code -> full name
    leaveBalances = leaveBalances.map(l => ({
      ...l,
      leave_type: leaveTypeFullNameMap[l.leave_type] || l.leave_type
    }));

    // 🟢 Get last 5 attendance logs
    const attendanceLogs = await sql`
      SELECT attendance_date, am_checkin, am_checkout, pm_checkin, pm_checkout
      FROM attendance_logs
      WHERE pin = ${employee.id_number}
      ORDER BY attendance_date DESC
      LIMIT 5;
    `;

    res.json({
      ...employee,
      leaveBalances,
      attendanceLogs,
    });
  } catch (error) {
    console.error("Error fetching employee:", error);
    res.status(500).json({ error: "Failed to fetch employee" });
  }
};

// 📌 Update employee
export const updateEmployee = async (req, res) => {
  const { id } = req.params;
  const {
    first_name,
    last_name,
    email,
    position,
    department,   // ✅ plain text
    employment_status,
    gender,
    civil_status,
    status,
    date_hired,
    id_number,
    contact_number,
    inactive_reason
  } = req.body;

  try {
    const result = await sql`
      UPDATE employee_list
      SET
        first_name = ${first_name},
        last_name = ${last_name},
        email = ${email},
        position = ${position},
        department = ${department},
        employment_status = ${employment_status},
        gender = ${gender},
        civil_status = ${civil_status},
        status = ${status},
        date_hired = ${date_hired},
        id_number = ${id_number},
        contact_number = ${contact_number},
        inactive_reason = ${inactive_reason},
        updated_at = NOW()
      WHERE id = ${id}
      RETURNING *;
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    res.json(result[0]);
  } catch (error) {
    console.error("Error updating employee:", error);
    res.status(500).json({ error: "Failed to update employee" });
  }
};

// 📌 Delete employee
export const deleteEmployee = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await sql`
      DELETE FROM employee_list
      WHERE id = ${id}
      RETURNING *;
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    res.json({ message: "Employee deleted successfully" });
  } catch (error) {
    console.error("Error deleting employee:", error);
    res.status(500).json({ error: "Failed to delete employee" });
  }
};

// Count employees
export async function getEmployeeCount(req, res) {
  try {
    const role = req.query.role || "admin";
    const department = req.query.department || "";

    let result;
    if (role === "admin" || role === "mayor") {
      [result] = await sql`
        SELECT COUNT(*)::int AS total FROM employee_list
      `;
    } else {
      [result] = await sql`
        SELECT COUNT(*)::int AS total
        FROM employee_list
        WHERE department = ${department}
      `;
    }

    res.status(200).json({ total: result.total });
  } catch (error) {
    console.error("Error fetching employee count:", error);
    res.status(500).json({ message: "Internal server error" });
  }
}


// 📌 Get employee leave balances
export const getEmployeeLeaveBalances = async (req, res) => {
  const { id } = req.params;

  // Map short code -> full name
  const leaveTypeFullNameMap = {
    "VL": "Vacation Leave",
    "ML": "Mandatory/Forced Leave",
    "SL": "Sick Leave",
    "MAT": "Maternity Leave",
    "PAT": "Paternity Leave",
    "SPL": "Special Privilege Leave",
    "SOLO": "Solo Parent Leave",
    "STUDY": "Study Leave",
    "VAWC": "VAWC Leave",
    "RL": "Rehabilitation Leave",
    "SLBW": "Special Leave Benefits for Women",
    "CALAMITY": "Special Emergency (Calamity) Leave",
    "MOL": "Monetization of Leave Credits",
    "TL": "Terminal Leave",
    "AL": "Adoption Leave",
  };

  try {
    // Fetch leave entitlements for the employee
    let leaveBalances = await sql`
      SELECT 
        leave_type,
        total_days,
        used_days,
        balance_days,
        year
      FROM leave_entitlements
      WHERE user_id = ${id}
      ORDER BY leave_type;
    `;

    // Map short codes to full names
    leaveBalances = leaveBalances.map(l => ({
      ...l,
      leave_type: leaveTypeFullNameMap[l.leave_type] || l.leave_type
    }));

    res.json({
      success: true,
      leaveBalances
    });

  } catch (error) {
    console.error("Error fetching leave balances:", error);
    res.status(500).json({
      success: false,
      error: "Failed to fetch leave balances"
    });
  }
};

// 📌 Update leave entitlement
export const updateLeaveEntitlement = async (req, res) => {
  const { userId, leaveType, year, totalDays, usedDays } = req.body;
  
  try {
    // Update only total_days and used_days - balance_days will be auto-calculated
    const result = await sql`
      UPDATE leave_entitlements
      SET 
        total_days = ${totalDays},
        used_days = ${usedDays},
        updated_at = NOW()
      WHERE 
        user_id = ${userId} 
        AND leave_type = ${leaveType}
        AND year = ${year}
      RETURNING *;
    `;

    if (result.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: "Leave entitlement not found" 
      });
    }

    res.json({
      success: true,
      message: "Leave entitlement updated successfully",
      data: result[0]
    });

  } catch (error) {
    console.error("Error updating leave entitlement:", error);
    res.status(500).json({ 
      success: false, 
      error: "Failed to update leave entitlement" 
    });
  }
};