import multer from "multer";
import XLSX from "xlsx";
import fs from "fs";
import sql from "../config/db.js";

// Multer config
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads/"),
  filename: (req, file, cb) => cb(null, Date.now() + "-" + file.originalname),
});
export const upload = multer({ storage });

// Upload Leave Card
export const uploadLeaveCard = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file uploaded" });

    const workbook = XLSX.readFile(req.file.path);
    const sheet = workbook.Sheets[workbook.SheetNames[0]];

    // Parse employee name from B8
    const nameCell = sheet["B8"]?.v?.trim();
    if (!nameCell) {
      fs.unlinkSync(req.file.path);
      return res.status(400).json({ error: "Employee name not found in B8" });
    }

    const [lastNameRaw, firstNameRaw] = nameCell.split(",").map(s => s.trim());
    const lastName = lastNameRaw || "";
    const firstName = (firstNameRaw || "").split(" ").slice(0, 2).join(" ");

    console.log("🧾 Parsed Name ->", { lastName, firstName });

    // Match employee
    const employee = await sql`
      SELECT id, first_name, last_name
      FROM employee_list
      WHERE LOWER(TRIM(last_name)) = LOWER(TRIM(${lastName}))
        AND LOWER(first_name) LIKE LOWER(${firstName} || '%')
      LIMIT 1;
    `;

    if (!employee.length) {
      fs.unlinkSync(req.file.path);
      console.log(`❌ No matching employee found for ${nameCell}`);
      return res.json({ message: `No matching employee found for ${nameCell}`, inserted: 0, skipped: 1 });
    }

    const empId = employee[0].id;
    console.log(`✅ Matched employee: ${employee[0].last_name}, ${employee[0].first_name} (ID: ${empId})`);

    // Convert sheet to array of rows
    const rows = [];
    const range = XLSX.utils.decode_range(sheet["!ref"]);
    for (let R = 12; R <= range.e.r; ++R) { // row 13+
      const row = {};
      for (let C = 0; C <= 10; ++C) { // columns A-K
        const cellAddress = { r: R, c: C };
        const cellRef = XLSX.utils.encode_cell(cellAddress);
        row[C] = sheet[cellRef]?.v ?? "";
      }
      rows.push(row);
    }

    // Build leaveValues
    const leaveValues = rows
      .map(row => {
        const isEmptyRow = Object.values(row).every(cell => cell === "" || cell == null);
        if (isEmptyRow) return null;

        const period = row[0] ? row[0].toString().trim() : null;
        const particulars = row[1] ? row[1].toString().trim() : null;
        const absUndWpRaw = row[5] ? row[5].toString().trim() : null;

        // Helper: only numeric values
        const toNumberOrNull = val => {
          if (val === "" || val == null) return null;
          return /^[0-9]+(\.[0-9]+)?$/.test(val.toString().trim()) ? Number(val) : null;
        };

        const vlEarned  = toNumberOrNull(row[2]);
        let vlUsed      = row[3] ? row[3].toString().trim() : null; // keep text
        const vlBalance = toNumberOrNull(row[4]);
        const slEarned  = toNumberOrNull(row[6]);
        let slUsed      = row[7] ? row[7].toString().trim() : null; // keep text
        const slBalance = toNumberOrNull(row[8]);

        // Non-numeric text from numeric columns (exclude vl_used & sl_used)
        const nonNumericFromNumericCols = [2,4,6,8]
          .map(i => row[i])
          .filter(v => v != null && v !== "" && !/^[0-9]+(\.[0-9]+)?$/.test(v.toString().trim()))
          .map(v => v.toString().trim());

        // Original remarks
        let remarks = row[10] ? row[10].toString().trim() : null;

        // Put AbsUndW/P into vl_used if empty (or sl_used if relevant)
        if (absUndWpRaw) {
          if (!vlUsed) vlUsed = absUndWpRaw; // here assuming vlUsed
          remarks = remarks ? `${remarks} | AbsUndW/P: ${absUndWpRaw}` : `AbsUndW/P: ${absUndWpRaw}`;
        }

        // Merge particulars with non-numeric values (excluding vl_used/sl_used)
        const mergedParticulars = [particulars, ...nonNumericFromNumericCols].filter(Boolean).join(" | ");

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

    // Insert into DB
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
    res.json({ message: `✅ Leave card uploaded for ${lastName}, ${firstName}`, inserted, skipped });

  } catch (err) {
    console.error("❌ Error processing leave card upload:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
};




// 📋 Get employee with leave balances
export const getEmployeeWithLeaveBalances = async (req, res) => {
  try {
    const empId = req.params.id;

    // Fetch all employee info
    const employeeResult = await sql`
      SELECT *
      FROM employee_list
      WHERE id = ${empId}
      LIMIT 1
    `;

    if (!employeeResult[0]) 
      return res.status(404).json({ message: "Employee not found" });

    const employee = employeeResult[0];

    // Fetch all leave card entries
    const leaveCards = await sql`
      SELECT period, particulars, vl_earned, vl_used, vl_balance,
             sl_earned, sl_used, sl_balance, remarks
      FROM leave_cards
      WHERE employee_id = ${empId}
      ORDER BY id
    `;

    res.json({ employee, leaveCards });
  } catch (err) {
    console.error("❌ Error fetching employee info:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
};
