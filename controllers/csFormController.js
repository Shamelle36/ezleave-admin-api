import fs from "fs";
import path from "path";
import puppeteer from "puppeteer-core"; // Changed from puppeteer to puppeteer-core
import chromium from "@sparticuz/chromium"; // Add this import
import sql from "../config/db.js";
import sharp from 'sharp';

export const removeSignatureBackground = async (req, res) => {
  // Set timeout for the entire request
  res.setTimeout(30000, () => {
    if (!res.headersSent) {
      res.status(408).json({
        message: "Request timeout - processing took too long"
      });
    }
  });

  try {
    const { image } = req.body;

    if (!image) {
      return res.status(400).json({
        message: "Image data is required"
      });
    }

    console.log("🖼️ Processing signature background removal...");

    // Validate and limit image size
    const maxSize = 5 * 1024 * 1024; // 5MB max
    const base64Size = Buffer.byteLength(image, 'utf8');
    
    if (base64Size > maxSize) {
      console.warn(`Image too large: ${base64Size} bytes`);
      return res.json({
        processedImage: image,
        message: "Image too large for processing, using original",
        warning: "Image exceeds 5MB limit"
      });
    }

    // Extract base64 data
    const base64Match = image.match(/^data:image\/(\w+);base64,(.+)$/);
    if (!base64Match) {
      console.warn("Invalid base64 image format");
      return res.json({
        processedImage: image,
        message: "Invalid image format, using original",
        warning: "Not a valid base64 image"
      });
    }

    const [, imageType, base64Data] = base64Match;
    const allowedTypes = ['png', 'jpeg', 'jpg'];
    
    if (!allowedTypes.includes(imageType.toLowerCase())) {
      console.warn(`Unsupported image type: ${imageType}`);
      return res.json({
        processedImage: image,
        message: "Unsupported image type, using original",
        warning: `Image type ${imageType} not supported`
      });
    }

    const buffer = Buffer.from(base64Data, 'base64');
    
    // Optimize sharp operations
    try {
      const processedBuffer = await sharp(buffer)
        .resize(800, 300, { // Resize to reasonable dimensions
          fit: 'inside',
          withoutEnlargement: true
        })
        .grayscale()
        .normalise() // Better than .linear() for contrast
        .threshold(245, { // Slightly higher threshold
          grayscale: true
        })
        .png({
          compressionLevel: 6,
          adaptiveFiltering: true
        })
        .toBuffer();

      const processedBase64 = processedBuffer.toString('base64');
      const processedImage = `data:image/png;base64,${processedBase64}`;

      console.log("✅ Background removed successfully");
      
      return res.json({
        processedImage: processedImage,
        message: "Signature background removed successfully"
      });

    } catch (sharpError) {
      console.error("Sharp processing error:", sharpError);
      // Fall back to simpler processing
      try {
        const simpleBuffer = await sharp(buffer)
          .resize(800, 300, { fit: 'inside' })
          .grayscale()
          .png()
          .toBuffer();
          
        const simpleBase64 = simpleBuffer.toString('base64');
        const simpleImage = `data:image/png;base64,${simpleBase64}`;
        
        return res.json({
          processedImage: simpleImage,
          message: "Basic processing applied",
          warning: "Could not fully remove background"
        });
      } catch (fallbackError) {
        console.error("Fallback processing also failed:", fallbackError);
        throw new Error("Image processing failed");
      }
    }

  } catch (err) {
    console.error("Error in removeSignatureBackground:", err);
    
    // Always return original image if provided
    if (req.body.image) {
      return res.json({
        processedImage: req.body.image,
        message: "Using original image (processing failed)",
        warning: err.message || "Unknown error"
      });
    } else {
      return res.status(400).json({
        message: "Failed to process signature image",
        error: err.message || "Unknown error"
      });
    }
  }
};

// ... existing code ...

