import multer from "multer";
import XLSX from "xlsx";
import fs from "fs";
import sql from "../config/db.js";
import { sendPushToUser } from "../utils/fcm.js";
import { sendAndSaveNotification } from "../utils/notificationService.js";

// 📁 Multer config
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads/"),
  filename: (req, file, cb) => cb(null, Date.now() + "-" + file.originalname),
});
export const upload = multer({ storage });


// 📤 Upload Leave Card
export const uploadLeaveCard = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file uploaded" });

    const workbook = XLSX.readFile(req.file.path);
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const nameCell = sheet["B8"]?.v?.trim();

    if (!nameCell) {
      fs.unlinkSync(req.file.path);
      return res.status(400).json({ error: "Employee name not found in cell B8" });
    }

    console.log(`📄 Raw Name Cell: ${nameCell}`);

    // 🧾 Parse employee name
    const [lastNameRaw, firstNameRaw] = nameCell.split(",").map(s => s.trim());
    const lastName = lastNameRaw || "";
    const firstName = (firstNameRaw || "").split(" ")[0]; // only the first word (ignores middle initial, suffix, etc.)

    console.log("🧾 Parsed Name ->", { lastName, firstName });

    // 🔍 Match employee (case-insensitive, flexible first name)
    const employee = await sql`
      SELECT id, first_name, last_name
      FROM employee_list
      WHERE LOWER(TRIM(last_name)) = LOWER(TRIM(${lastName}))
        AND LOWER(TRIM(first_name)) LIKE LOWER(TRIM(${firstName}) || '%')
      LIMIT 1;
    `;

    if (!employee.length) {
      fs.unlinkSync(req.file.path);
      console.log(`❌ No matching employee found for ${nameCell}`);
      return res.json({ message: `No matching employee found for ${nameCell}`, inserted: 0, skipped: 1 });
    }

    const empId = employee[0].id;
    console.log(`✅ Matched employee: ${employee[0].last_name}, ${employee[0].first_name} (ID: ${empId})`);

    // 📊 Convert sheet rows
    const rows = [];
    const range = XLSX.utils.decode_range(sheet["!ref"]);

    for (let R = 12; R <= range.e.r; ++R) { // starts from row 13
      const row = {};
      for (let C = 0; C <= 10; ++C) { // A-K
        const cellRef = XLSX.utils.encode_cell({ r: R, c: C });
        row[C] = sheet[cellRef]?.v ?? "";
      }
      rows.push(row);
    }

    // 🧮 Helper function
    const toNumberOrNull = val => {
      if (val === "" || val == null) return null;
      return /^[0-9]+(\.[0-9]+)?$/.test(val.toString().trim()) ? Number(val) : null;
    };

    // 🧱 Build leave values
    const leaveValues = rows
      .map(row => {
        const isEmpty = Object.values(row).every(v => v === "" || v == null);
        if (isEmpty) return null;

        const period = row[0]?.toString().trim() || null;
        const particulars = row[1]?.toString().trim() || null;
        const absUndWpRaw = row[5]?.toString().trim() || null;

        const vlEarned  = toNumberOrNull(row[2]);
        let vlUsed      = row[3]?.toString().trim() || null;
        const vlBalance = toNumberOrNull(row[4]);
        const slEarned  = toNumberOrNull(row[6]);
        let slUsed      = row[7]?.toString().trim() || null;
        const slBalance = toNumberOrNull(row[8]);
        let remarks     = row[10]?.toString().trim() || null;

        // Gather non-numeric text from numeric columns
        const nonNumericExtra = [2,4,6,8]
          .map(i => row[i])
          .filter(v => v && !/^[0-9]+(\.[0-9]+)?$/.test(v.toString().trim()))
          .map(v => v.toString().trim());

        // Merge particulars with extra text
        const mergedParticulars = [particulars, ...nonNumericExtra].filter(Boolean).join(" | ");

        // Append AbsUndW/P
        if (absUndWpRaw) {
          if (!vlUsed) vlUsed = absUndWpRaw;
          remarks = remarks
            ? `${remarks} | AbsUndW/P: ${absUndWpRaw}`
            : `AbsUndW/P: ${absUndWpRaw}`;
        }

        return [
          empId,
          period,
          mergedParticulars || null,
          vlEarned,
          vlUsed,
          vlBalance,
          slEarned,
          slUsed,
          slBalance,
          remarks
        ];
      })
      .filter(Boolean);

    if (!leaveValues.length) {
      fs.unlinkSync(req.file.path);
      return res.json({ message: `No valid leave entries found for ${nameCell}`, inserted: 0, skipped: rows.length });
    }

    // 💾 Insert into DB
    let inserted = 0;
    for (const vals of leaveValues) {
      await sql`
        INSERT INTO leave_cards (
          employee_id, period, particulars, vl_earned, vl_used, vl_balance,
          sl_earned, sl_used, sl_balance, remarks
        ) VALUES (
          ${vals[0]}, ${vals[1]}, ${vals[2]}, ${vals[3]}, ${vals[4]}, ${vals[5]},
          ${vals[6]}, ${vals[7]}, ${vals[8]}, ${vals[9]}
        );
      `;
      inserted++;
    }

    fs.unlinkSync(req.file.path);
    const skipped = rows.length - inserted;

    res.json({
      message: `✅ Leave card uploaded successfully for ${lastName}, ${firstName}`,
      inserted,
      skipped
    });

  } catch (err) {
    console.error("❌ Error processing leave card upload:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
};


// 📋 Get Employee with Leave Balances
export const getEmployeeWithLeaveBalances = async (req, res) => {
  try {
    const empId = req.params.id;

    const [employee] = await sql`
      SELECT *
      FROM employee_list
      WHERE id = ${empId}
      LIMIT 1;
    `;
    if (!employee) return res.status(404).json({ message: "Employee not found" });

    const leaveCards = await sql`
      SELECT period, particulars, vl_earned, vl_used, vl_balance,
             sl_earned, sl_used, sl_balance, remarks
      FROM leave_cards
      WHERE employee_id = ${empId}
      ORDER BY id;
    `;

    // Compute cumulative used
    const totalVlUsed = leaveCards.reduce((sum, row) => sum + (parseFloat(row.vl_used) || 0), 0);
    const totalSlUsed = leaveCards.reduce((sum, row) => sum + (parseFloat(row.sl_used) || 0), 0);

    // Get latest balance (latest row)
    const latestCard = leaveCards[leaveCards.length - 1] || {};
    const vlBalance = latestCard.vl_balance || 0;
    const slBalance = latestCard.sl_balance || 0;

    res.json({
      employee,
      leaveCards,
      summary: {
        vl: { used: totalVlUsed, balance: vlBalance },
        sl: { used: totalSlUsed, balance: slBalance }
      }
    });
  } catch (err) {
    console.error("❌ Error fetching employee info:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
};

// 🕒 Auto Earn Leave Credits (Runs Once Per Month)
export const autoEarnLeaveCredits = async () => {
  try {
    console.log("⏳ Running monthly leave credit job...");

    // Get all employees
    const employees = await sql`SELECT id, user_id, first_name, last_name FROM employee_list`;

    const today = new Date();

    // Compute PREVIOUS month
    let year = today.getFullYear();
    let month = today.getMonth(); // previous month (0–11)

    if (month === 0) {
      month = 12;
      year = year - 1;
    }

    // month is now 1–12
    const lastDay = new Date(year, month, 0).getDate();
    const period = `${month}/1-${lastDay}/${year}`;

    for (const emp of employees) {
      const empId = emp.id;

      // Check last entry
      const last = await sql`
        SELECT period
        FROM leave_cards
        WHERE employee_id = ${empId}
        ORDER BY id DESC
        LIMIT 1;
      `;

      // Skip if already earned
      if (last.length > 0 && last[0].period === period) {
        console.log(`⚠️ Already credited for ${period} | Emp: ${empId}`);
        continue;
      }

      // Get current balances
      const lastBalance = await sql`
        SELECT vl_balance, sl_balance
        FROM leave_cards
        WHERE employee_id = ${empId}
        ORDER BY id DESC
        LIMIT 1;
      `;

      if (lastBalance.length === 0) {
        console.log(`⏭ Skipped — No leave card record yet | Emp: ${empId}`);
        continue;
      }

      const vlBalance = Number(lastBalance[0].vl_balance);
      const slBalance = Number(lastBalance[0].sl_balance);

      const newVlBalance = vlBalance + 1.25;
      const newSlBalance = slBalance + 1.25;

      // Insert leave credit
      await sql`
        INSERT INTO leave_cards (
          employee_id, period, particulars,
          vl_earned, vl_used, vl_balance,
          sl_earned, sl_used, sl_balance,
          remarks
        )
        VALUES (
          ${empId}, ${period}, NULL,
          1.25, NULL, ${newVlBalance},
          1.25, NULL, ${newSlBalance},
          NULL
        );
      `;

      console.log(`✅ Credited 1.25 VL/SL for Emp ID: ${empId}`);

      // === PUSH NOTIFICATION TO EMPLOYEE ===
      const messageTitle = "Monthly Leave Credits Added 🎉";
      const messageBody = `Hi ${emp.first_name}, your VL and SL for ${period} have been credited: 1.25 each.`;

      try {
        // 1️⃣ Send push notification (FCM)
        const pushResult = await sendPushToUser(
          emp.user_id,
          messageTitle,
          messageBody,
          {
            type: 'leave_credited',
            employee_id: empId,
            period,
            vl_earned: 1.25,
            sl_earned: 1.25,
            screen: 'leave_status'
          }
        );

        console.log("📱 Push notification result:", pushResult);

        // 2️⃣ Save notification to DB
        await sql`
          INSERT INTO notifications (
            user_id, title, message, created_at
          )
          VALUES (
            ${emp.user_id},
            ${messageTitle},
            ${messageBody},
            NOW()
          );
        `;

        console.log(`🔔 Notification sent and saved for Emp ID: ${empId}`);
      } catch (notifError) {
        console.error("❌ Error sending notification for Emp ID:", empId, notifError);
      }
    }

    console.log("🎉 Monthly leave credit job completed.");

  } catch (err) {
    console.error("❌ Auto earn error:", err);
  }
};
