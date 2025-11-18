import sql from "../config/db.js";

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
        lr.approver_name,
        lr.approver_date,
        lr.office_head_status,
        lr.office_head_date,
        lr.hr_status,
        lr.hr_date,
        lr.mayor_status,
        lr.mayor_date,
        lr.first_name,
        lr.middle_name,
        lr.last_name
      FROM leave_applications lr
      JOIN employee_list el ON lr.user_id = el.user_id
      ORDER BY lr.id DESC;
    `;

    const enriched = await Promise.all(
      leaveRequests.map(async (lr) => {
        const leaveCode = leaveTypeMap[lr.leave_type];
        if (!leaveCode) return { ...lr, entitled: 0, used: 0, balance: 0 };

        const [employee] = await sql`
          SELECT id
          FROM employee_list
          WHERE user_id = ${lr.user_id}
        `;
        if (!employee) return { ...lr, entitled: 0, used: 0, balance: 0 };

        const leaveCards = await sql`
          SELECT *
          FROM leave_cards
          WHERE employee_id = ${employee.id}
          ORDER BY id ASC;
        `;

        if (!leaveCards || leaveCards.length === 0)
          return { ...lr, entitled: 0, used: 0, balance: 0 };

        let entitled = 0;
        let balance = 0;
        let used = 0;

        // Debug log full card list for this employee
        console.log(`\n🔍 Employee ID: ${employee.id}`);
        console.table(leaveCards.map(c => ({
          period: c.period,
          vl_earned: c.vl_earned,
          vl_used: c.vl_used,
          vl_balance: c.vl_balance,
          sl_earned: c.sl_earned,
          sl_used: c.sl_used,
          sl_balance: c.sl_balance
        })));

        if (leaveCode === "VL") {
          const validEarned = leaveCards.filter(c => /^\d/.test(c.period));
          const latestEarned = validEarned[validEarned.length - 1];
          const lastVL = leaveCards.filter(c => c.vl_balance != null && c.vl_balance !== "").pop();

          entitled = latestEarned ? parseFloat(latestEarned.vl_balance) || 0 : 0;
          balance = lastVL ? parseFloat(lastVL.vl_balance) || 0 : 0;
          used = +(entitled - balance).toFixed(3);

          console.log(`🟢 VL → Entitled: ${entitled}, Balance: ${balance}, Used: ${used}`);
        } else if (leaveCode === "SL") {
          const validEarned = leaveCards.filter(c => /^\d/.test(c.period));
          const latestEarned = validEarned[validEarned.length - 1];
          const lastSL = leaveCards.filter(c => c.sl_balance != null && c.sl_balance !== "").pop();

          entitled = latestEarned ? parseFloat(latestEarned.sl_balance) || 0 : 0;
          balance = lastSL ? parseFloat(lastSL.sl_balance) || 0 : 0;
          used = +(entitled - balance).toFixed(3);

          console.log(`🟣 SL → Entitled: ${entitled}, Balance: ${balance}, Used: ${used}`);
        }

        return { ...lr, entitled, used, balance };
      })
    );

    res.json(enriched);
  } catch (err) {
    console.error("❌ Error fetching leave requests:", err);
    res.status(500).json({ error: "Failed to fetch leave requests" });
  }
}




// APPROVE LEAVE REQUEST
// APPROVE LEAVE REQUEST
export async function approveLeaveRequest(req, res) {
  const { id } = req.params;
  const { actionBy, remarks, role } = req.body; 
  // role = "office_head" | "hr" | "mayor"

  try {
    // 1️⃣ Get approver info
    let approverTable = role === "admin" ? "useradmin" : "admin_accounts";

    const [approver] = await sql`
      SELECT full_name
      FROM ${sql(approverTable)}
      WHERE email = ${actionBy} OR id::text = ${actionBy}
      LIMIT 1;
    `;

    if (!approver) return res.status(404).json({ error: "Approver not found" });
    const approverName = approver.full_name;

    // 2️⃣ Get leave request and employee
    const [leave] = await sql`
      SELECT lr.*, el.id AS employee_id
      FROM leave_applications lr
      JOIN employee_list el ON lr.user_id = el.user_id
      WHERE lr.id = ${id};
    `;
    if (!leave) return res.status(404).json({ error: "Leave request not found" });

    // 3️⃣ Handle based on role
    if (role === "office_head") {
      await sql`
        UPDATE leave_applications
        SET office_head_status = 'Approved',
            office_head_id = ${actionBy},
            office_head_date = NOW(),
            remarks = ${remarks ?? null},
            updated_at = NOW()
        WHERE id = ${id};
      `;
    } 
    else if (role === "admin") {
      await sql`
        UPDATE leave_applications
        SET hr_status = 'Approved',
            hr_id = ${actionBy},
            hr_date = NOW(),
            remarks = ${remarks ?? null},
            updated_at = NOW()
        WHERE id = ${id};
      `;
    } 
    else if (role === "mayor") {
      // Final approval (Mayor) — calculate leave balance
      const leaveCode = leaveTypeMap[leave.leave_type];
      if (!leaveCode) return res.status(400).json({ error: `Unsupported leave type: ${leave.leave_type}` });

      const [latestCard] = await sql`
        SELECT *
        FROM leave_cards
        WHERE employee_id = ${leave.employee_id}
        ORDER BY id DESC
        LIMIT 1;
      `;
      if (!latestCard) return res.status(400).json({ error: "Leave card not found" });

      // Determine leave fields
      let usedField = "", balanceField = "", earnedField = "";
      switch (leaveCode) {
        case "VL":
          usedField = "vl_used";
          balanceField = "vl_balance";
          earnedField = "vl_earned";
          break;
        case "SL":
          usedField = "sl_used";
          balanceField = "sl_balance";
          earnedField = "sl_earned";
          break;
        default:
          return res.status(400).json({ error: "Unsupported leave type for leave card" });
      }

      const leaveUsed = parseFloat(leave.number_of_days);
      const prevBalance = parseFloat(latestCard[balanceField]) || 0;
      const newBalance = prevBalance - leaveUsed;
      if (newBalance < 0) return res.status(400).json({ error: "Insufficient leave balance" });

      // Prepare readable remarks
      function getDatesFromRange(rangeStr) {
        if (!rangeStr) return [];
        const match = rangeStr.match(/\[(.*),(.*)\)/);
        if (!match) return [];
        const start = new Date(match[1]);
        const end = new Date(match[2]);
        const dates = [];
        for (let d = new Date(start); d < end; d.setDate(d.getDate() + 1)) {
          dates.push(new Date(d));
        }
        return dates;
      }
      function formatRemarks(dates) {
        if (!dates.length) return null;
        const dateStrings = dates.map(d => `${d.toLocaleString('default', { month: 'long' })} ${d.getDate()}`);
        const year = dates[0].getFullYear();
        if (dateStrings.length === 1) return `${dateStrings[0]}, ${year}`;
        if (dateStrings.length === 2) return `${dateStrings[0]} & ${dateStrings[1]}, ${year}`;
        return `${dateStrings.slice(0, -1).join(", ")} & ${dateStrings.slice(-1)}, ${year}`;
      }

      const dates = getDatesFromRange(leave.inclusive_dates);
      const leaveCardRemarks = formatRemarks(dates);

      // 🟩 Compute all fields
      const vl_earned = null;  // ✅ Always null during leave approval (no earning)
      const sl_earned = null;  // ✅ Always null during leave approval (no earning)

      // For used/balance: only update the type that matches the leaveCode
      const vl_used = leaveCode === "VL" ? leaveUsed : latestCard.vl_used;
      const vl_balance = leaveCode === "VL" ? newBalance : latestCard.vl_balance;

      const sl_used = leaveCode === "SL" ? leaveUsed : latestCard.sl_used;
      const sl_balance = leaveCode === "SL" ? newBalance : latestCard.sl_balance;

      // 🟦 Insert new leave card row
      await sql`
        INSERT INTO leave_cards (
          employee_id,
          vl_earned, vl_used, vl_balance,
          sl_earned, sl_used, sl_balance,
          period,
          remarks
        )
        VALUES (
          ${leave.employee_id},
          ${vl_earned}, ${vl_used}, ${vl_balance},
          ${sl_earned}, ${sl_used}, ${sl_balance},
          ${`(${leaveUsed.toFixed(3)}) ${leaveCode}`},
          ${leaveCardRemarks}
        );
      `;


      // Update final status
      await sql`
        UPDATE leave_applications
        SET mayor_status = 'Approved',
            mayor_id = ${actionBy},
            mayor_date = NOW(),
            status = 'Approved',
            approver_name = ${approverName},
            approver_date = CURRENT_DATE,
            remarks = ${remarks ?? null},
            updated_at = NOW()
        WHERE id = ${id};
      `;
    } else {
      return res.status(400).json({ error: "Invalid role for approval" });
    }

    // 🔔 Notification for employee
    await sql`
      INSERT INTO notifications (user_id, message)
      VALUES (
        ${leave.user_id},
        ${`Your leave request (${leave.leave_type}) has been approved by ${approverName} (${role.replace('_', ' ')}).`}
      );
    `;

    res.status(200).json({
      message: `${role} approval by ${approverName} successful`,
      approver_name: approverName
    });

  } catch (error) {
    console.error("❌ Error approving leave:", error);
    res.status(500).json({ error: "Failed to approve leave" });
  }
}

// REJECT LEAVE REQUEST
export async function rejectLeaveRequest(req, res) {
  const { id } = req.params;
  const { actionBy, remarks, role } = req.body; 
  // role = "office_head" | "hr" | "mayor"

  if (!id) return res.status(400).json({ error: "Leave request ID is required" });
  if (!role) return res.status(400).json({ error: "Approver role is required" });

  try {
    // 1️⃣ Determine approver table based on role
    const approverTable = role === "admin" ? "useradmin" : "admin_accounts";

    // 2️⃣ Find approver name
    const [approver] = await sql`
      SELECT full_name
      FROM ${sql(approverTable)}
      WHERE email = ${actionBy} OR id::text = ${actionBy}
      LIMIT 1;
    `;
    if (!approver) return res.status(404).json({ error: "Approver not found" });
    const approverName = approver.full_name;

    // 3️⃣ Get leave request
    const [leave] = await sql`
      SELECT *
      FROM leave_applications
      WHERE id = ${id};
    `;
    if (!leave) return res.status(404).json({ error: "Leave request not found" });

    // 4️⃣ Apply rejection logic by role
    if (role === "office_head") {
      await sql`
        UPDATE leave_applications
        SET office_head_status = 'Rejected',
            office_head_id = ${actionBy},
            office_head_date = NOW(),
            status = 'Rejected',  -- <-- add this
            approver_name = ${approverName}, -- optional
            approver_date = CURRENT_DATE,   -- optional
            remarks = ${remarks ?? null},
            updated_at = NOW()
        WHERE id = ${id};
      `;
    } 
    else if (role === "admin") {
      await sql`
        UPDATE leave_applications
        SET hr_status = 'Rejected',
            hr_id = ${actionBy},
            hr_date = NOW(),
            status = 'Rejected',  -- <-- add this
            approver_name = ${approverName}, -- optional
            approver_date = CURRENT_DATE,   -- optional
            remarks = ${remarks ?? null},
            updated_at = NOW()
        WHERE id = ${id};
      `;
    } 
    else if (role === "mayor") {
      // Mayor rejection = Final rejection
      await sql`
        UPDATE leave_applications
        SET mayor_status = 'Rejected',
            mayor_id = ${actionBy},
            mayor_date = NOW(),
            status = 'Rejected',
            approver_name = ${approverName},
            approver_date = CURRENT_DATE,
            remarks = ${remarks ?? null},
            updated_at = NOW()
        WHERE id = ${id};
      `;
    } 
    else {
      return res.status(400).json({ error: "Invalid role for rejection" });
    }

    // 5️⃣ Notify employee
    await sql`
      INSERT INTO notifications (user_id, message)
      VALUES (
        ${leave.user_id},
        ${`Your leave request (${leave.leave_type}) has been rejected by ${approverName} (${role.replace("_", " ")}). Remarks: ${remarks || "No remarks provided."}` }
      );
    `;

    // 6️⃣ Respond success
    res.status(200).json({
      message: `${role} rejection by ${approverName} successful`,
      approver_name: approverName
    });

  } catch (error) {
    console.error("❌ Error rejecting leave request:", error);
    res.status(500).json({ error: "Failed to reject leave request" });
  }
}



// GET MONTHLY LEAVE COUNTS
export async function getMonthlyLeaveCounts(req, res) {
  try {
    const { leaveType } = req.query;
    let whereClause = sql``;

    if (leaveType) {
      const leaveCode = leaveTypeMap[leaveType];
      if (!leaveCode) return res.status(400).json({ error: `Invalid leave type: ${leaveType}` });
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

// GET LEAVE REQUESTS COUNT
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
    res.status(500).json({ error: "Failed to fetch leave request counts" });
  }
}
