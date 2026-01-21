// controllers/loginCodeController.js
import sql from "../config/db.js";

// Generate a random code
const generateRandomCode = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
};

// Generate new login code
export const generateLoginCode = async (req, res) => {
  try {
    const { employee_id, employee_name, expires_at } = req.body;

    // Validate required fields
    if (!employee_id || !employee_name || !expires_at) {
      return res.status(400).json({
        success: false,
        error: "Employee ID, name, and expiration date are required"
      });
    }

    // Check if employee exists
    const employeeExists = await sql`
      SELECT id FROM employee_list WHERE id = ${employee_id}
    `;
    
    if (employeeExists.length === 0) {
      return res.status(404).json({
        success: false,
        error: "Employee not found"
      });
    }

    // Generate unique code
    let code;
    let isUnique = false;
    let attempts = 0;
    const maxAttempts = 10;

    while (!isUnique && attempts < maxAttempts) {
      code = generateRandomCode();
      const existingCode = await sql`
        SELECT id FROM login_codes WHERE code = ${code}
      `;
      if (existingCode.length === 0) {
        isUnique = true;
      }
      attempts++;
    }

    if (!isUnique) {
      return res.status(500).json({
        success: false,
        error: "Failed to generate unique code"
      });
    }

    // Insert the code
    const [newCode] = await sql`
      INSERT INTO login_codes (
        employee_id,
        employee_name,
        code,
        expires_at
      ) VALUES (
        ${employee_id},
        ${employee_name},
        ${code},
        ${expires_at}
      )
      RETURNING *;
    `;

    res.status(201).json({
      success: true,
      message: "Login code generated successfully",
      data: newCode
    });

  } catch (error) {
    console.error("❌ Error generating login code:", error);
    res.status(500).json({
      success: false,
      error: "Failed to generate login code",
      details: error.message
    });
  }
};

// Get all login codes
export const getAllLoginCodes = async (req, res) => {
  try {
    const codes = await sql`
      SELECT 
        lc.*,
        el.first_name,
        el.last_name,
        el.email,
        el.department,
        el.position
      FROM login_codes lc
      LEFT JOIN employee_list el ON lc.employee_id = el.id
      ORDER BY lc.generated_at DESC
    `;

    res.json({
      success: true,
      data: codes
    });

  } catch (error) {
    console.error("❌ Error fetching login codes:", error);
    res.status(500).json({
      success: false,
      error: "Failed to fetch login codes",
      details: error.message
    });
  }
};

// Get login codes by employee ID
export const getLoginCodesByEmployee = async (req, res) => {
  try {
    const { employeeId } = req.params;

    const codes = await sql`
      SELECT * FROM login_codes
      WHERE employee_id = ${employeeId}
      ORDER BY generated_at DESC
    `;

    res.json({
      success: true,
      data: codes
    });

  } catch (error) {
    console.error("❌ Error fetching employee login codes:", error);
    res.status(500).json({
      success: false,
      error: "Failed to fetch login codes",
      details: error.message
    });
  }
};