export const generateCSForm = async (req, res) => {
  let browser;
  let pdfBuffer;

  try {
    const { 
      leave_application_id, 
      days_with_pay, 
      requesting_role, 
      action_type, 
      action_remarks,
      real_time_data,
      user_id,
      user_data,
      signature_data,
      signature_method,
      save_to_db = true
    } = req.body;

    if (!leave_application_id) {
      return res.status(400).json({
        message: "Leave application ID is required"
      });
    }

    // Use real-time data if available, otherwise use the main parameters
    const effectiveActionType = real_time_data?.action_type || action_type;
    const effectiveActionRemarks = real_time_data?.action_remarks || action_remarks;
    const effectiveDaysWithPay = real_time_data?.days_with_pay !== undefined 
      ? real_time_data.days_with_pay 
      : days_with_pay;

    console.log("Using form data:", {
      effectiveActionType,
      effectiveActionRemarks, 
      effectiveDaysWithPay,
      signature_method,
      has_signature: !!signature_data
    });

    const [leaveApplication] = await sql`
      SELECT 
        lr.*,
        el.department,
        el.position,
        el.first_name,
        el.middle_name, 
        el.last_name,
        lr.salary,
        lr.remarks,
        lr.approved_by,
        lr.approver_name,
        lr.approver_date,
        lr.office_head_status,
        lr.hr_status,
        lr.mayor_status,
        lr.office_head_signature,
        lr.hr_signature,
        lr.mayor_signature,
        lr.subtype,
        lr.signature_url
        
        -- Get earned values for current year
        (SELECT period FROM leave_cards WHERE employee_id = el.id AND period LIKE '%2025%' ORDER BY id DESC LIMIT 1) as period,
        (SELECT CAST(vl_balance AS NUMERIC) FROM leave_cards WHERE employee_id = el.id AND period LIKE '%2025%' ORDER BY id DESC LIMIT 1) as vacation_leave_earned,
        (SELECT CAST(sl_balance AS NUMERIC) FROM leave_cards WHERE employee_id = el.id AND period LIKE '%2025%' ORDER BY id DESC LIMIT 1) as sick_leave_earned,
        
        -- Get the latest balance values
        (SELECT CAST(vl_balance AS NUMERIC) FROM leave_cards WHERE employee_id = el.id ORDER BY id DESC LIMIT 1) as vacation_leave_balance,
        (SELECT CAST(sl_balance AS NUMERIC) FROM leave_cards WHERE employee_id = el.id ORDER BY id DESC LIMIT 1) as sick_leave_balance
        
      FROM leave_applications lr
      LEFT JOIN employee_list el ON lr.user_id = el.user_id
      WHERE lr.id = ${leave_application_id}
    `;

    if (!leaveApplication) {
      return res.status(404).json({
        message: "Leave application not found"
      });
    }

    // Extract data from the database result
    const {
      department = "",
      first_name = "",
      middle_name = "",
      last_name = "",
      position = "",
      salary = "",
      date_filing = "",
      leave_type = "",
      number_of_days = "",
      inclusive_dates = "",
      commutation_requested = false,
      details = "",
      status = "",
      remarks = "",
      approved_by = "",
      approver_name = "",
      approver_date = "",
      office_head_status = "",
      hr_status = "",
      mayor_status = "",
      office_head_signature = "",
      hr_signature = "",
      mayor_signature = "",
      period = "",
      vacation_leave_earned = "",
      sick_leave_earned = "",
      vacation_leave_balance = "",
      sick_leave_balance = "",
      signature_url = ""
    } = leaveApplication;

    // Determine if HR has approved - only then show leave credit values in 7.A
    const hrApproved = hr_status === "Approved";
    
    // If the current user is HR admin and they're approving, show the values
    const showLeaveCredits = hrApproved || requesting_role === "admin";
    
    // Format the period for "As of" section - only show if HR approved or HR is viewing
    const formatPeriod = (periodString) => {
      if (!periodString || !showLeaveCredits) return '';
      
      try {
        if (/^[A-Za-z]+\s+\d{4}$/.test(periodString)) {
          return periodString;
        }
        
        const yearMatch = periodString.match(/\d{4}/);
        const monthMatch = periodString.match(/^(\d+)\//);
        
        if (yearMatch && monthMatch) {
          const year = yearMatch[0];
          const monthNumber = parseInt(monthMatch[1]);
          const monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
          ];
          
          if (monthNumber >= 1 && monthNumber <= 12) {
            return `${monthNames[monthNumber - 1]} ${year}`;
          }
        }
        
        return periodString;
      } catch (error) {
        console.error('Error formatting period:', error);
        return periodString;
      }
    };

    const formattedPeriod = formatPeriod(period);

    const isApproved = status === "Approved";
    const isRejected = status === "Rejected";

    const currentActionType = effectiveActionType;
    
    // Determine days with pay (for approved leaves) - only mayor can set this
    const daysWithPay = effectiveDaysWithPay !== undefined ? effectiveDaysWithPay : number_of_days;
    const daysWithoutPay = "0";    

    // Determine disapproval reason - use the effective action_remarks
    const disapprovalReason = effectiveActionRemarks || (isRejected ? remarks : "");

    // Calculate balances only if showing leave credits
    const vacationBalance = showLeaveCredits && leave_type === "Vacation Leave" 
        ? (parseFloat(vacation_leave_earned || 0) - parseFloat(number_of_days || 0)).toFixed(3)
        : showLeaveCredits ? vacation_leave_balance || '0' : '';

    const sickBalance = showLeaveCredits && leave_type === "Sick Leave" 
        ? (parseFloat(sick_leave_earned || 0) - parseFloat(number_of_days || 0)).toFixed(3)
        : showLeaveCredits ? sick_leave_balance || '0' : '';

    // Only show earned values if showing leave credits
    const displayVacationEarned = showLeaveCredits ? (vacation_leave_earned || '0') : '';
    const displaySickEarned = showLeaveCredits ? (sick_leave_earned || '0') : '';

    // Determine signature section based on role - for the final approval section
    let finalSignatureSection = "Municipal Mayor";

    let approverFullName = "";
    let mayorFullName = "";
    let departmentHeadFullName = "";
    let approverRow;

    // In the generateCSForm function, update the signature display logic:

let displaySignature = "";

// Check if we have a newly uploaded signature
if (signature_method === "upload" && signature_data) {
  displaySignature = signature_data;
  console.log("📤 Using uploaded signature");
} else if (signature_method === "e-sign" && signature_data) {
  displaySignature = signature_data;
  console.log("✍️ Using e-signature");
} else {
  // Use stored signatures from database
  if (requesting_role === "office_head") {
    displaySignature = office_head_signature;
  } else if (requesting_role === "admin") {
    displaySignature = hr_signature;
  } else if (requesting_role === "mayor") {
    displaySignature = mayor_signature;
  }
}

// Also update the separate role signature variables to handle uploaded signatures:
const officeHeadSignature = signature_method === "upload" && requesting_role === "office_head" ? signature_data : office_head_signature;
const hrSignature = signature_method === "upload" && requesting_role === "admin" ? signature_data : hr_signature;
const mayorSignature = signature_method === "upload" && requesting_role === "mayor" ? signature_data : mayor_signature;

    const userId = user_id;

    if (!userId) {
      return res.status(401).json({
        message: "User ID is required in request"
      });
    }

    console.log("Using user ID:", userId, "for role:", requesting_role);

    // Get mayor's name regardless of current user role
    try {
        const [mayorRow] = await sql`
            SELECT full_name
            FROM admin_accounts
            WHERE role = 'mayor'
            LIMIT 1
        `;
        mayorFullName = mayorRow?.full_name || "";
    } catch (error) {
        console.error("Error fetching mayor:", error);
    }

    // Get department head's name for the employee's department
    try {
        const [deptHeadRow] = await sql`
            SELECT aa.full_name
            FROM admin_accounts aa
            WHERE aa.role = 'office_head' 
            AND aa.department = ${department}
            LIMIT 1
        `;
        departmentHeadFullName = deptHeadRow?.full_name || "";
    } catch (error) {
        console.error("Error fetching department head:", error);
    }

    if (requesting_role === "office_head") {
      [approverRow] = await sql`
        SELECT full_name
        FROM admin_accounts
        WHERE id = ${userId} AND role = 'office_head'
      `;
      approverFullName = approverRow?.full_name || "";
    }
    else if (requesting_role === "admin") {
      [approverRow] = await sql`
        SELECT full_name
        FROM useradmin
        WHERE id = ${userId}
      `;
      approverFullName = approverRow?.full_name || "";
    }
    else if (requesting_role === "mayor") {
      [approverRow] = await sql`
        SELECT full_name
        FROM admin_accounts
        WHERE id = ${userId} AND role = 'mayor'
      `;
      approverFullName = approverRow?.full_name || "";
    }

    console.log("✅ Final approverFullName:", approverFullName);
    console.log("✅ Mayor's name:", mayorFullName);

    let displayMayorName = "";
    if (requesting_role === "mayor") {
        displayMayorName = mayorFullName;  
    }

    console.log("✅ Department Head's name:", departmentHeadFullName);

    let hrApproverFullName = "";
    if (requesting_role === "admin") {
        hrApproverFullName = approverFullName;
    } else {
        try {
            const [hrRow] = await sql`
                SELECT full_name 
                FROM useradmin 
                WHERE role = 'admin' 
                LIMIT 1
            `;
            hrApproverFullName = hrRow?.full_name || "HR Department";
        } catch (error) {
            console.error("Error fetching HR admin:", error);
            hrApproverFullName = "HR Department";
        }
    }

    let recommendationSignatureSection = "Department Head";
    
    let recommendationName = departmentHeadFullName;
    if (requesting_role === "office_head") {
        recommendationName = approverFullName || departmentHeadFullName;
    }

    let logoBase64 = '';
    try {
      const logoPath = path.join(process.cwd(), 'templates', 'paluan-logo.png');
      const logoBuffer = fs.readFileSync(logoPath);
      logoBase64 = logoBuffer.toString('base64');
    } catch (error) {
      console.warn('Logo file not found, using placeholder');
    }

    const formattedDateFiling = date_filing ? new Date(date_filing).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    }) : '';

    let formattedInclusiveDates = '';
    if (inclusive_dates) {
      try {
        if (inclusive_dates.includes('[') && inclusive_dates.includes(',')) {
          const match = inclusive_dates.match(/\[(.*?),(.*?)[)\]]/);
          if (match) {
            const startDate = new Date(match[1]);
            const endDate = new Date(match[2]);
            formattedInclusiveDates = `${startDate.toLocaleDateString('en-US', {
              month: 'long',
              day: 'numeric',
              year: 'numeric'
            })} - ${endDate.toLocaleDateString('en-US', {
              month: 'long',
              day: 'numeric',
              year: 'numeric'
            })}`;
          }
        } else {
          formattedInclusiveDates = inclusive_dates;
        }
      } catch (error) {
        console.error('Error parsing inclusive dates:', error);
        formattedInclusiveDates = inclusive_dates;
      }
    }

    const commutationStatus = commutation_requested ? "Requested" : "Not Requested";

    let leaveLocation = "";
    if (leaveApplication.subtype === "Abroad") {
      leaveLocation = "abroad";
    } else if (leaveApplication.subtype === "Philippines") {
      leaveLocation = "within";
    }

    let hospitalIllness = "";
    let outpatientIllness = "";
    let womenLeaveIllness = "";

    if (leaveApplication.subtype) {
      if (leaveApplication.subtype === "Hospital") {
        hospitalIllness = details || "";
      } else if (leaveApplication.subtype === "Outpatient") {
        outpatientIllness = details || "";
      } else if (leave_type === "Special Leave Benefits for Women") {
        womenLeaveIllness = details || "";
      }
    }


    console.log("=== SIGNATURE DEBUG INFO ===");
    console.log("Requesting role:", requesting_role);
    console.log("Signature method:", signature_method);
    console.log("Signature data present:", !!signature_data);
    console.log("Saved signature present:", !!displaySignature);
    console.log("Approver full name:", approverFullName);
    console.log("Recommendation name:", recommendationName);
    console.log("HR approver name:", hrApproverFullName);
    console.log("Mayor display name:", displayMayorName);
    console.log("Applicant signature URL:", signature_url);
    console.log("=== END DEBUG INFO ===");    

    // Check if signature_url is a base64 string and prepare it for display
    let applicantSignatureHtml = '';
    if (signature_url && signature_url.startsWith('data:image/')) {
      // It's already a base64 data URL
      applicantSignatureHtml = `
        <div style="text-align: center; margin-top: 8px;">
          <img 
            src="${signature_url}" 
            style="max-width: 120px; max-height: 40px; object-fit: contain;"
            onerror="this.style.display='none';"
          />
        </div>
      `;
    } else if (signature_url && signature_url.startsWith('http')) {
      // It's a URL, use it directly
      applicantSignatureHtml = `
        <div style="text-align: center; margin-top: 8px;">
          <img 
            src="${signature_url}" 
            style="max-width: 120px; max-height: 40px; object-fit: contain;"
            onerror="this.style.display='none';"
          />
        </div>
      `;
    }

    // FIXED: Updated HTML with applicant signature
    const htmlContent = `
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8" />
      <title>CS Form No.6 - Application for Leave</title>
      <style>
        @page { 
        margin: 5mm 15mm;
        }
        html,body { 
        margin:0; 
        padding:0; 
        font-family: "Arial", serif; 
        color:#000; 
        background:white;
        height: auto;
        }
        .container { 
        width: 216mm; 
        height: auto;
        padding:0; 
        box-sizing: border-box; 
        }

        .main-title { 
          font-weight:bold; 
          font-size:24px; 
          margin:10px 0 6px 0; 
          letter-spacing:0.5px; 
          text-align:center; 
        }

        table { width:100%; border-collapse:collapse; height: auto; }
        .bordered td, .bordered th { border:1px solid #000; padding:4px; vertical-align:top;}

        .section-header { text-align:center; padding:6px; border-top: 2px solid #000; border-bottom: 2px solid #000; font-weight: bold, font-size: 16px }
        .subsection-header { text-align:left; padding:4px; }

        .checkbox { display:inline-block; width:12px; height:12px; border:1px solid #000; margin-right:6px; font-size:10px; text-align:center; line-height:10px; }
        
        .leave-item { padding:2px 4px; display: flex; align-items: center; margin-bottom: 5px; font-size: 13px }
        .italic { font-style:italic; }
        .underline { display:inline-block; border-bottom:1px solid #000; min-width:50px; height:12px; margin:0 2px; }
        .underline-large { display:inline-block; border-bottom:1px solid #000; min-width:120px; height:12px; margin:0 2px; }
        .full-width-underline { flex: 1; border-bottom: 1px solid #000; height: 12px; margin-left: 4px; }
        .underline-below { display: block; border-bottom: 1px solid #000; width: 100%; height: 12px; margin-top: 2px; }
        .double-underline { display: block; border-bottom: 1px solid #000; width: 100%; height: 12px; margin-top: 2px; }
        .double-underline + .double-underline { margin-top: 8px; }
        
        .signature { text-align:center; font-size:10px; }
        .single-sign { text-align:center; margin-top:15px; } /* Reduced from 25px to 15px */
        
        .two-col { display:flex; gap:10px; margin-top:8px; }
        .two-col .col { flex:1; }
        
        .text-center { text-align:center; }
        .text-left { text-align:left; }
        .text-right { text-align:right; }
        
        .mt-8 { margin-top:8px; }
        .mb-4 { margin-bottom:4px; }

        .note {
        font-size: 10px;   
        }

        .header-container {
          display: flex;
          align-items: center;
          justify-content: center;
          margin-bottom: 15px; /* Reduced from 20px */
          position: relative;
          margin-top: 15px; /* Reduced from 20px */
        }
        .logo {
          width: 80px;
          height: 80px;
          position: absolute;
          left: 150px;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .agency-info {
          text-align: center;
        }

        .inline-underline {
          display: inline-flex;
          align-items: center;
          margin-bottom: 8px;
        }

        .filled-data {
          display: inline-block;
          min-width: 120px;
          border-bottom: 1px solid #000;
          text-align: center;
          padding: 0 5px;
          font-weight: normal;
        }

        .period-data {
          display: inline-block;
          min-width: 150px;
          border-bottom: 1px solid #000;
          text-align: center;
          padding: 0 5px;
          font-weight: normal;
        }

        .signature-container {
          text-align: center;
          margin-top: 5px; /* Reduced from 10px */
        }
        
        .signature-image {
          max-width: 120px; /* Reduced from 180px */
          max-height: 40px; /* Reduced from 60px */
          object-fit: contain;
        }

        /* Compact signature layout */
        .compact-signature {
          display: flex;
          flex-direction: column;
          align-items: center;
          margin-top: 5px; /* Reduced spacing */
        }
        
        .compact-signature-name {
          text-align: center;
          margin-top: 2px; /* Reduced from 3px */
          font-size: 11px; /* Reduced from 12px */
        }
        
        .compact-signature-underline {
          width: 150px; /* Reduced from 200px */
          border-bottom: 1px solid #000;
          margin-top: 1px; /* Reduced from 2px */
        }
        
        .compact-signature-title {
          font-size: 11px; /* Reduced from 12px */
          margin-top: 1px; /* Reduced from 3px */
          text-align: center;
        }

      </style>
    </head>

    <body>

      <div class="container">

      <header style="text-align: left; margin-bottom: 15px;"> <!-- Reduced margin -->
        <p style="font-size: 12px; font-style: italic; font-weight: bold; margin: 0;">
            Civil Service Form No. 6
        </p>
        <p style="font-size: 12px; font-style: italic; font-weight: bold; margin: 0;">
            Revised 2020
        </p>

        <div class="header-container">
          <div class="logo">
            ${logoBase64 ? 
              `<img src="data:image/png;base64,${logoBase64}" style="width: 80px; height: 80px; object-fit: contain;">` : 
              `<div style="width: 80px; height: 80px; border: 1px solid #000; display: flex; align-items: center; justify-content: center; font-size: 10px;">LOGO</div>`
            }
          </div>
          <div class="agency-info">
            <p style="font-size: 13px; font-weight: bold; margin: 0">Republic of the Philippines</p>
            <p style="font-size: 16px; font-weight: bold; margin: 0">MUNICIPALITY OF PALUAN</p>
            <p style="font-size: 13px; font-weight: bold; margin: 0">Brgy. 10-Alipaoy, Paluan, Occidental Mindoro</p>
          </div>
        </div>

    </header>

      <div class="main-title">APPLICATION FOR LEAVE</div>

        <!-- SECTIONS 1-5 - NO COLUMN DIVIDERS -->
        <table class="bordered">
          <tr>
            <td style="border-right: none; border-bottom: none; font-size: 13px">1. OFFICE/DEPARTMENT</td>
            <td style="border-left: none; border-right: none; border-bottom: none; font-size: 13px">2. NAME :</td>
            <td style="border-left: none; border-right: none; border-bottom: none; text-align:center; font-size: 13px">(Last)</td>
            <td style="border-left: none; border-right: none; border-bottom: none; text-align:center; font-size: 13px">(First)</td>
            <td style="border-left: none; text-align:center; border-bottom: none; font-size: 13px">(Middle)</td>
          </tr>
          <tr>
            <td style="height: 25px;border-right:none; border-top: none; font-size: 13px;">${department}</td> <!-- Reduced height -->
            <td style="height: 25px;border-left:none; border-right:none; border-top: none; font-size: 13px"></td> <!-- Reduced height -->
            <td style="height: 25px;border-left:none; border-right:none; text-align:center; border-top: none; font-size: 13px">${last_name}</td> <!-- Reduced height -->
            <td style="height: 25px;border-left:none; border-right:none; text-align:center; border-top: none; font-size: 13px">${first_name}</td> <!-- Reduced height -->
            <td style="height: 25px;border-left:none; text-align:center; border-top: none; font-size: 13px">${middle_name}</td> <!-- Reduced height -->
          </tr>
          <tr>
            <td colspan="6" style="height: 15px; border-bottom: none;"></td> <!-- Reduced height -->
          </tr>
          <tr>
            <td style="border-right: none; border-top: none; border-bottom: none; font-size: 13px">
              3. DATE OF FILING <span class="filled-data">${formattedDateFiling}</span>
            </td>
            <td colspan="3" style="border-left: none; border-top: none; border-right: none; border-bottom: none; font-size: 13px">
              4. POSITION <span class="filled-data">${position}</span>
            </td>
            <td style="border-left: none; border-top: none; border-bottom: none; font-size: 13px">
              5. SALARY <span class="filled-data">${salary}</span>
            </td>
          </tr>
        </table>

        <!-- SECTION 6 -->
        <table class="bordered">
          <tr>
            <td colspan="2" style="height: 2px; padding: 0;"></td>
          </tr>

          <tr><td colspan="2" class="section-header" style="font-weight: bold">6. DETAILS OF APPLICATION</td></tr>

          <tr>
            <td colspan="2" style="height: 2px; padding: 0;"></td>
          </tr>
          
          <tr>
            <td style="width: 60%; border-bottom: none; font-size: 13px" class="subsection-header">6.A TYPE OF LEAVE TO BE AVAILED OF</td>
            <td style="width: 40%; border-bottom: none; font-size: 13px" class="subsection-header">6.B DETAILS OF LEAVE</td>
          </tr>

          <tr>
            <td style="vertical-align:top; border-top: none; padding: 8px;"> <!-- Reduced padding -->
              <!-- LEAVE TYPES -->
                <div class="leave-item">
                <span class="checkbox">${leave_type === "Vacation Leave" ? "X" : ""}</span> 
                Vacation Leave <span class="note">(Sec. 51, Rule XVI, Omnibus Rules Implementing E.O. No. 292)</span>
                </div>

                <div class="leave-item">
                <span class="checkbox">${leave_type === "Mandatory/Forced Leave" ? "X" : ""}</span> 
                Mandatory/Forced Leave <span class="note">(Sec. 25, Rule XVI, Omnibus Rules Implementing E.O. No. 292)</span>
                </div>

                <div class="leave-item">
                <span class="checkbox">${leave_type === "Sick Leave" ? "X" : ""}</span> 
                Sick Leave <span class="note">(Sec. 43, Rule XVI, Omnibus Rules Implementing E.O. No. 292)</span>
                </div>

                <div class="leave-item">
                <span class="checkbox">${leave_type === "Maternity Leave" ? "X" : ""}</span> 
                Maternity Leave <span class="note">(R.A. No. 11210 / RRI issued by CSC, DOLE and SSS)</span>
                </div>

                <div class="leave-item">
                <span class="checkbox">${leave_type === "Paternity Leave" ? "X" : ""}</span> 
                Paternity Leave <span class="note">(R.A. No. 8187 / CSC MC No. 71, s. 1998, as amended)</span>
                </div>

                <div class="leave-item">
                <span class="checkbox">${leave_type === "Special Privilege Leave" ? "X" : ""}</span> 
                Special Privilege Leave <span class="note">(Sec. 21, Rule XVI, Omnibus Rules Implementing E.O. No. 292)</span>
                </div>

                <div class="leave-item">
                <span class="checkbox">${leave_type === "Solo Parent Leave" ? "X" : ""}</span> 
                Solo Parent Leave <span class="note">(R.A. No. 8972 / CSC MC No. 8, s. 2004)</span>
                </div>

                <div class="leave-item">
                <span class="checkbox">${leave_type === "Study Leave" ? "X" : ""}</span> 
                Study Leave <span class="note">(Sec. 68, Rule XVI, Omnibus Rules Implementing E.O. No. 292)</span>
                </div>

                <div class="leave-item">
                <span class="checkbox">${leave_type === "10-Day VAWC Leave" ? "X" : ""}</span> 
                10-Day VAWC Leave <span class="note">(R.A. No. 3262 / CSC MC No. 15, s. 2005)</span>
                </div>

                <div class="leave-item">
                <span class="checkbox">${leave_type === "Rehabilitation Privilege" ? "X" : ""}</span> 
                Rehabilitation Privilege <span class="note">(Sec. 55, Rule XVI, Omnibus Rules Implementing E.O. No. 292)</span>
                </div>

                <div class="leave-item">
                <span class="checkbox">${leave_type === "Special Leave Benefits for Women" ? "X" : ""}</span> 
                Special Leave Benefits for Women <span class="note">(R.A. No. 9710 / CSC MC No. 25, s. 2010)</span>
                </div>

                <div class="leave-item">
                <span class="checkbox">${leave_type === "Special Emergency (Calamity) Leave" ? "X" : ""}</span> 
                Special Emergency (Calamity) Leave <span class="note">(CSC MC No. 2, s. 2012, as amended)</span>
                </div>

                <div class="leave-item">
                <span class="checkbox">${leave_type === "Adoption Leave" ? "X" : ""}</span> 
                Adoption Leave <span class="note">(R.A. No. 8552)</span>
                </div>

            <div style="margin-top: 20px;"> <!-- Reduced from 30px -->
              <div class="italic" style="font-size: 13px">Others:</div>
              <div class="underline-below" style="margin-top: 15px; margin-bottom: 15px;"></div> <!-- Reduced margins -->
            </div>

            </td>

            <td style="vertical-align:top; border-top: none; padding: 8px;"> <!-- Reduced padding -->
              <!-- LEAVE DETAILS -->
              <div style="font-size: 13px; margin-bottom: 8px" class="italic mb-4">In case of Vacation/Special Privilege Leave:</div> <!-- Reduced margin -->
              <div style="font-size: 13px; margin-bottom: 8px" class="leave-item"> <!-- Reduced margin -->
                <span class="checkbox">${leaveLocation === "within" ? "X" : ""}</span> Within the Philippines 
                <span class="full-width-underline"></span>
              </div>
              <div class="leave-item" style="font-size: 13px; margin-bottom: 8px"> <!-- Reduced margin -->
                <span class="checkbox">${leaveLocation === "abroad" ? "X" : ""}</span> Abroad (Specify) 
                <span class="full-width-underline">${leaveLocation === "abroad" ? details : ""}</span>
              </div>

              <div style="font-size: 13px; margin-bottom: 8px" class="italic mb-4 mt-8">In case of Sick Leave:</div> <!-- Reduced margin -->
              <div style="margin-bottom: 8px;"> <!-- Reduced margin -->
                <div style="font-size: 13px" class="leave-item">
                  <span class="checkbox">${hospitalIllness ? "X" : ""}</span>
                  In Hospital (Specify Illness) 
                  <span class="full-width-underline">${hospitalIllness}</span>
                </div>
              </div>
              <div style="margin-bottom: 8px;"> <!-- Reduced margin -->
                <div style="font-size: 13px" class="leave-item">
                  <span class="checkbox">${outpatientIllness ? "X" : ""}</span>
                  Out Patient (Specify Illness) 
                  <span class="full-width-underline">${outpatientIllness}</span>
                </div>
              </div>

              <div style="font-size: 13px; margin-bottom: 8px" class="italic mb-4 mt-8">In case of Special Leave Benefits for Women:</div> <!-- Reduced margin -->
              <div style="margin-bottom: 8px;"> <!-- Reduced margin -->
                <div class="leave-item">
                  (Specify Illness) 
                  <span class="full-width-underline">${womenLeaveIllness}</span>
                </div>
                <div style="margin-top: 8px" class="double-underline"></div> <!-- Reduced margin -->
              </div>

              <div style="font-size: 13px; margin-bottom: 8px" class="italic mb-4 mt-8">In case of Study Leave:</div> <!-- Reduced margin -->
              <div class="leave-item" style="font-size: 13px; margin-bottom: 8px"><span class="checkbox"></span> Completion of Master's Degree</div> <!-- Reduced margin -->
              <div class="leave-item" style="font-size: 13px; margin-bottom: 8px"><span class="checkbox"></span> BAR/Board Examination Review</div> <!-- Reduced margin -->

              <div style="font-size: 13px; margin-bottom: 8px" class="italic mb-4 mt-8">Other purpose:</div> <!-- Reduced margin -->
              <div class="leave-item" style="font-size: 13px; margin-bottom: 8px"><span class="checkbox"></span> Monetization of Leave Credits</div> <!-- Reduced margin -->
              <div class="leave-item" style="font-size: 13px; margin-bottom: 8px"><span class="checkbox"></span> Terminal Leave</div> <!-- Reduced margin -->

            </td>
          </tr>

          <tr>
            <td style="font-size: 13px; border-bottom: none">6.C NUMBER OF WORKING DAYS APPLIED FOR</td>
            <td style="font-size: 13px; border-bottom: none">6.D COMMUTATION</td>
          </tr>

          <tr>
            <td style="padding: 8px 8px 15px 8px; border-top: none;"> <!-- Reduced padding -->
              <span class="filled-data">${number_of_days}</span>
              <p style="font-size: 13px; margin-bottom: 20px">INCLUSIVE DATES</p> <!-- Reduced margin -->
              <span class="filled-data">${formattedInclusiveDates}</span>
            </td>

            <td style="padding:6px; border-top: none;"> <!-- Reduced padding -->
              <div style="margin-bottom: 5px; font-size: 13px"><span class="checkbox">${commutationStatus === "Not Requested" ? "X" : ""}</span> Not Requested</div>
              <div style="font-size: 13px"><span class="checkbox">${commutationStatus === "Requested" ? "X" : ""}</span> Requested</div>
              
              <!-- APPLICANT SIGNATURE SECTION -->
              ${applicantSignatureHtml}
              <div class="full-width-underline" style="margin-top: 15px;"></div> <!-- Reduced margin -->
              <div style="font-size: 13px" class="signature">(Signature of Applicant)</div>
            </td>
          </tr>
        </table>

        <!-- SECTION 7 -->
        <table class="bordered">
            <tr>
                <td colspan="2" style="height: 2px; padding: 0;"></td>
            </tr>
            <tr><td colspan="2" class="section-header" style="font-weight: bold">7. DETAILS OF ACTION ON APPLICATION</td></tr>
            <tr>
                <td colspan="2" style="height: 2px; padding: 0;"></td>
            </tr>

          <tr>
            <td style="width:60%; border-bottom: none; font-size: 13px" class="subsection-header">7.A CERTIFICATION OF LEAVE CREDITS</td>
            <td style="width:40%; border-bottom: none; font-size: 13px" class="subsection-header">7.B RECOMMENDATION</td>
          </tr>

          <tr>
             <td style="vertical-align:top; border-top: none; padding: 8px 15px; text-align: center; font-size: 13px"> <!-- Reduced padding -->
                ${showLeaveCredits ? `As of <span class="period-data">${formattedPeriod}</span>` : '<br>'}
                <table style="width:100%; border-collapse:collapse; margin-top:6px;"> <!-- Reduced margin -->
                  <tr>
                    <td style="width:40%;"></td>
                    <td style="width:30%; text-align:center; font-weight:bold; font-size: 13px">Vacation Leave</td>
                    <td style="width:30%; text-align:center; font-weight:bold; font-size: 13px">Sick Leave</td>
                  </tr>
                  <tr>
                    <td style="font-size: 13px">Total Earned</td>
                    <td style="text-align:center;">${displayVacationEarned}</td>
                    <td style="text-align:center;">${displaySickEarned}</td>
                  </tr>
                  <tr>
                    <td style="font-size: 13px">Less this application</td>
                    <td style="text-align:center;">${showLeaveCredits && leave_type === "Vacation Leave" ? number_of_days : '0'}</td>
                    <td style="text-align:center;">${showLeaveCredits && leave_type === "Sick Leave" ? number_of_days : '0'}</td>
                  </tr>
                  <tr>
                    <td style="font-size: 13px">Balance</td>
                    <td style="text-align:center;">${vacationBalance}</td>
                    <td style="text-align:center;">${sickBalance}</td>
                  </tr>
                </table>
                  
                <div class="single-sign" style="text-align:center; margin-top:15px;"> <!-- Reduced margin -->
                  ${hrSignature ? `
                    <div class="compact-signature">
                      <!-- Signature Image -->
                      <img 
                        src="data:image/png;base64,${hrSignature.replace(/^data:image\/(png|jpeg|jpg);base64,/, "")}" 
                        class="signature-image"
                      />
                      <!-- Name BELOW e-sign -->
                      <div class="compact-signature-name">${hrApproverFullName}</div>
                      <!-- Underline BELOW name (still present) -->
                      <div class="compact-signature-underline"></div>
                      <!-- Title BELOW underline -->
                      <div class="compact-signature-title">Administrative Office IV</div>
                    </div>
                  ` : (requesting_role === "admin" && displaySignature) ? `
                    <div class="compact-signature">
                      <!-- Signature Image -->
                      <img 
                        src="data:image/png;base64,${displaySignature.replace(/^data:image\/(png|jpeg|jpg);base64,/, "")}" 
                        class="signature-image"
                      />
                      <!-- Name BELOW e-sign -->
                      <div class="compact-signature-name">${hrApproverFullName}</div>
                      <!-- Underline BELOW name (still present) -->
                      <div class="compact-signature-underline"></div>
                      <!-- Title BELOW underline -->
                      <div class="compact-signature-title">Administrative Office IV</div>
                    </div>
                  ` : `
                    <div class="full-width-underline">${hrApproverFullName}</div>
                    Administrative Office IV
                  `}
                </div>         
              </td>

            <td style="vertical-align:top; padding:6px; border-top: none"> <!-- Reduced padding -->
              <div class="leave-item">
                <span class="checkbox">${currentActionType === "approve" ? "X" : ""}</span> For approval 
              </div>
              <div class="leave-item" style="align-items: flex-start;">
                <span class="checkbox">${currentActionType === "reject" ? "X" : ""}</span> 
                <div style="flex: 1; margin-left: 5px;">
                  For disapproval due to
                  <div class="continuous-underline" style="margin-top: 2px; text-align:justify;">
                    ${currentActionType === "reject" ? effectiveActionRemarks : "&nbsp;"}
                  </div>
                </div>
              </div>

              <div class="single-sign" style="text-align:center; margin-top:15px;"> <!-- Reduced margin -->
                ${officeHeadSignature ? `
                    <div class="compact-signature">
                        <!-- Signature Image -->
                        <img 
                          src="data:image/png;base64,${officeHeadSignature.replace(/^data:image\/(png|jpeg|jpg);base64,/, "")}" 
                          class="signature-image"
                        />
                        <!-- Name BELOW e-sign -->
                        <div class="compact-signature-name">${recommendationName}</div>
                        <!-- Underline BELOW name (still present) -->
                        <div class="compact-signature-underline"></div>
                        <!-- Title BELOW underline -->
                        <div class="compact-signature-title">${recommendationSignatureSection}</div>
                    </div>
                ` : (requesting_role === "office_head" && displaySignature) ? `
                    <div class="compact-signature">
                        <!-- Signature Image -->
                        <img 
                          src="data:image/png;base64,${displaySignature.replace(/^data:image\/(png|jpeg|jpg);base64,/, "")}" 
                          class="signature-image"
                        />
                        <!-- Name BELOW e-sign -->
                        <div class="compact-signature-name">${recommendationName}</div>
                        <!-- Underline BELOW name (still present) -->
                        <div class="compact-signature-underline"></div>
                        <!-- Title BELOW underline -->
                        <div class="compact-signature-title">${recommendationSignatureSection}</div>
                    </div>
                ` : `
                    <div class="full-width-underline">${recommendationName}</div>
                    ${recommendationSignatureSection}
                `}
              </div>            
              </td>
          </tr>

            <tr>
                <td colspan="2" style="height: 2px; padding: 0;"></td>
            </tr>

          <tr>
            <td class="subsection-header" style="border-right: none; border-bottom: none; font-size: 13px">7.C APPROVED FOR:</td>
            <td class="subsection-header" style="border-left: none; border-bottom: none; font-size: 13px">7.D DISAPPROVED DUE TO:</td>
          </tr>

            <tr>
                <td style="border-top: none; border-right: none; border-bottom: none; padding: 0 20px;"> <!-- Reduced padding -->
                  <div style="display: flex; flex-direction: column; margin-top: 8px; gap: 8px;"> <!-- Reduced margins and gap -->
                    <div class="inline-underline">
                        <span class="filled-data" style="width: 80px;">${currentActionType === "approve" ? daysWithPay : ""}</span>
                        <span style="font-size: 13px;"> days with pay</span>
                    </div>
                    <div class="inline-underline">
                        <span class="filled-data" style="width: 80px;">${currentActionType === "approve" ? daysWithoutPay : ""}</span>
                        <span style="font-size: 13px;"> days without pay</span>
                    </div>
                    <div class="inline-underline">
                        <span class="filled-data" style="width: 80px;"></span>
                        <span style="font-size: 13px;"> others (Specify)</span>
                    </div>
                  </div>
                </td>

                <td style="border-top: none; border-left: none; border-bottom: none; padding: 8px;"> <!-- Reduced padding -->
                    <div class="filled-data" style="min-height: 80px; text-align: left; padding: 5px;"> <!-- Reduced height -->
                        ${currentActionType === "reject" ? effectiveActionRemarks : ""}
                    </div>
                </td>
            </tr>

            <tr>
                <td colspan="2" style="height: 40px; border-top: none; padding: 8px 250px; font-size: 14px; font-weight: bold;"> <!-- Reduced height and padding -->
                    <div class="single-sign">
                      ${mayorSignature ? `
                        <div class="compact-signature">
                          <!-- Signature Image -->
                          <img 
                            src="data:image/png;base64,${mayorSignature.replace(/^data:image\/(png|jpeg|jpg);base64,/, "")}" 
                            class="signature-image"
                          />
                          <!-- Name BELOW e-sign -->
                          <div class="compact-signature-name">${displayMayorName}</div>
                          <!-- Underline BELOW name (still present) -->
                          <div class="compact-signature-underline"></div>
                          <!-- Title BELOW underline -->
                          <div class="compact-signature-title">${finalSignatureSection}</div>
                        </div>
                      ` : (requesting_role === "mayor" && displaySignature) ? `
                        <div class="compact-signature">
                          <!-- Signature Image -->
                          <img 
                            src="data:image/png;base64,${displaySignature.replace(/^data:image\/(png|jpeg|jpg);base64,/, "")}" 
                            class="signature-image"
                          />
                          <!-- Name BELOW e-sign -->
                          <div class="compact-signature-name">${displayMayorName}</div>
                          <!-- Underline BELOW name (still present) -->
                          <div class="compact-signature-underline"></div>
                          <!-- Title BELOW underline -->
                          <div class="compact-signature-title">${finalSignatureSection}</div>
                        </div>
                      ` : `
                        <div class="full-width-underline">${displayMayorName}</div>
                        ${finalSignatureSection}
                      `}
                    </div>
                </td>
            </tr>
        </table>

      </div>
    </body>
    </html>
    `;

    // Configure Puppeteer for Render.com
    let browserConfig;
    
    if (process.env.NODE_ENV === 'production' || process.env.RENDER) {
      // Production mode on Render.com
      const executablePath = await chromium.executablePath();
      
      browserConfig = {
        args: chromium.args,
        defaultViewport: chromium.defaultViewport,
        executablePath: executablePath,
        headless: chromium.headless,
        ignoreHTTPSErrors: true,
      };
    } else {
      // Development mode (local)
      browserConfig = {
        headless: true,
        args: [
          "--no-sandbox", 
          "--disable-setuid-sandbox", 
          "--disable-dev-shm-usage",
          "--disable-gpu",
          "--disable-web-security",
          "--disable-features=VizDisplayCompositor",
          "--disable-software-rasterizer"
        ],
        timeout: 120000
      };
    }

    browser = await puppeteer.launch(browserConfig);

    const page = await browser.newPage();
    
    page.setDefaultTimeout(120000);
    page.setDefaultNavigationTimeout(120000);
    
    await page.setRequestInterception(true);
    page.on('request', (req) => {
      if (req.resourceType() === 'image' || req.resourceType() === 'font' || req.resourceType() === 'stylesheet') {
        req.abort();
      } else {
        req.continue();
      }
    });

    const mmToPx = mm => Math.round(mm * 3.7795275591);
    await page.setViewport({ width: mmToPx(215.9), height: mmToPx(355.6) });

    await page.setContent(htmlContent, { 
      waitUntil: "load",
      timeout: 120000 
    });

    await page.waitForFunction(() => document.querySelector('.container'), { timeout: 10000 });

    const pdfBuffer = await page.pdf({
        width: "215.9mm",
        height: "355.6mm",
        printBackground: true,
        margin: { top: "0mm", right: "0mm", bottom: "0mm", left: "0mm" },
    });

    await browser.close();

    if (save_to_db) {
  try {
    console.log(`📄 Saving/updating PDF for leave application ${leave_application_id}...`);
    
    // Format the employee name for the filename
    const formatEmployeeName = (lastName, firstName, middleName) => {
      const middleInitial = middleName && middleName.trim().length > 0 
        ? `${middleName.trim().charAt(0).toUpperCase()}.` 
        : '';
      return `${lastName}, ${firstName} ${middleInitial}`.trim();
    };
    
    const formattedName = formatEmployeeName(last_name, first_name, middle_name);
    const filename = `CS-Form-No6-${formattedName}.pdf`;
    const mimetype = 'application/pdf';
    
    // Determine which action was taken
    const actionTaken = action_type === 'approve' ? 'Approved' : 'Rejected';
    const remarksText = action_remarks || 
      (action_type === 'approve' 
        ? `Approved with ${days_with_pay || 0} days with pay` 
        : 'Rejected');
    
    // First, update the main leave_applications table
    await sql`
      UPDATE leave_applications 
      SET 
        cs_form_pdf = ${pdfBuffer},
        cs_form_filename = ${filename},
        cs_form_mimetype = ${mimetype},
        cs_form_generated_at = NOW(),
        cs_form_generated = true,
        updated_at = NOW()
      WHERE id = ${leave_application_id}
    `;
    
    console.log(`✅ Main leave_applications table updated for ID ${leave_application_id}`);
    
    // Check if there's an existing PDF document for this application
    const existingPDFs = await sql`
      SELECT id, version 
      FROM leave_pdf_documents 
      WHERE leave_application_id = ${leave_application_id}
      ORDER BY version DESC 
      LIMIT 1
    `;
    
    if (existingPDFs.length > 0) {
      // UPDATE existing record (instead of creating new one)
      const existingId = existingPDFs[0].id;
      await sql`
        UPDATE leave_pdf_documents 
        SET 
          pdf_data = ${pdfBuffer},
          pdf_filename = ${filename},
          pdf_mimetype = ${mimetype},
          generated_by = ${user_data?.full_name || 'Unknown'},
          signature_method = ${signature_method || null},
          signature_data = ${signature_data || null},
          updated_at = NOW()
        WHERE id = ${existingId}
      `;
      
      console.log(`✅ Existing PDF record ${existingId} updated`);
    } else {
      const pdfVersion = await sql`
        INSERT INTO leave_pdf_documents (
          leave_application_id,
          pdf_data,
          pdf_filename,
          pdf_mimetype,
          generated_by,
          signature_method,
          signature_data,
          version,
          created_at,
          updated_at
        ) VALUES (
          ${leave_application_id},
          ${pdfBuffer},
          ${filename},
          ${mimetype},
          ${user_data?.full_name || 'Unknown'},
          ${signature_method || null},
          ${signature_data || null},
          1,
          NOW(),
          NOW()
        ) RETURNING id
      `;
      
      console.log(`✅ New PDF record created with ID ${pdfVersion[0]?.id}`);
    }
    
  } catch (dbError) {
    console.error("❌ Error saving PDF to database:", dbError);
  }
}

