import sql from "../config/db.js";
import { sendPushToUser } from "../utils/fcm.js";
import { sendAndSaveNotification } from "../utils/notificationService.js";

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

// Define major holidays (Christmas season)
const MAJOR_HOLIDAYS = [
  '12-24', // Christmas Eve
  '12-25', // Christmas Day
  '12-30', // Rizal Day
  '12-31', // New Year's Eve
  '01-01', // New Year's Day
];

// Function to get total employee count
async function getTotalEmployeeCount() {
  try {
    const [result] = await sql`
      SELECT COUNT(*) as total_employees
      FROM employee_list
      WHERE status = 'Active'
    `;
    return parseInt(result?.total_employees || 100);
  } catch (error) {
    console.error("Error getting total employee count:", error);
    return 100;
  }
}

// Add this function
export async function testOverlapCheck(req, res) {
  try {
    // Test with hardcoded data
    const testData = {
      id: 1,
      user_id: "user_34oTu5GqoNrNVwxp76cVuw5EeKB",
      inclusive_dates: "[2025-12-15,2025-12-17)"  // Test dates
    };
    
    console.log("🧪 TEST: Calling overlap check with:", testData);
    const result = await checkOverlappingLeavesForOfficeHead(testData);
    
    res.json({
      message: "Test complete",
      test_data: testData,
      result: result
    });
    
  } catch (error) {
    console.error("Test error:", error);
    res.status(500).json({ error: error.message });
  }
}