// Verify login code
export const verifyLoginCode = async (req, res) => {
  try {
    const { code } = req.body;

    if (!code) {
      return res.status(400).json({
        success: false,
        error: "Code is required"
      });
    }

    // Find the code
    const [codeRecord] = await sql`
      SELECT 
        lc.*,
        el.first_name,
        el.last_name,
        el.email,
        el.department,
        el.position,
        el.id_number,
        el.contact_number,
        el.profile_picture
      FROM login_codes lc
      LEFT JOIN employee_list el ON lc.employee_id = el.id
      WHERE lc.code = ${code}
    `;

    if (!codeRecord) {
      return res.status(404).json({
        success: false,
        error: "Invalid code"
      });
    }

    // Check if code is already used
    if (codeRecord.is_used) {
      return res.status(400).json({
        success: false,
        error: "Code has already been used",
        used_at: codeRecord.used_at
      });
    }

    // Check if code is expired
    const now = new Date();
    const expiresAt = new Date(codeRecord.expires_at);
    
    if (now > expiresAt) {
      return res.status(400).json({
        success: false,
        error: "Code has expired",
        expired_at: codeRecord.expires_at
      });
    }

    // Mark code as used
    const [updatedCode] = await sql`
      UPDATE login_codes
      SET 
        is_used = TRUE,
        used_at = CURRENT_TIMESTAMP
      WHERE id = ${codeRecord.id}
      RETURNING *
    `;

    res.json({
      success: true,
      message: "Code verified successfully",
      data: {
        code: updatedCode,
        employee: {
          id: codeRecord.employee_id,
          name: codeRecord.employee_name,
          first_name: codeRecord.first_name,
          last_name: codeRecord.last_name,
          email: codeRecord.email,
          department: codeRecord.department,
          position: codeRecord.position,
          id_number: codeRecord.id_number,
          contact_number: codeRecord.contact_number,
          profile_picture: codeRecord.profile_picture
        }
      }
    });

  } catch (error) {
    console.error("❌ Error verifying login code:", error);
    res.status(500).json({
      success: false,
      error: "Failed to verify code",
      details: error.message
    });
  }
};

// Revoke/delete login code
export const revokeLoginCode = async (req, res) => {
  try {
    const { id } = req.params;

    const [deletedCode] = await sql`
      DELETE FROM login_codes
      WHERE id = ${id}
      RETURNING *
    `;

    if (!deletedCode) {
      return res.status(404).json({
        success: false,
        error: "Code not found"
      });
    }

    res.json({
      success: true,
      message: "Code revoked successfully",
      data: deletedCode
    });

  } catch (error) {
    console.error("❌ Error revoking login code:", error);
    res.status(500).json({
      success: false,
      error: "Failed to revoke code",
      details: error.message
    });
  }
};

// Clean up expired codes (cron job endpoint)
export const cleanupExpiredCodes = async (req, res) => {
  try {
    const result = await sql`
      DELETE FROM login_codes
      WHERE expires_at < CURRENT_TIMESTAMP
        AND is_used = FALSE
      RETURNING *
    `;

    res.json({
      success: true,
      message: `Cleaned up ${result.length} expired codes`,
      data: result
    });

  } catch (error) {
    console.error("❌ Error cleaning up expired codes:", error);
    res.status(500).json({
      success: false,
      error: "Failed to clean up expired codes",
      details: error.message
    });
  }
};

// Get code statistics
export const getCodeStatistics = async (req, res) => {
  try {
    const stats = await sql`
      SELECT 
        COUNT(*) as total_codes,
        COUNT(CASE WHEN is_used = TRUE THEN 1 END) as used_codes,
        COUNT(CASE WHEN is_used = FALSE AND expires_at > CURRENT_TIMESTAMP THEN 1 END) as active_codes,
        COUNT(CASE WHEN is_used = FALSE AND expires_at <= CURRENT_TIMESTAMP THEN 1 END) as expired_codes
      FROM login_codes
    `;

    // Recent activity
    const recentActivity = await sql`
      SELECT 
        employee_name,
        code,
        generated_at,
        expires_at,
        is_used,
        used_at
      FROM login_codes
      ORDER BY generated_at DESC
      LIMIT 10
    `;

    // Top employees with generated codes
    const topEmployees = await sql`
      SELECT 
        employee_id,
        employee_name,
        COUNT(*) as code_count
      FROM login_codes
      GROUP BY employee_id, employee_name
      ORDER BY code_count DESC
      LIMIT 5
    `;

    res.json({
      success: true,
      data: {
        statistics: stats[0],
        recent_activity: recentActivity,
        top_employees: topEmployees
      }
    });

  } catch (error) {
    console.error("❌ Error fetching code statistics:", error);
    res.status(500).json({
      success: false,
      error: "Failed to fetch statistics",
      details: error.message
    });
  }
};