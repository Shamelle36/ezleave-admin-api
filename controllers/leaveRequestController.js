import sql from "../config/db.js"; // assuming you're using postgres client

const leaveTypeMap = {
  "Vacation Leave": "VL",
  "Mandatory/Forced Leave": "ML",
  "Sick Leave": "SL",
  "Maternity Leave": "MAT",
  "Paternity Leave": "PAT",
  "Special Privilege Leave": "SPL",
  "Solo Parent Leave": "SOLO",
  "Study Leave": "STUDY",
  "VAWC Leave": "VAWC",
  "Rehabilitation Leave": "RL",
  "Special Leave Benefits for Women": "SLBW",
  "Special Emergency (Calamity) Leave": "CALAMITY",
  "Monetization of Leave Credits": "MOL",
  "Terminal Leave": "TL",
  "Adoption Leave": "AL",
};


export async function getLeaveRequests(req, res) {
  try {
    // 1. Fetch leave requests with employee info
    const leaveRequests = await sql`
      SELECT 
        lr.id,
        lr.user_id,
        el.email,
        el.id_number,
        el.department,
        el.position,
        lr.salary,
        el.profile_picture,
        TO_CHAR(lr.date_filing, 'FMMonth DD, YYYY') AS date_filing,
        lr.leave_type,
        lr.details,
        TO_CHAR(lower(lr.inclusive_dates), 'FMMonth DD, YYYY') AS inclusive_date_start,
        TO_CHAR(upper(lr.inclusive_dates), 'FMMonth DD, YYYY') AS inclusive_date_end,
        lr.number_of_days,
        lr.commutation_requested,
        lr.status,
        lr.approved_by,
        lr.remarks,
        lr.created_at,
        lr.updated_at,
        lr.first_name,
        lr.middle_name,
        lr.last_name
      FROM leave_applications lr
      JOIN employee_list el 
        ON lr.user_id = el.user_id
      ORDER BY lr.created_at DESC;
    `;

    // 2. For each leave request, fetch entitlement and calculate balance
    const enriched = await Promise.all(
      leaveRequests.map(async (lr) => {
        const leaveCode = leaveTypeMap[lr.leave_type] || null;
        if (!leaveCode) return { ...lr, entitled: 0, used: 0, balance: 0 };

        // 1. Get employee_list.id (numeric) for this lr.user_id
        const [employee] = await sql`
          SELECT id
          FROM employee_list
          WHERE user_id = ${lr.user_id}
        `;

        if (!employee) return { ...lr, entitled: 0, used: 0, balance: 0 };

        // 2. Fetch entitlement using numeric id
        const [entitlement] = await sql`
          SELECT total_days, used_days
          FROM leave_entitlements
          WHERE user_id = ${employee.id}  -- numeric ID now
            AND leave_type = ${leaveCode}
            AND year = EXTRACT(YEAR FROM CURRENT_DATE)
        `;

        return {
          ...lr,
          entitled: entitlement?.total_days || 0,
          used: entitlement?.used_days || 0,
          balance: entitlement ? entitlement.total_days - entitlement.used_days : 0, 
        };
      })
    );


    res.json(enriched);
  } catch (err) {
    console.error("Error fetching leave requests:", err);
    res.status(500).json({ error: "Failed to fetch leave requests" });
  }
}

export async function getLeaveRequestsCount(req, res) {
  try {
    const [result] = await sql`
      SELECT 
        COUNT(*) FILTER (WHERE status = 'Pending')::int   AS pending,
        COUNT(*) FILTER (WHERE status = 'Approved')::int  AS approved,
        COUNT(*) FILTER (WHERE status = 'Rejected')::int  AS rejected,
        COUNT(*)::int AS total
      FROM leave_applications;
    `;

    res.status(200).json(result);
  } catch (error) {
    console.error("Error fetching leave request counts:", error);
    res.status(500).json({ message: "Internal server error" });
  }
}