export async function checkOverlappingLeavesForOfficeHead(reqOrLeaveRequest, res) {
  try {
    // Determine if called as route handler (has res) or standalone function
    const isRouteHandler = res !== undefined;
    const leaveRequest = isRouteHandler ? reqOrLeaveRequest.body : reqOrLeaveRequest;
    
    console.log("🔍 Starting overlap check for leave request:", leaveRequest?.id);
    
    if (!leaveRequest) {
      const errorMsg = "No leave request data provided";
      if (isRouteHandler) {
        return res.status(400).json({ error: errorMsg, hasOverlap: false, violations: [] });
      }
      return { hasOverlap: false, violations: [], error: errorMsg };
    }

    // Parse inclusive dates
    let raw = leaveRequest.inclusive_dates;
    
    if (!raw) {
      console.log("❌ inclusive_dates is undefined");
      const result = { hasOverlap: false, violations: [] };
      if (isRouteHandler) return res.json(result);
      return result;
    }

    // Extract dates from range format [start,end)
    const dateMatch = raw.match(/\[(.*?),(.*?)[\])]/);
    if (!dateMatch) {
      console.log("❌ No date match found for:", raw);
      const result = { hasOverlap: false, violations: [] };
      if (isRouteHandler) return res.json(result);
      return result;
    }

    const startDate = new Date(dateMatch[1]);
    const endDate = new Date(dateMatch[2]);
    
    console.log("📅 Parsed dates:", { 
      start: startDate.toISOString().split('T')[0], 
      end: endDate.toISOString().split('T')[0] 
    });

    // Get employee's department
    const [employee] = await sql`
      SELECT department, position
      FROM employee_list
      WHERE user_id = ${leaveRequest.user_id}
      AND status = 'Active'
      LIMIT 1
    `;

    if (!employee) {
      console.log("❌ Employee not found:", leaveRequest.user_id);
      const result = { hasOverlap: false, violations: [] };
      if (isRouteHandler) return res.json(result);
      return result;
    }

    console.log("👤 Employee department:", employee.department);
    
    // Get department size
    const [deptSizeResult] = await sql`
      SELECT COUNT(*) as dept_size
      FROM employee_list
      WHERE department = ${employee.department}
      AND status = 'Active'
    `;
    
    const deptSize = parseInt(deptSizeResult?.dept_size || 1);
    
    // Check each date in the leave period
    const violations = [];
    const currentDate = new Date(startDate);
    
    while (currentDate < endDate) {
      const dateStr = currentDate.toISOString().split('T')[0];
      const monthDay = `${String(currentDate.getMonth() + 1).padStart(2, '0')}-${String(currentDate.getDate()).padStart(2, '0')}`;
      const isMajorHoliday = MAJOR_HOLIDAYS.includes(monthDay);
      
      console.log(`📊 Checking date: ${dateStr} (${isMajorHoliday ? 'Holiday' : 'Regular'})`);
      
      // FIXED: Get count of approved leaves for this specific date and department
      const [leaveCountResult] = await sql`
        SELECT COUNT(DISTINCT la.user_id) as count_on_leave
        FROM leave_applications la
        JOIN employee_list el ON la.user_id = el.user_id
        WHERE la.status = 'Approved'
          AND la.id != ${leaveRequest.id || 0}
          AND el.department = ${employee.department}
          AND ${dateStr}::date >= LOWER(la.inclusive_dates)
          AND ${dateStr}::date < UPPER(la.inclusive_dates)
          AND el.status = 'Active'
      `;
      
      const countOnLeave = parseInt(leaveCountResult?.count_on_leave || 0);
      
      console.log(`   Employees on leave in ${employee.department}: ${countOnLeave}`);
      
      // Determine max allowed based on day type
      let maxAllowed;
      if (isMajorHoliday) {
        // For holidays: maximum 50% of department
        maxAllowed = Math.floor(deptSize / 2);
        console.log(`   ⭐ Holiday (${monthDay}): Max allowed = ${maxAllowed} (half of ${deptSize})`);
      } else {
        // For regular days: maximum 3 employees
        maxAllowed = 3;
        console.log(`   📅 Regular day: Max allowed = ${maxAllowed}`);
      }
      
      // Check if approving would exceed limit
      // Note: We check if countOnLeave >= maxAllowed, because after approval it would be countOnLeave + 1
      if (countOnLeave >= maxAllowed) {
        console.log(`   ⚠️ VIOLATION: ${countOnLeave} >= ${maxAllowed}`);
        violations.push({
          date: dateStr,
          is_holiday: isMajorHoliday,
          current_on_leave: countOnLeave,
          max_allowed: maxAllowed,
          department: employee.department,
          would_exceed: true
        });
      }
      
      currentDate.setDate(currentDate.getDate() + 1);
    }
    
    console.log(`✅ Overlap check complete. Violations: ${violations.length}`);
    
    const result = {
      hasOverlap: violations.length > 0,
      violations: violations,
      canProceed: violations.length === 0
    };
    
    if (isRouteHandler) {
      return res.json(result);
    }
    return result;
    
  } catch (error) {
    console.error("❌ Error checking overlapping leaves:", error);
    const errorResult = { 
      hasOverlap: false, 
      violations: [], 
      error: error.message 
    };
    
    if (res !== undefined) {
      return res.status(500).json(errorResult);
    }
    return errorResult;
  }
}

