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
    const eligibleStatuses = ["Temporary", "Permanent", "Contractual", "Casual", "Coterminous"];

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
        user_id,
        first_name,
        last_name,
        signature_url,
        signature_uploaded_at,
        cloudinary_public_id
      FROM employee_list
      WHERE user_id = ${id};
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
export const addLeaveType = async (req, res) => {
  try {
    const { name, abbreviation, days } = req.body;
    const year = new Date().getFullYear();

    if (!name || !abbreviation || days === undefined) {
      return res.status(400).json({ 
        success: false,
        error: "Leave name, abbreviation, and days are required" 
      });
    }

    console.log(`📝 Adding new leave type "${name}" (${abbreviation}) to employees...`);

    // First, check if leave type abbreviation already exists in leave_entitlements
    const existingType = await sql`
      SELECT DISTINCT leave_type FROM leave_entitlements 
      WHERE leave_type = ${abbreviation} 
      LIMIT 1;
    `;

    if (existingType.length > 0) {
      return res.status(400).json({
        success: false,
        error: `Leave type with abbreviation "${abbreviation}" already exists`
      });
    }

    // Get ALL eligible employees from employee_list
    const eligibleStatuses = ["Temporary", "Permanent", "Contractual", "Casual", "Coterminous", "Job Order"];
    
    const employees = await sql`
      SELECT id FROM employee_list 
      WHERE employment_status = ANY(${eligibleStatuses})
      ORDER BY id
    `;

    console.log(`✅ Found ${employees.length} eligible employees from employee_list`);

    let addedCount = 0;
    let skippedCount = 0;

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
            created_at,
            updated_at
          ) VALUES (
            ${employee.id},
            ${abbreviation},
            ${year},
            ${days},
            0,
            NOW(),
            NOW()
          )
          ON CONFLICT (user_id, leave_type, year) DO NOTHING
          RETURNING *;
        `;
        
        if (result.length > 0) {
          addedCount++;
        } else {
          skippedCount++;
        }
        
      } catch (error) {
        console.error(`Error adding leave type for employee ${employee.id}:`, error);
        skippedCount++;
      }
    }

    console.log(`✅ Leave type "${name}" (${abbreviation}) added to ${addedCount} employees, skipped ${skippedCount}`);

    res.status(200).json({
      success: true,
      message: `Leave type "${name}" added successfully`,
      data: {
        name: name,
        abbreviation: abbreviation,
        days: days
      },
      stats: {
        added: addedCount,
        skipped: skippedCount,
        total: employees.length
      }
    });

  } catch (error) {
    console.error("❌ Error adding leave type:", error);
    res.status(500).json({ 
      success: false,
      error: "Failed to add leave type",
      details: error.message 
    });
  }
};

// 📌 Update leave type (abbreviation and total_days)
export const updateLeaveType = async (req, res) => {
  try {
    const { oldAbbreviation } = req.params;
    const { newAbbreviation, name, days } = req.body;

    // Validate input
    if (!newAbbreviation || days === undefined) {
      return res.status(400).json({
        success: false,
        error: "New abbreviation and days are required"
      });
    }

    // Check if old leave type exists
    const existingType = await sql`
      SELECT DISTINCT leave_type FROM leave_entitlements 
      WHERE leave_type = ${oldAbbreviation} 
      LIMIT 1
    `;

    if (existingType.length === 0) {
      return res.status(404).json({
        success: false,
        error: `Leave type "${oldAbbreviation}" not found`
      });
    }

    // Check if new abbreviation is different from old one and if it already exists
    if (newAbbreviation !== oldAbbreviation) {
      const duplicateAbbr = await sql`
        SELECT DISTINCT leave_type FROM leave_entitlements 
        WHERE leave_type = ${newAbbreviation} 
        LIMIT 1
      `;

      if (duplicateAbbr.length > 0) {
        return res.status(400).json({
          success: false,
          error: `Abbreviation "${newAbbreviation}" is already in use`
        });
      }

      // Update abbreviation in leave_entitlements
      await sql`
        UPDATE leave_entitlements 
        SET leave_type = ${newAbbreviation}
        WHERE leave_type = ${oldAbbreviation}
      `;
    }

    // Update total_days for all employees with this leave type
    if (days !== undefined) {
      await sql`
        UPDATE leave_entitlements 
        SET total_days = ${days},
            updated_at = NOW()
        WHERE leave_type = ${newAbbreviation !== oldAbbreviation ? newAbbreviation : oldAbbreviation}
      `;
    }

    res.status(200).json({
      success: true,
      message: "Leave type updated successfully",
      data: {
        oldAbbreviation: oldAbbreviation,
        newAbbreviation: newAbbreviation,
        name: name,
        days: days
      }
    });

  } catch (error) {
    console.error("❌ Error updating leave type:", error);
    res.status(500).json({ 
      success: false,
      error: "Failed to update leave type",
      details: error.message 
    });
  }
};

// 📌 Delete leave type permanently
export const deleteLeaveType = async (req, res) => {
  try {
    const { abbreviation } = req.params;
    
    // Check if leave type exists
    const existingType = await sql`
      SELECT DISTINCT leave_type FROM leave_entitlements 
      WHERE leave_type = ${abbreviation}
      LIMIT 1
    `;

    if (existingType.length === 0) {
      return res.status(404).json({
        success: false,
        error: "Leave type not found"
      });
    }

    // Delete the leave type from leave_entitlements
    await sql`
      DELETE FROM leave_entitlements 
      WHERE leave_type = ${abbreviation}
    `;

    res.status(200).json({
      success: true,
      message: "Leave type deleted successfully",
      data: {
        abbreviation: abbreviation,
        deleted: true
      }
    });

  } catch (error) {
    console.error("❌ Error deleting leave type:", error);
    res.status(500).json({ 
      success: false,
      error: "Failed to delete leave type",
      details: error.message 
    });
  }
};

// 📌 Get leave type details
export const getLeaveTypeDetails = async (req, res) => {
  try {
    const { abbreviation } = req.params;
    
    // Get leave type details from leave_entitlements
    const result = await sql`
      SELECT 
        leave_type as abbreviation,
        total_days as days,
        COUNT(DISTINCT user_id) as employee_count
      FROM leave_entitlements 
      WHERE leave_type = ${abbreviation}
      GROUP BY leave_type, total_days
      LIMIT 1
    `;

    if (result.length === 0) {
      return res.status(404).json({
        success: false,
        error: "Leave type not found"
      });
    }

    res.status(200).json({
      success: true,
      data: result[0]
    });

  } catch (error) {
    console.error("❌ Error fetching leave type details:", error);
    res.status(500).json({ 
      success: false,
      error: "Failed to fetch leave type details",
      details: error.message 
    });
  }
};

// 📌 Get all distinct leave types from leave_entitlements
export const getAllLeaveTypes = async (req, res) => {
  try {
    // Fetch distinct leave types from leave_entitlements
    const leaveTypes = await sql`
      SELECT DISTINCT leave_type, total_days
      FROM leave_entitlements 
      ORDER BY leave_type;
    `;

    console.log("✅ Fetched leave types:", leaveTypes);

    // Map short codes to full names
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
      "WL": "Wellness Leave"
    };

    // Transform to include both code and full name (remove status field)
    const formattedLeaveTypes = leaveTypes.map(type => ({
      abbreviation: type.leave_type,
      name: leaveTypeFullNameMap[type.leave_type] || type.leave_type,
      days: type.total_days
    }));

    res.json({
      success: true,
      leaveTypes: formattedLeaveTypes
    });

  } catch (error) {
    console.error("❌ Error fetching leave types:", error);
    res.status(500).json({ 
      success: false,
      error: "Failed to fetch leave types" 
    });
  }
};

export const getEmployeeLeaveHistory = async (req, res) => {
  const { id } = req.params;
  
  try {
    // Get employee details first
    const [employee] = await sql`
      SELECT id, first_name, last_name, user_id
      FROM employee_list
      WHERE id = ${id}
    `;

    if (!employee) {
      return res.status(404).json({ error: "Employee not found" });
    }

    // Get all leave applications for this employee
    const leaveHistory = await sql`
      SELECT 
        la.id,
        la.date_filing,
        la.leave_type,
        la.number_of_days,
        la.inclusive_dates,
        la.details,
        la.status,
        la.approver_name,
        la.approver_date,
        la.office_head_status,
        la.office_head_date,
        la.hr_status,
        la.hr_date,
        la.mayor_status,
        la.mayor_date,
        la.remarks,
        la.created_at,
        la.updated_at,
        -- Extract start and end dates from inclusive_dates
        LOWER(la.inclusive_dates)::date as start_date,
        (UPPER(la.inclusive_dates) - INTERVAL '1 day')::date as end_date,
        -- Format dates for display
        TO_CHAR(LOWER(la.inclusive_dates), 'Mon DD, YYYY') as formatted_start_date,
        TO_CHAR((UPPER(la.inclusive_dates) - INTERVAL '1 day'), 'Mon DD, YYYY') as formatted_end_date,
        TO_CHAR(la.date_filing, 'Mon DD, YYYY') as formatted_filing_date,
        TO_CHAR(la.approver_date, 'Mon DD, YYYY') as formatted_approval_date
      FROM leave_applications la
      WHERE la.user_id = ${employee.user_id}
      ORDER BY la.date_filing DESC
    `;

    // Transform the data for easier consumption
    const formattedHistory = leaveHistory.map(leave => ({
      id: leave.id,
      leaveType: leave.leave_type,
      filingDate: leave.date_filing,
      formattedFilingDate: leave.formatted_filing_date,
      startDate: leave.start_date,
      endDate: leave.end_date,
      formattedStartDate: leave.formatted_start_date,
      formattedEndDate: leave.formatted_end_date,
      duration: parseFloat(leave.number_of_days).toFixed(1),
      status: leave.status,
      details: leave.details,
      remarks: leave.remarks,
      approver: leave.approver_name,
      approvalDate: leave.approver_date,
      formattedApprovalDate: leave.formatted_approval_date,
      // Approval status at different levels
      approvalStatus: {
        officeHead: {
          status: leave.office_head_status,
          date: leave.office_head_date
        },
        hr: {
          status: leave.hr_status,
          date: leave.hr_date
        },
        mayor: {
          status: leave.mayor_status,
          date: leave.mayor_date
        }
      },
      createdAt: leave.created_at,
      updatedAt: leave.updated_at
    }));

    // Calculate summary statistics
    const summary = {
      totalLeaves: formattedHistory.length,
      approvedLeaves: formattedHistory.filter(l => l.status === 'Approved').length,
      pendingLeaves: formattedHistory.filter(l => l.status === 'Pending').length,
      rejectedLeaves: formattedHistory.filter(l => l.status === 'Rejected').length,
      totalDaysUsed: formattedHistory
        .filter(l => l.status === 'Approved')
        .reduce((sum, leave) => sum + parseFloat(leave.duration), 0),
      byLeaveType: formattedHistory.reduce((acc, leave) => {
        acc[leave.leaveType] = (acc[leave.leaveType] || 0) + 1;
        return acc;
      }, {}),
      byYear: formattedHistory.reduce((acc, leave) => {
        const year = new Date(leave.filingDate).getFullYear();
        acc[year] = (acc[year] || 0) + 1;
        return acc;
      }, {})
    };

    res.json({
      success: true,
      employee: {
        id: employee.id,
        name: `${employee.first_name} ${employee.last_name}`
      },
      leaveHistory: formattedHistory,
      summary: summary,
      totalRecords: formattedHistory.length
    });

  } catch (error) {
    console.error("❌ Error fetching leave history:", error);
    res.status(500).json({ 
      success: false,
      error: "Failed to fetch leave history",
      details: error.message 
    });
  }
};