// Approve a leave request
// Approve a leave request
export async function approveLeaveRequest(req, res) {
  const { id } = req.params;
  const { actionBy, remarks } = req.body;

  try {
    // 1. Get the leave application with employee id
    const [leave] = await sql`
      SELECT lr.user_id, lr.leave_type, lr.number_of_days, el.id AS employee_id
      FROM leave_applications lr
      JOIN employee_list el ON lr.user_id = el.user_id
      WHERE lr.id = ${id};
    `;

    if (!leave) {
      return res.status(404).json({ error: "Leave request not found" });
    }

    // 2. Map leave_type (full → short code)
    const leaveCode = leaveTypeMap[leave.leave_type];
    if (!leaveCode) {
      return res.status(400).json({ error: `Unsupported leave type: ${leave.leave_type}` });
    }

    // 3. Get entitlement for this employee id + leave type
    const [entitlement] = await sql`
      SELECT id, total_days, used_days, balance_days
      FROM leave_entitlements
      WHERE user_id = ${leave.employee_id}
        AND leave_type = ${leaveCode}
        AND year = EXTRACT(YEAR FROM CURRENT_DATE);
    `;

    if (!entitlement) {
      return res.status(400).json({ error: "Entitlement not found for this leave type" });
    }

    // 4. Check if balance is enough
    if (entitlement.balance_days < leave.number_of_days) {
      return res.status(400).json({ error: "Insufficient leave balance" });
    }

    // 5. Update leave application status
    const [updatedLeave] = await sql`
      UPDATE leave_applications
      SET status = 'Approved',
          approved_by = ${actionBy},
          remarks = ${remarks},
          updated_at = now()
      WHERE id = ${id}
      RETURNING *;
    `;

    // 6. Update entitlement
    const [updatedEntitlement] = await sql`
      UPDATE leave_entitlements
      SET used_days = used_days + ${leave.number_of_days},
          updated_at = now()
      WHERE id = ${entitlement.id}
      RETURNING *;
    `;

    // 7. Insert notification for the employee
    await sql`
      INSERT INTO notifications (user_id, message)
      VALUES (${leave.user_id}, ${`Your leave request (${leave.leave_type}) has been approved by ${actionBy}.`});
    `;

    res.status(200).json({
      ...updatedLeave,
      entitled: updatedEntitlement.total_days,
      used: updatedEntitlement.used_days,
      balance: updatedEntitlement.total_days - updatedEntitlement.used_days,
      notification: "Leave approved and notification sent"
    });

  } catch (error) {
    console.error("Error approving leave:", error);
    res.status(500).json({ error: "Failed to approve leave" });
  }
}



// Reject a leave request
// Reject a leave request
export async function rejectLeaveRequest(req, res) {
  const { id } = req.params;
  const actionBy = req.body.actionBy || "Admin";
  const remarks = req.body.remarks || null;

  if (!id) {
    return res.status(400).json({ error: "Leave request ID is required" });
  }

  try {
    const [updatedLeave] = await sql`
      UPDATE leave_applications
      SET status = 'Rejected',
          updated_at = NOW(),
          approved_by = ${actionBy},
          remarks = ${remarks}
      WHERE id = ${id}
      RETURNING *;
    `;

    if (!updatedLeave) {
      return res.status(404).json({ error: "Leave request not found" });
    }

    // ✅ Insert notification for rejected leave
    await sql`
      INSERT INTO notifications (user_id, message)
      VALUES (${updatedLeave.user_id}, ${`Your leave request (${updatedLeave.leave_type}) has been rejected by ${actionBy}. Remarks: ${remarks || "No remarks provided."}`});
    `;

    res.status(200).json({ 
      message: "Leave request rejected and notification sent", 
      data: updatedLeave 
    });
  } catch (error) {
    console.error("Error rejecting leave request:", error);
    res.status(500).json({ error: "Failed to reject leave request" });
  }
}

// 📌 Get monthly leave requests (with optional leave type filter)
export async function getMonthlyLeaveCounts(req, res) {
  try {
    const { leaveType } = req.query; // from frontend dropdown
    let whereClause = sql``;

    if (leaveType) {
      const leaveCode = leaveTypeMap[leaveType];
      if (!leaveCode) {
        return res.status(400).json({ error: `Invalid leave type: ${leaveType}` });
      }
      whereClause = sql`AND lr.leave_type = ${leaveType}`;
    }

    const results = await sql`
      SELECT 
        TO_CHAR(lr.date_filing, 'Mon') AS month,
        EXTRACT(MONTH FROM lr.date_filing)::int AS month_number,
        COUNT(*)::int AS value
      FROM leave_applications lr
      WHERE EXTRACT(YEAR FROM lr.date_filing) = EXTRACT(YEAR FROM CURRENT_DATE)
      ${whereClause}
      GROUP BY month, month_number
      ORDER BY month_number;
    `;

    res.json(results);
  } catch (err) {
    console.error("❌ Error fetching monthly leave counts:", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
}