// Existing getLeaveRequests function remains the same...
export async function getLeaveRequests(req, res) {
  try {
    // 1️⃣ FETCH ALL LEAVE REQUESTS
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
        lr.inclusive_dates,
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
        lr.last_name,
        lr.cs_form_generated
      FROM leave_applications lr
      JOIN employee_list el ON lr.user_id = el.user_id
      ORDER BY lr.id DESC;
    `;

    // 2️⃣ FETCH ONLY "Filed Leave" Notifications
    const filedNotifications = await sql`
      SELECT *
      FROM notifications
      WHERE message LIKE '%filed a % leave%'
      ORDER BY created_at DESC;
    `;

    // 3️⃣ ADD LEAVE BALANCES + MATCH NOTIFICATIONS
    const enriched = await Promise.all(
      leaveRequests.map(async (lr) => {
        const leaveCode = leaveTypeMap[lr.leave_type];

        // Attach the notification for this employee
        const notification = filedNotifications.find(
          (n) => n.user_id === lr.user_id
        );

        if (!leaveCode) {
          return { 
            ...lr, 
            entitled: 0, 
            used: 0, 
            balance: 0, 
            notification 
          };
        }

        const [employee] = await sql`
          SELECT id
          FROM employee_list
          WHERE user_id = ${lr.user_id}
        `;
        if (!employee) {
          return { 
            ...lr, 
            entitled: 0, 
            used: 0, 
            balance: 0, 
            notification 
          };
        }

        const leaveCards = await sql`
          SELECT *
          FROM leave_cards
          WHERE employee_id = ${employee.id}
          ORDER BY id ASC;
        `;

        if (!leaveCards || leaveCards.length === 0) {
          return { 
            ...lr, 
            entitled: 0, 
            used: 0, 
            balance: 0, 
            notification 
          };
        }

        let entitled = 0;
        let balance = 0;
        let used = 0;

        // Debug log full card list for this employee
        console.log(`\n🔍 Employee ID: ${employee.id}`);
        console.table(
          leaveCards.map((c) => ({
            period: c.period,
            vl_earned: c.vl_earned,
            vl_used: c.vl_used,
            vl_balance: c.vl_balance,
            sl_earned: c.sl_earned,
            sl_used: c.sl_used,
            sl_balance: c.sl_balance,
          }))
        );

        if (leaveCode === "VL") {
          const validEarned = leaveCards.filter((c) => /^\d/.test(c.period));
          const latestEarned = validEarned[validEarned.length - 1];
          const lastVL = leaveCards
            .filter((c) => c.vl_balance != null && c.vl_balance !== "")
            .pop();

          entitled = latestEarned
            ? parseFloat(latestEarned.vl_balance) || 0
            : 0;
          balance = lastVL ? parseFloat(lastVL.vl_balance) || 0 : 0;
          used = +(entitled - balance).toFixed(3);
        }

        if (leaveCode === "SL") {
          const validEarned = leaveCards.filter((c) => /^\d/.test(c.period));
          const latestEarned = validEarned[validEarned.length - 1];
          const lastSL = leaveCards
            .filter((c) => c.sl_balance != null && c.sl_balance !== "")
            .pop();

          entitled = latestEarned
            ? parseFloat(latestEarned.sl_balance) || 0
            : 0;
          balance = lastSL ? parseFloat(lastSL.sl_balance) || 0 : 0;
          used = +(entitled - balance).toFixed(3);
        }

        return {
          ...lr,
          entitled,
          used,
          balance,
          notification, // 👈 attached here
        };
      })
    );

    res.json(enriched);
  } catch (err) {
    console.error("❌ Error fetching leave requests:", err);
    res.status(500).json({ error: "Failed to fetch leave requests" });
  }
}

// UPDATED APPROVE LEAVE REQUEST with overlapping check for office_head
export async function approveLeaveRequest(req, res) {
  const { id } = req.params;
  const { actionBy, remarks, role, forceApprove = false } = req.body; 
  // role = "office_head" | "admin" | "mayor"
  // forceApprove = boolean to override business rules

  try {
    // 1️⃣ Get approver info
    const approverTable = role === "admin" ? "useradmin" : "admin_accounts";
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

    if (role === "office_head") {
      console.log("🔍 DEBUG: Checking leave data:", {
        id: leave.id,
        user_id: leave.user_id,
        has_inclusive_dates: !!leave.inclusive_dates,
        inclusive_dates: leave.inclusive_dates
      });

      // FIX: Directly use the leave object from the query
      const leaveForOverlapCheck = {
        id: leave.id,
        user_id: leave.user_id,
        inclusive_dates: leave.inclusive_dates  // Use the inclusive_dates from the leave query
      };
      
      console.log("📦 Sending to overlap check:", leaveForOverlapCheck);
      
      // Check for overlapping leaves before approving
      const overlapCheck = await checkOverlappingLeavesForOfficeHead(leaveForOverlapCheck);

      if (overlapCheck.hasOverlap && !forceApprove) {
        const holidayViolations = overlapCheck.violations.filter(v => v.is_holiday);
        const regularViolations = overlapCheck.violations.filter(v => !v.is_holiday);
        
        return res.status(400).json({
          error: "Overlapping leave conflict",
          violations: overlapCheck.violations,
          summary: {
            total_violations: overlapCheck.violations.length,
            holiday_violations: holidayViolations.length,
            regular_violations: regularViolations.length,
            requires_force_approve: true,
            message: `Cannot approve: Would exceed ${regularViolations.length > 0 ? '3-employee limit on regular days' : ''}${regularViolations.length > 0 && holidayViolations.length > 0 ? ' and ' : ''}${holidayViolations.length > 0 ? '50% department limit on holidays' : ''}`
          }
        });
      }

      // If forceApprove is true or no violations, proceed with approval
      await sql`
        UPDATE leave_applications
        SET office_head_status = 'Approved',
            office_head_id = ${actionBy},
            office_head_date = NOW(),
            remarks = ${remarks ?? null},
            updated_at = NOW()
        WHERE id = ${id};
      `;
      
      // Add note about overlapping if force approved
      if (overlapCheck.hasOverlap && forceApprove) {
        await sql`
          UPDATE leave_applications
          SET remarks = ${(remarks || '') + ' (Approved despite overlapping leaves - forced approval)'}
          WHERE id = ${id};
        `;
      }
      
      return res.status(200).json({ 
        message: `Office Head approval successful${overlapCheck.hasOverlap ? ' (with overlapping leaves warning)' : ''}`,
        has_overlaps: overlapCheck.hasOverlap,
        violations: overlapCheck.violations
      });
    } else if (role === "admin") {
      await sql`
        UPDATE leave_applications
        SET hr_status = 'Approved',
            hr_id = ${actionBy},
            hr_date = NOW(),
            remarks = ${remarks ?? null},
            updated_at = NOW()
        WHERE id = ${id};
      `;
      return res.status(200).json({ message: `HR/Admin approval successful` });
    }

     if (role === "mayor") {
      await sql`
        UPDATE leave_applications
        SET mayor_status = 'Approved',
            mayor_id = ${actionBy},
            mayor_date = NOW(),
            status = 'Approved',
            approver_name = ${approverName},
            approver_date = CURRENT_DATE,
            remarks = ${remarks ?? null},
            updated_at = NOW(),
            cs_form_generated = true
        WHERE id = ${id};
      `;
    }

    // 4️⃣ Mayor approval (final) - NO OVERLAPPING CHECK HERE
    const leaveCode = leaveTypeMap[leave.leave_type];
    if (!leaveCode) return res.status(400).json({ error: `Unsupported leave type: ${leave.leave_type}` });

    // Fetch latest leave card for balances
    const [latestCard] = await sql`
      SELECT *
      FROM leave_cards
      WHERE employee_id = ${leave.employee_id}
      ORDER BY id DESC
      LIMIT 1;
    `;
    const prevVL = latestCard?.vl_balance || 0;
    const prevSL = latestCard?.sl_balance || 0;

    // Prepare remarks from inclusive_dates
    const getDatesFromRange = (rangeStr) => {
      if (!rangeStr) return [];
      const match = rangeStr.match(/\[(.*),(.*)\)/);
      if (!match) return [];
      const start = new Date(match[1]);
      const end = new Date(match[2]);
      const dates = [];
      for (let d = new Date(start); d < end; d.setDate(d.getDate() + 1)) dates.push(new Date(d));
      return dates;
    };
    const formatRemarks = (dates) => {
      if (!dates.length) return null;
      const dateStrings = dates.map(d => `${d.toLocaleString('default', { month: 'long' })} ${d.getDate()}`);
      const year = dates[0].getFullYear();
      if (dateStrings.length === 1) return `${dateStrings[0]}, ${year}`;
      if (dateStrings.length === 2) return `${dateStrings[0]} & ${dateStrings[1]}, ${year}`;
      return `${dateStrings.slice(0, -1).join(", ")} & ${dateStrings.slice(-1)}, ${year}`;
    };
    const leaveCardRemarks = formatRemarks(getDatesFromRange(leave.inclusive_dates));

    const leaveUsed = parseFloat(leave.number_of_days);

    // 5️⃣ Insert leave_card row based on leave type
    if (leaveCode === "VL") {
      const newBalance = prevVL - leaveUsed;
      if (newBalance < 0) return res.status(400).json({ error: "Insufficient VL balance" });

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
          NULL, ${leaveUsed}, ${newBalance},
          NULL, NULL, ${prevSL},
          ${`(${leaveUsed.toFixed(3)}) ${leaveCode}`},
          ${leaveCardRemarks}
        );
      `;
    } else if (leaveCode === "SL") {
      const newBalance = prevSL - leaveUsed;
      if (newBalance < 0) return res.status(400).json({ error: "Insufficient SL balance" });

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
          NULL, NULL, ${prevVL},
          NULL, ${leaveUsed}, ${newBalance},
          ${`(${leaveUsed.toFixed(3)}) ${leaveCode}`},
          ${leaveCardRemarks}
        );
      `;
    } else {
        // Non-VL/SL leave (ML, SPL, MAT, etc.)
        const leaveCode = leaveTypeMap[leave.leave_type]; // "ML" for Mandatory/Forced Leave

        const [entitlement] = await sql`
          SELECT *
          FROM leave_entitlements
          WHERE user_id = ${leave.employee_id}   -- use employee_id
            AND leave_type = ${leaveCode}       -- use code (ML, VL, SL, etc.)
            AND year = EXTRACT(YEAR FROM CURRENT_DATE)
        `;

        if (!entitlement) 
          return res.status(400).json({ error: `No leave entitlement found for ${leave.leave_type}` });

        if (entitlement.balance_days < leaveUsed)
          return res.status(400).json({ error: `Insufficient ${leave.leave_type} balance` });

        // 2️⃣ Update used_days
        await sql`
          UPDATE leave_entitlements
          SET used_days = used_days + ${leaveUsed},
              updated_at = NOW()
          WHERE id = ${entitlement.id};
        `;

        // 3️⃣ Insert into leave_cards for record
        await sql`
          INSERT INTO leave_cards (
            employee_id,
            period,
            particulars,
            vl_earned, vl_used, vl_balance,
            sl_earned, sl_used, sl_balance,
            remarks
          )
          VALUES (
            ${leave.employee_id},
            ${`(${leaveUsed.toFixed(3)}) ${leaveCode}`},
            NULL,
            NULL, NULL, ${prevVL},
            NULL, NULL, ${prevSL},
            ${leaveCardRemarks}
          );
        `;
      }


    // 6️⃣ Update leave application final status
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


        // 7️⃣ Send push notification to employee
    try {
      const pushResult = await sendPushToUser(
        leave.user_id,
        "Leave Request Approved 🎉",
        `Your ${leave.leave_type} leave request has been approved by ${approverName}.`,
        {
          type: 'leave_approved',
          leave_id: id,
          leave_type: leave.leave_type,
          approver: approverName,
          action: 'approved',
          screen: 'leave_status'
        }
      );
      
      console.log("📱 Push notification result:", {
        success: pushResult.success,
        tokens_found: pushResult.tokens_found,
        valid_tokens: pushResult.valid_tokens
      });
      
      // Save notification to database regardless of push success
      await sql`
        INSERT INTO notifications (user_id, message)
        VALUES (${leave.user_id}, ${`Leave Approved: Your ${leave.leave_type} leave request has been approved by ${approverName}`})
      `;
      
    } catch (pushError) {
      console.error("❌ Error sending push notification:", pushError);
      // Still save to notifications table even if push fails
      await sql`
        INSERT INTO notifications (user_id, message)
        VALUES (${leave.user_id}, ${`Leave Approved: Your ${leave.leave_type} leave request has been approved by ${approverName}`})
      `;
    }


    res.status(200).json({ message: `Leave approved successfully`, approver_name: approverName });

  } catch (error) {
    console.error("❌ Error approving leave:", error);
    res.status(500).json({ error: "Failed to approve leave" });
  }
}

export async function rejectLeaveRequest(req, res) {
  const { id } = req.params;
  const { actionBy, remarks, role } = req.body;

  if (!id) return res.status(400).json({ error: "Leave request ID is required" });
  if (!role) return res.status(400).json({ error: "Approver role is required" });

  try {
    const approverTable = role === "admin" ? "useradmin" : "admin_accounts";

    const [approver] = await sql`
      SELECT full_name
      FROM ${sql(approverTable)}
      WHERE email = ${actionBy} OR id::text = ${actionBy}
      LIMIT 1;
    `;

    if (!approver) return res.status(404).json({ error: "Approver not found" });

    const approverName = approver.full_name;

    const [leave] = await sql`
      SELECT *
      FROM leave_applications
      WHERE id = ${id};
    `;

    if (!leave) return res.status(404).json({ error: "Leave request not found" });

    // APPLY REJECTION - FIXED LOGIC
    if (role === "office_head") {
      await sql`
        UPDATE leave_applications
        SET 
          office_head_status = 'Rejected',
          office_head_id = ${actionBy},
          office_head_date = NOW(),
          status = 'Rejected', 
          hr_status = 'Rejected',  
          mayor_status = 'Rejected', 
          approver_name = ${approverName},
          approver_date = CURRENT_DATE,
          remarks = ${remarks ?? null},
          updated_at = NOW(),
          cs_form_generated = true
        WHERE id = ${id};
      `;
    }
    else if (role === "admin") {
      await sql`
        UPDATE leave_applications
        SET 
          hr_status = 'Rejected',
          hr_id = ${actionBy},
          hr_date = NOW(),
          status = 'Rejected',  
          mayor_status = 'Rejected', 
          approver_name = ${approverName},
          approver_date = CURRENT_DATE,
          remarks = ${remarks ?? null},
          updated_at = NOW()
        WHERE id = ${id};
      `;
    }
    else if (role === "mayor") {
      await sql`
        UPDATE leave_applications
        SET 
          mayor_status = 'Rejected',
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

    // Send push notification to employee
    let pushResult = null;
    try {
      pushResult = await sendPushToUser(
        leave.user_id,
        "Leave Request Rejected ❗",
        `Your ${leave.leave_type} leave request was rejected by ${approverName}.`,
        {
          type: 'leave_rejected',
          leave_id: id,
          leave_type: leave.leave_type,
          approver: approverName,
          action: 'rejected',
          screen: 'leave_status'
        }
      );
      
      console.log("📱 Push notification result:", {
        success: pushResult?.success,
        tokens_found: pushResult?.tokens_found,
        valid_tokens: pushResult?.valid_tokens
      });
      
    } catch (pushError) {
      console.error("❌ Error sending push notification:", pushError);
      // Continue anyway - notification will be saved to database below
    }
    
    // Always save notification to database
    const notificationMessage = `Leave Rejected: Your ${leave.leave_type} leave request was rejected by ${approverName}`;
    
    await sql`
      INSERT INTO notifications (user_id, message)
      VALUES (${leave.user_id}, ${notificationMessage})
    `;
    
    console.log("✅ Notification saved to database");

    // ✅ ADD THIS RETURN STATEMENT - It was missing!
    return res.status(200).json({
      success: true,
      message: `${role} rejection by ${approverName} successful`,
      approver_name: approverName,
      notification_sent: pushResult?.success || false,
      leave_id: id,
      status: 'Rejected'
    });

  } catch (error) {
    console.error("❌ Error rejecting leave request:", error);
    res.status(500).json({ 
      success: false,
      error: "Failed to reject leave request",
      details: error.message 
    });
  }
}

