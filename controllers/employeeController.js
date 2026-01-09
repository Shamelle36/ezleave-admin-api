// controllers/employeeController.js
import sql from "../config/db.js";
import { cloudinary } from "../config/cloudinary.js";

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
      employment_status,
      contract_start_date,
      contract_end_date
    } = req.body;

    console.log("📥 Received employee data:", {
      first_name, last_name, employment_status,
      contract_start_date, contract_end_date
    });

    // Convert empty id_number and email to null
    id_number = id_number?.trim() || null;
    email = email?.trim() || null;

    // Sanitize date_hired
    if (date_hired) {
      const parsedDate = new Date(date_hired);
      if (!isNaN(parsedDate)) {
        date_hired = parsedDate.toISOString().split('T')[0];
      } else {
        date_hired = new Date().toISOString().split('T')[0];
      }
    } else {
      date_hired = new Date().toISOString().split('T')[0];
    }

    // Sanitize contract_start_date
    if (contract_start_date && contract_start_date.trim() !== "") {
      const parsedStart = new Date(contract_start_date);
      if (!isNaN(parsedStart)) {
        contract_start_date = parsedStart.toISOString().split('T')[0];
      } else {
        contract_start_date = null;
      }
    } else {
      contract_start_date = null;
    }
    
    // Sanitize contract_end_date
    if (contract_end_date && contract_end_date.trim() !== "") {
      const parsedEnd = new Date(contract_end_date);
      if (!isNaN(parsedEnd)) {
        contract_end_date = parsedEnd.toISOString().split('T')[0];
      } else {
        contract_end_date = null;
      }
    } else {
      contract_end_date = null;
    }

    console.log("🧹 Sanitized dates:", {
      date_hired,
      contract_start_date,
      contract_end_date
    });

    // ✅ Declare eligibleStatuses - Include ALL statuses
    const eligibleStatuses = ["Temporary", "Permanent", "Contractual", "Casual", "Coterminous", "Job Order"];

    // INSERT employee
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
        employment_status,
        contract_start_date,
        contract_end_date,
        signature_url,
        signature_uploaded_at,
        cloudinary_public_id
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
        ${employment_status},
        ${contract_start_date},  
        ${contract_end_date},
        NULL,  -- signature_url initially null
        NULL,  -- signature_uploaded_at initially null
        NULL   -- cloudinary_public_id initially null
      )
      RETURNING *;
    `;

    console.log("✅ Employee inserted with ID:", employee.id, "Status:", employee.employment_status);

    // AFTER employee insert
    if (eligibleStatuses.includes(employment_status)) {
      const year = new Date().getFullYear();

      // Neutral leaves for everyone - INCLUDING VL and SL
      const neutralLeaves = [
        { type: "VL", days: 15 },
        { type: "SL", days: 15 },
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

      console.log("📝 Creating leave entitlements...");

      // Insert neutral leaves
      for (const leave of neutralLeaves) {
        try {
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
        } catch (leaveError) {
          console.error(`Error inserting ${leave.type}:`, leaveError);
        }
      }

      // Female-only leaves
      if (gender === "Female") {
        try {
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
        } catch (error) {
          console.error("Error inserting female leaves:", error);
        }
      }

      // Male-only leave
      if (gender === "Male" && civil_status === "Married") {
        try {
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
        } catch (error) {
          console.error("Error inserting paternity leave:", error);
        }
      }

      console.log("✅ Leave entitlements created successfully");
    } else {
      console.log("ℹ️ Employee status not eligible for leave entitlements:", employment_status);
    }

    console.log("🎉 Employee added successfully:", employee);
    res.status(201).json(employee);
  } catch (error) {
    console.error("❌ Error adding employee:", error);
    console.error("❌ Error details:", error.message);
    console.error("❌ Error stack:", error.stack);
    console.error("❌ Request body:", req.body);
    
    res.status(500).json({ 
      error: "Failed to add employee",
      details: error.message,
      employment_status: req.body.employment_status
    });
  }
};

// 📌 Get all employees (updated to include signature status)
export const getEmployees = async (req, res) => {
  try {
    const role = req.query.role || "admin";
    const department = req.query.department || "";

    let result;
    
    if (role === "admin" || role === "mayor") {
      // Both admin and mayor can see all employees
      result = await sql`
        SELECT 
          *,
          CASE 
            WHEN signature_url IS NOT NULL THEN true
            ELSE false
          END as has_signature
        FROM employee_list 
        ORDER BY id DESC;
      `;
    } else {
      // Office heads can only see their department employees
      result = await sql`
        SELECT 
          *,
          CASE 
            WHEN signature_url IS NOT NULL THEN true
            ELSE false
          END as has_signature
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