// Return the PDF
res.setHeader("Content-Type", "application/pdf");

// Format function for download filename
const formatForDownload = (lastName, firstName, middleName) => {
  const middleInitial = middleName && middleName.trim().length > 0 
    ? `${middleName.trim().charAt(0).toUpperCase()}.` 
    : '';
  return `${lastName}, ${firstName} ${middleInitial}`.trim();
};

const downloadFilename = `CS-Form-No6-${formatForDownload(last_name, first_name, middle_name)}.pdf`;

res.setHeader("Content-Disposition", `inline; filename="${downloadFilename}"`);
res.setHeader("Cache-Control", "no-store");
res.send(pdfBuffer);

  } catch (err) {
    console.error("CS Form generation error:", err);
    
    if (browser) {
      try {
        await browser.close();
      } catch (closeError) {
        console.error("Error closing browser:", closeError);
      }
    }
    
    res.status(500).json({
      message: "Internal Server Error",
      error: err.message,
    });
  }
};

// ... rest of the code remains the same ...

// NEW: Add this function to save signatures to the database
export const saveSignature = async (req, res) => {
  try {
    const { leave_application_id, signature_data, requesting_role } = req.body;

    if (!leave_application_id || !signature_data || !requesting_role) {
      return res.status(400).json({
        message: "Leave application ID, signature data, and role are required"
      });
    }

    let updateQuery;
    switch (requesting_role) {
      case 'office_head':
        updateQuery = sql`
          UPDATE leave_applications 
          SET office_head_signature = ${signature_data}
          WHERE id = ${leave_application_id}
          RETURNING id, office_head_signature
        `;
        break;
      case 'admin':
        updateQuery = sql`
          UPDATE leave_applications 
          SET hr_signature = ${signature_data}
          WHERE id = ${leave_application_id}
          RETURNING id, hr_signature
        `;
        break;
      case 'mayor':
        updateQuery = sql`
          UPDATE leave_applications 
          SET mayor_signature = ${signature_data}
          WHERE id = ${leave_application_id}
          RETURNING id, mayor_signature
        `;
        break;
      default:
        return res.status(400).json({
          message: "Invalid role specified"
        });
    }

    const result = await updateQuery;

    if (result.length === 0) {
      return res.status(404).json({
        message: "Leave application not found"
      });
    }

    res.json({
      message: "Signature saved successfully",
      success: true
    });

  } catch (err) {
    console.error("Error saving signature:", err);
    res.status(500).json({
      message: "Internal Server Error",
      error: err.message,
    });
  }
};

export async function getLeavePDFs(req, res) {
  try {
    const { leave_application_id } = req.params;

    const pdfs = await sql`
      SELECT 
        id,
        pdf_filename,
        generated_by,
        generated_at,
        signature_method,
        version
      FROM leave_pdf_documents
      WHERE leave_application_id = ${leave_application_id}
      ORDER BY generated_at DESC
    `;

    res.json(pdfs);
  } catch (error) {
    console.error('❌ Error fetching PDFs:', error);
    res.status(500).json({ error: 'Failed to fetch PDFs' });
  }
}

export async function downloadPDF(req, res) {
  try {
    const { pdf_id } = req.params;

    const [pdf] = await sql`
      SELECT pdf_data, pdf_filename
      FROM leave_pdf_documents
      WHERE id = ${pdf_id}
    `;

    if (!pdf) {
      return res.status(404).json({ error: 'PDF not found' });
    }

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${pdf.pdf_filename}"`);
    res.send(pdf.pdf_data);

  } catch (error) {
    console.error('❌ Error downloading PDF:', error);
    res.status(500).json({ error: 'Failed to download PDF' });
  }
}