// GET MONTHLY LEAVE COUNTS (unchanged)
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

// GET LEAVE REQUESTS COUNT (unchanged)
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

// GET WHO IS ON LEAVE FOR A SPECIFIC DAY (unchanged)
export async function getLeaveCalendarByDay(req, res) {
  try {
    const { date } = req.params;
    
    // Validate date format
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD' });
    }

    const leaveRequests = await sql`
      SELECT 
        la.id,
        la.user_id,
        CONCAT(la.first_name, ' ', la.last_name) as employee_name,
        la.office_department as department,
        la.position,
        la.leave_type,
        la.inclusive_dates,
        la.number_of_days,
        la.status,
        la.details,
        la.approver_name,
        la.remarks,
        el.profile_picture,
        el.id_number
      FROM leave_applications la
      LEFT JOIN employee_list el ON la.user_id = el.user_id
      WHERE 
        la.status = 'Approved'
        AND ${date}::date BETWEEN 
          LOWER(la.inclusive_dates) AND UPPER(la.inclusive_dates)
      ORDER BY la.office_department, la.first_name, la.last_name
    `;

    res.json({
      date: date,
      total_on_leave: leaveRequests.length,
      employees: leaveRequests
    });

  } catch (error) {
    console.error('❌ Error fetching leave calendar data:', error);
    res.status(500).json({ error: 'Failed to fetch leave calendar data' });
  }
}