// 📌 Get all signatures for frontend mapping
export const getAllSignatures = async (req, res) => {
  try {
    const signatures = await sql`
      SELECT 
        id,
        signature_url,
        signature_uploaded_at
      FROM employee_list
      WHERE signature_url IS NOT NULL;
    `;

    // Convert to object format for frontend
    const signatureMap = {};
    signatures.forEach(sig => {
      signatureMap[sig.id] = sig.signature_url;
    });

    res.json(signatureMap);
  } catch (error) {
    console.error("Error fetching signatures:", error);
    res.status(500).json({ error: "Failed to fetch signatures" });
  }
};

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
        e.signature_url,
        e.signature_uploaded_at,
        e.cloudinary_public_id,
        e.created_at,
        e.updated_at,
        e.inactive_reason,
        CASE 
          WHEN e.signature_url IS NOT NULL THEN true
          ELSE false
        END as has_signature
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

// 📌 Get employee signature
export const getEmployeeSignature = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await sql`
      SELECT 
        id,
        first_name,
        last_name,
        signature_url,
        signature_uploaded_at,
        cloudinary_public_id
      FROM employee_list
      WHERE id = ${id};
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    const employee = result[0];
    
    if (!employee.signature_url) {
      return res.status(404).json({ error: "No signature found for this employee" });
    }

    res.json({
      success: true,
      signature_url: employee.signature_url,
      uploaded_at: employee.signature_uploaded_at,
      public_id: employee.cloudinary_public_id,
      employee_name: `${employee.first_name} ${employee.last_name}`
    });
  } catch (error) {
    console.error("Error fetching signature:", error);
    res.status(500).json({ error: "Failed to fetch signature" });
  }
};

// 📌 Upload employee signature to Cloudinary
export const uploadEmployeeSignature = async (req, res) => {
  const { id } = req.params;
  
  try {
    // Check if employee exists
    const employeeCheck = await sql`
      SELECT id, first_name, last_name, cloudinary_public_id 
      FROM employee_list 
      WHERE id = ${id};
    `;
    
    if (employeeCheck.length === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    if (!req.file) {
      return res.status(400).json({ error: "No signature file uploaded" });
    }

    const employee = employeeCheck[0];
    const oldPublicId = employee.cloudinary_public_id;

    // If employee already has a signature, delete the old one from Cloudinary
    if (oldPublicId) {
      try {
        await cloudinary.uploader.destroy(oldPublicId);
        console.log(`Deleted old signature: ${oldPublicId}`);
      } catch (deleteError) {
        console.warn("Could not delete old signature from Cloudinary:", deleteError);
      }
    }

    // Upload to Cloudinary
    const result = await cloudinary.uploader.upload(req.file.path, {
      folder: "employee-signatures",
      public_id: `signature_${id}_${Date.now()}`,
      overwrite: true,
      resource_type: "image",
      transformation: [
        { width: 500, height: 200, crop: "limit" } // Resize for consistency
      ]
    });

    console.log("Cloudinary upload result:", {
      public_id: result.public_id,
      secure_url: result.secure_url
    });

    // Update employee record with Cloudinary URL
    const updatedEmployee = await sql`
      UPDATE employee_list
      SET 
        signature_url = ${result.secure_url},
        signature_uploaded_at = NOW(),
        cloudinary_public_id = ${result.public_id}
      WHERE id = ${id}
      RETURNING *;
    `;

    res.status(200).json({
      success: true,
      message: "Signature uploaded successfully",
      signature_url: result.secure_url,
      public_id: result.public_id,
      employee: {
        id: updatedEmployee[0].id,
        name: `${employee.first_name} ${employee.last_name}`,
        signature_uploaded_at: updatedEmployee[0].signature_uploaded_at
      }
    });

  } catch (error) {
    console.error("Error uploading signature:", error);
    res.status(500).json({ 
      success: false,
      error: "Failed to upload signature",
      details: error.message 
    });
  }
};

// 📌 Delete employee signature from Cloudinary
export const deleteEmployeeSignature = async (req, res) => {
  const { id } = req.params;
  
  try {
    // Check if employee exists and has a signature
    const employee = await sql`
      SELECT signature_url, cloudinary_public_id 
      FROM employee_list 
      WHERE id = ${id};
    `;
    
    if (employee.length === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    if (!employee[0].signature_url) {
      return res.status(404).json({ error: "No signature found for this employee" });
    }

    const publicId = employee[0].cloudinary_public_id;

    // Delete from Cloudinary if public_id exists
    if (publicId) {
      try {
        await cloudinary.uploader.destroy(publicId);
        console.log(`Deleted signature from Cloudinary: ${publicId}`);
      } catch (cloudinaryError) {
        console.warn("Could not delete from Cloudinary:", cloudinaryError);
      }
    }

    // Update employee record
    await sql`
      UPDATE employee_list
      SET 
        signature_url = NULL,
        signature_uploaded_at = NULL,
        cloudinary_public_id = NULL
      WHERE id = ${id}
      RETURNING *;
    `;

    res.status(200).json({
      success: true,
      message: "Signature deleted successfully"
    });

  } catch (error) {
    console.error("Error deleting signature:", error);
    res.status(500).json({ 
      success: false,
      error: "Failed to delete signature",
      details: error.message 
    });
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
    inactive_reason,
    contract_start_date,
    contract_end_date
  } = req.body;

  try {
    // Sanitize contract dates if they exist
    let sanitizedStartDate = null;
    let sanitizedEndDate = null;
    
    if (contract_start_date) {
      const parsedStart = new Date(contract_start_date);
      sanitizedStartDate = !isNaN(parsedStart) ? parsedStart.toISOString().split('T')[0] : null;
    }
    
    if (contract_end_date) {
      const parsedEnd = new Date(contract_end_date);
      sanitizedEndDate = !isNaN(parsedEnd) ? parsedEnd.toISOString().split('T')[0] : null;
    }

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
        contract_start_date = ${sanitizedStartDate},  
        contract_end_date = ${sanitizedEndDate}, 
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

// 📌 Delete employee (with Cloudinary cleanup)
export const deleteEmployee = async (req, res) => {
  const { id } = req.params;
  try {
    // First, delete signature from Cloudinary if exists
    const employee = await sql`
      SELECT cloudinary_public_id FROM employee_list WHERE id = ${id};
    `;
    
    if (employee.length > 0 && employee[0].cloudinary_public_id) {
      const publicId = employee[0].cloudinary_public_id;
      try {
        await cloudinary.uploader.destroy(publicId);
        console.log(`Deleted signature from Cloudinary for employee ${id}: ${publicId}`);
      } catch (cloudinaryError) {
        console.warn("Could not delete signature from Cloudinary:", cloudinaryError);
      }
    }

    // Delete from database
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

// 📌 Add new leave type to all employees
// 📌 Add new leave type to all employees who already have leave entitlements
export const addLeaveTypeToAllEmployees = async (req, res) => {
  try {
    const { leaveType, days, description } = req.body;
    const year = new Date().getFullYear();

    if (!leaveType || days === undefined) {
      return res.status(400).json({ 
        error: "Leave type and days are required" 
      });
    }

    console.log(`📝 Adding new leave type "${leaveType}" to employees with existing leave entitlements...`);

    // Get DISTINCT employees who already have leave entitlements
    const employees = await sql`
      SELECT DISTINCT user_id as id 
      FROM leave_entitlements 
      WHERE year = ${year}
      ORDER BY user_id
    `;

    console.log(`✅ Found ${employees.length} employees with existing leave entitlements`);

    // If no employees found, you might want to get employees from employee_list
    // who should have leave entitlements based on their status
    if (employees.length === 0) {
      console.log("⚠️ No employees found with existing leave entitlements. Checking eligible employees...");
      
      // Option 1: Get employees from employee_list based on employment status
      const eligibleStatuses = ["Temporary", "Permanent", "Contractual", "Casual", "Coterminous"];
      
      const eligibleEmployees = await sql`
        SELECT id FROM employee_list 
        WHERE employment_status = ANY(${eligibleStatuses})
      `;
      
      console.log(`✅ Found ${eligibleEmployees.length} eligible employees from employee_list`);
      employees = eligibleEmployees;
    }

    let addedCount = 0;
    let updatedCount = 0;
    let skippedCount = 0;
    let errors = [];

    // Add leave type to each employee
    for (const employee of employees) {
      try {
        const result = await sql`
          INSERT INTO leave_entitlements (
            user_id,
            leave_type,
            year,
            total_days,
            used_days,
            description,
            created_at,
            updated_at
          ) VALUES (
            ${employee.id},
            ${leaveType},
            ${year},
            ${days},
            0,
            ${description || null},
            NOW(),
            NOW()
          )
          ON CONFLICT (user_id, leave_type, year) 
          DO UPDATE SET 
            total_days = ${days},
            description = ${description || null},
            updated_at = NOW()
          RETURNING id
        `;
        
        if (result && result.length > 0) {
          if (result[0].id) {
            addedCount++;
          } else {
            updatedCount++;
          }
        }
        
      } catch (error) {
        console.error(`Error adding leave type for employee ${employee.id}:`, error);
        skippedCount++;
        errors.push({ 
          employeeId: employee.id, 
          error: error.message 
        });
      }
    }

    console.log(`✅ Leave type "${leaveType}" added to ${addedCount} employees, updated for ${updatedCount}, skipped ${skippedCount}`);

    res.status(200).json({
      success: true,
      message: `Leave type "${leaveType}" added to ${addedCount} employees`,
      stats: {
        added: addedCount,
        updated: updatedCount,
        skipped: skippedCount,
        total: employees.length
      },
      errors: errors.length > 0 ? errors : undefined
    });

  } catch (error) {
    console.error("❌ Error adding leave type to all employees:", error);
    res.status(500).json({ 
      error: "Failed to add leave type to all employees",
      details: error.message 
    });
  }
};