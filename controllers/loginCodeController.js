// controllers/loginCodeController.js
import sql from "../config/db.js";
import sgMail from '@sendgrid/mail';
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
// Generate new login code - UPDATED VERSION
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

    // Check if employee exists and get email
    const [employee] = await sql`
      SELECT id, email, first_name, last_name, department, position 
      FROM employee_list 
      WHERE id = ${employee_id}
    `;
    
    if (!employee) {
      return res.status(404).json({
        success: false,
        error: "Employee not found"
      });
    }

    // Check if employee has email
    if (!employee.email) {
      return res.status(400).json({
        success: false,
        error: "Employee does not have an email address"
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

    // Send email using SendGrid - UPDATED SECTION
    console.log('📧 ========== LOGIN CODE EMAIL START ==========');
    
    let emailSent = false;
    let emailError = null;
    
    try {
      console.log('📧 Sending login code email...');
      console.log('📧 SendGrid API Key present:', !!process.env.SENDGRID_API_KEY);
      
      // Check API key
      if (!process.env.SENDGRID_API_KEY) {
        console.error('❌ SENDGRID_API_KEY is not set!');
        throw new Error('SendGrid API key is not configured');
      }
      
      const apiKey = process.env.SENDGRID_API_KEY;
      console.log('🔑 API Key length:', apiKey.length);
      console.log('🔑 API Key starts with "SG.":', apiKey.startsWith('SG.'));
      
      // Set API key
      sgMail.setApiKey(apiKey);
      console.log('✅ SendGrid API key set');
      
      // Using fixed email for testing (as per your request)
      const toEmail = employee.email.trim();
      console.log('📧 Sending to:', toEmail);
      console.log('📧 Using from email:', 'shamelletadeja10@gmail.com');
      
      const expirationTime = new Date(expires_at);
      const formattedTime = expirationTime.toLocaleTimeString([], { 
        hour: '2-digit', 
        minute: '2-digit',
        timeZoneName: 'short'
      });
      
      // Create message - using the same structure as successful test email
      const msg = {
        to: toEmail,
        from: {
          email: 'shamelletadeja10@gmail.com',
          name: 'EZLeave System'
        },
        replyTo: 'ezleave516@gmail.com',
        subject: `Your Login Code: ${code}`,
        text: `
EZLeave Login Code

Hello ${employee.first_name} ${employee.last_name},

You have been issued a login code for the EZLeave system.

Your Login Code: ${code}

Employee Details:
- Name: ${employee.first_name} ${employee.last_name}
- Department: ${employee.department || 'Not specified'}
- Position: ${employee.position || 'Not specified'}

⚠️ IMPORTANT: This code will expire at ${formattedTime} (15 minutes from now).

Instructions:
1. Go to the EZLeave login page
2. Select "Login with Code" option
3. Enter the code above
4. Complete your login

Security Notice:
- Do not share this code with anyone
- The code can only be used once
- If you did not request this code, please contact your administrator immediately

For security reasons, this code will automatically expire after use or after the expiration time.

This is an automated message from the EZLeave System.
© ${new Date().getFullYear()} EZLeave. All rights reserved.
        `,
        html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; border: 1px solid #ddd; }
    .code { 
      font-size: 32px; 
      font-weight: bold; 
      letter-spacing: 5px; 
      text-align: center; 
      margin: 20px 0; 
      padding: 15px;
      background-color: #fff;
      border: 2px dashed #4CAF50;
      border-radius: 5px;
      font-family: monospace;
    }
    .footer { 
      margin-top: 30px; 
      padding-top: 20px; 
      border-top: 1px solid #ddd; 
      font-size: 12px; 
      color: #666; 
      text-align: center;
    }
    .warning { 
      background-color: #fff3cd; 
      border: 1px solid #ffeaa7; 
      padding: 10px; 
      border-radius: 4px; 
      margin: 15px 0;
    }
    .employee-info { 
      background-color: #e9ecef; 
      padding: 15px; 
      border-radius: 4px; 
      margin-bottom: 20px;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>EZLeave Login Code</h1>
    </div>
    <div class="content">
      <p>Hello ${employee.first_name} ${employee.last_name},</p>
      
      <div class="employee-info">
        <p><strong>Employee Details:</strong></p>
        <p><strong>Name:</strong> ${employee.first_name} ${employee.last_name}</p>
        <p><strong>Department:</strong> ${employee.department || 'Not specified'}</p>
        <p><strong>Position:</strong> ${employee.position || 'Not specified'}</p>
      </div>
      
      <p>You have been issued a login code for the EZLeave system. Please use this code to log in:</p>
      
      <div class="code">${code}</div>
      
      <div class="warning">
        <p><strong>⚠️ Important:</strong> This code will expire at <strong>${formattedTime}</strong> (15 minutes from now).</p>
      </div>
      
      <p><strong>Instructions:</strong></p>
      <ol>
        <li>Go to the EZLeave login page</li>
        <li>Select "Login with Code" option</li>
        <li>Enter the code above</li>
        <li>Complete your login</li>
      </ol>
      
      <p><strong>Security Notice:</strong></p>
      <ul>
        <li>Do not share this code with anyone</li>
        <li>The code can only be used once</li>
        <li>If you did not request this code, please contact your administrator immediately</li>
      </ul>
      
      <p>For security reasons, this code will automatically expire after use or after the expiration time.</p>
      
      <div class="footer">
        <p>This is an automated message from the EZLeave System.</p>
        <p>© ${new Date().getFullYear()} EZLeave. All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>
        `
      };
      
      console.log('📧 Attempting to send email via SendGrid...');
      
      // Send the email
      const response = await sgMail.send(msg);
      
      console.log('✅ Email sent successfully!');
      console.log('📧 SendGrid response status:', response[0]?.statusCode);
      emailSent = true;
      
    } catch (emailError) {
      console.error('❌ ========== EMAIL SEND FAILED ==========');
      console.error('❌ Error type:', emailError.name);
      console.error('❌ Error message:', emailError.message);
      console.error('❌ Error code:', emailError.code);
      
      // SendGrid specific error details
      if (emailError.response) {
        console.error('❌ SendGrid response status:', emailError.response.statusCode);
        console.error('❌ SendGrid response body:', emailError.response.body);
      }
      
      console.error('========== EMAIL SEND FAILED ==========');
    }
    
    console.log('📧 ========== LOGIN CODE EMAIL END ==========');

    // Return response
    res.status(201).json({
      success: true,
      message: "Login code generated successfully",
      data: newCode,
      email_sent: emailSent,
      email_error: emailSent ? null : "Failed to send email",
      generated_code: code
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

// Test email sending (for debugging with Postman)
export const testEmail = async (req, res) => {
  try {
    console.log('🔧 ========== EMAIL TEST STARTED ==========');
    console.log('📧 Environment check...');
    console.log('📧 SENDGRID_API_KEY exists:', !!process.env.SENDGRID_API_KEY);
    
    // Check if API key exists
    if (!process.env.SENDGRID_API_KEY) {
      console.error('❌ SENDGRID_API_KEY is not set!');
      return res.status(500).json({
        success: false,
        error: "SENDGRID_API_KEY is not set in environment variables",
        details: "Check your .env file or environment variables"
      });
    }
    
    const apiKey = process.env.SENDGRID_API_KEY;
    console.log('🔑 API Key length:', apiKey.length);
    console.log('🔑 API Key starts with "SG.":', apiKey.startsWith('SG.'));
    console.log('🔑 API Key first 20 chars:', apiKey.substring(0, 20) + '...');
    
    // Set API key
    sgMail.setApiKey(apiKey);
    console.log('✅ SendGrid API key set');
    
    // Get email from request body or use default
    const toEmail = req.body.email || 'shamelletadeja10@gmail.com';
    const testCode = req.body.code || 'TEST123';
    
    console.log('📧 Sending to:', toEmail);
    console.log('📧 Using from email:', 'shamelletadeja10@gmail.com');
    
    // Create test message
    const msg = {
      to: toEmail,
      from: {
        email: 'shamelletadeja10@gmail.com',
        name: 'EZLeave System'
      },
      replyTo: 'ezleave516@gmail.com',
      subject: `Test Email - Login Code: ${testCode}`,
      text: `
EZLeave Test Email

This is a test email sent at: ${new Date().toLocaleString()}

Test Login Code: ${testCode}

If you receive this email, your SendGrid configuration is working correctly!

Environment: ${process.env.NODE_ENV || 'development'}

Thank you,
EZLeave System
      `,
      html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; border: 1px solid #ddd; }
    .code { 
      font-size: 32px; 
      font-weight: bold; 
      letter-spacing: 5px; 
      text-align: center; 
      margin: 20px 0; 
      padding: 15px;
      background-color: #fff;
      border: 2px dashed #4CAF50;
      border-radius: 5px;
      font-family: monospace;
    }
    .info { 
      background-color: #e9ecef; 
      padding: 15px; 
      border-radius: 4px; 
      margin-bottom: 20px;
      font-size: 14px;
    }
    .footer { 
      margin-top: 30px; 
      padding-top: 20px; 
      border-top: 1px solid #ddd; 
      font-size: 12px; 
      color: #666; 
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>EZLeave Test Email</h1>
    </div>
    <div class="content">
      <p>This is a test email sent at: <strong>${new Date().toLocaleString()}</strong></p>
      
      <div class="info">
        <p><strong>Test Details:</strong></p>
        <p><strong>To:</strong> ${toEmail}</p>
        <p><strong>Environment:</strong> ${process.env.NODE_ENV || 'development'}</p>
        <p><strong>Purpose:</strong> SendGrid Configuration Test</p>
      </div>
      
      <p>Your test login code is:</p>
      <div class="code">${testCode}</div>
      
      <p>If you receive this email, your SendGrid configuration is working correctly!</p>
      
      <div class="footer">
        <p>This is an automated test message from the EZLeave System.</p>
        <p>© ${new Date().getFullYear()} EZLeave. All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>
      `
    };
    
    console.log('📧 Attempting to send email via SendGrid...');
    
    // Send the email
    const response = await sgMail.send(msg);
    
    console.log('✅ Email sent successfully!');
    console.log('📧 SendGrid response status:', response[0]?.statusCode);
    console.log('📧 SendGrid response headers:', response[0]?.headers);
    console.log('========== EMAIL TEST COMPLETED ==========');
    
    res.json({
      success: true,
      message: "Test email sent successfully",
      data: {
        to: toEmail,
        from: 'shamelletadeja10@gmail.com',
        code: testCode,
        sent_at: new Date().toISOString(),
        sendgrid_response: {
          statusCode: response[0]?.statusCode,
          headers: response[0]?.headers
        }
      }
    });
    
  } catch (error) {
    console.error('❌ ========== EMAIL TEST FAILED ==========');
    console.error('❌ Error type:', error.name);
    console.error('❌ Error message:', error.message);
    console.error('❌ Error code:', error.code);
    
    // SendGrid specific error details
    if (error.response) {
      console.error('❌ SendGrid response status:', error.response.statusCode);
      console.error('❌ SendGrid response body:', error.response.body);
      console.error('❌ SendGrid response headers:', error.response.headers);
    }
    
    console.error('❌ Stack trace:', error.stack);
    console.error('========== EMAIL TEST FAILED ==========');
    
    res.status(500).json({
      success: false,
      error: "Failed to send test email",
      details: error.message,
      sendgrid_error: error.response ? {
        status: error.response.statusCode,
        body: error.response.body,
        headers: error.response.headers
      } : null,
      timestamp: new Date().toISOString()
    });
  }
};