export async function getLeaveCalendarByMonth(req, res) {
  try {
    const { year, month } = req.params;
    
    // Validate year and month
    if (!/^\d{4}$/.test(year) || !/^\d{1,2}$/.test(month)) {
      return res.status(400).json({ error: 'Invalid year or month format' });
    }

    const monthInt = parseInt(month);
    const yearInt = parseInt(year);
    
    if (monthInt < 1 || monthInt > 12) {
      return res.status(400).json({ error: 'Invalid month. Must be between 1-12' });
    }

    // Calculate date range for the month
    const startDate = new Date(yearInt, monthInt - 1, 1);
    const endDate = new Date(yearInt, monthInt, 0); // Last day of the month
    
    const startDateStr = startDate.toISOString().split('T')[0];
    const endDateStr = endDate.toISOString().split('T')[0];

    console.log(`📅 Fetching leave calendar for ${yearInt}-${monthInt}`);
    console.log(`📆 Date range: ${startDateStr} to ${endDateStr}`);

    // FIXED QUERY: Properly handle exclusive upper bound
    const leaveRequests = await sql`
      SELECT 
        la.id,
        la.user_id,
        CONCAT(la.first_name, ' ', la.last_name) as employee_name,
        la.office_department as department,
        la.position,
        la.leave_type,
        la.inclusive_dates,
        la.number_of_days,
        la.status,
        la.details,
        la.approver_name,
        la.remarks,
        el.profile_picture,
        el.id_number,
        LOWER(la.inclusive_dates) as leave_start,
        -- Subtract 1 day from upper bound to get the actual last day of leave
        (UPPER(la.inclusive_dates) - INTERVAL '1 day')::date as leave_end
      FROM leave_applications la
      LEFT JOIN employee_list el ON la.user_id = el.user_id
      WHERE 
        la.status = 'Approved'
        AND (
          -- Leave starts within the month
          (LOWER(la.inclusive_dates) >= ${startDateStr}::date AND LOWER(la.inclusive_dates) <= ${endDateStr}::date)
          -- Leave ends within the month (adjusting for exclusive upper bound)
          OR ((UPPER(la.inclusive_dates) - INTERVAL '1 day')::date >= ${startDateStr}::date AND (UPPER(la.inclusive_dates) - INTERVAL '1 day')::date <= ${endDateStr}::date)
          -- Leave spans the entire month
          OR (LOWER(la.inclusive_dates) <= ${startDateStr}::date AND (UPPER(la.inclusive_dates) - INTERVAL '1 day')::date >= ${endDateStr}::date)
        )
      ORDER BY la.office_department, la.first_name, la.last_name
    `;

    console.log(`✅ Found ${leaveRequests.length} leave requests for the month`);

    res.json({
      month: monthInt,
      year: yearInt,
      start_date: startDateStr,
      end_date: endDateStr,
      total_on_leave: leaveRequests.length,
      employees: leaveRequests
    });

  } catch (error) {
    console.error('❌ Error fetching monthly leave calendar data:', error);
    res.status(500).json({ error: 'Failed to fetch monthly leave calendar data' });
  }
}