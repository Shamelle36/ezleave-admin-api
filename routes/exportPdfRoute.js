import express from "express";
import ExcelJS from "exceljs";
import fs from "fs";
import path from "path";
import htmlPdf from "html-pdf-node";

const router = express.Router();

router.post("/export-pdf", async (req, res) => {
  try {
    const { employee, leaveCards } = req.body;

    // 1️⃣ Create workbook (for Excel download)
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet("Leave Card");

    // Header
    sheet.mergeCells("A1:I1");
    sheet.getCell("A1").value = "Republic of the Philippines";
    sheet.mergeCells("A2:I2");
    sheet.getCell("A2").value = "Province of Occidental Mindoro";
    sheet.mergeCells("A3:I3");
    sheet.getCell("A3").value = "Municipality of Paluan";
    sheet.mergeCells("A5:I5");
    sheet.getCell("A5").value = "EMPLOYEE LEAVE CARD";

    // Employee info
    sheet.addRow([]);
    sheet.addRow(["NAME:", `${employee.last_name}, ${employee.first_name} ${employee.middle_name || ""}`, "", "", "", "", "OFFICE:", employee.office || "MO"]);
    sheet.addRow(["POSITION:", employee.position || "Administrative Aide I", "", "", "", "", "STATUS:", employee.employment_status || "Permanent"]);
    sheet.addRow([]);

    // Table header (simple Excel fallback)
    sheet.addRow(["PERIOD", "PARTICULARS", "VL Earned", "VL Used", "VL Balance", "SL Earned", "SL Used", "SL Balance", "Remarks"]);

    // Leave data (Excel)
    leaveCards.forEach((lc) => {
      sheet.addRow([
        lc.period || "",
        lc.particulars || "",
        lc.vl_earned || "",
        lc.vl_used || "",
        lc.vl_balance || "",
        lc.sl_earned || "",
        lc.sl_used || "",
        lc.sl_balance || "",
        lc.remarks || "",
      ]);
    });

    const tempDir = path.resolve("temp");
    if (!fs.existsSync(tempDir)) fs.mkdirSync(tempDir, { recursive: true });
    const tempExcelPath = path.resolve(`${tempDir}/${employee.last_name}_${employee.first_name}.xlsx`);
    await workbook.xlsx.writeFile(tempExcelPath);

    // 2️⃣ Build styled HTML (pixel-like layout; vertical headers rendered letter-per-line)
    const html = `
<html>
<head>
  <meta charset="utf-8" />
  <style>
    /* Reset & base */
    * { box-sizing: border-box; }
    body {
      font-family: Arial, sans-serif;
      font-size: 11px;
      margin: 0;
      padding: 20px;
    }

    .center {
      text-align: center;
    }

    h4 { margin: 0; font-weight: normal; font-size: 14px; }
    h2 {
      margin: 8px 0 12px 0;
      font-size: 21px;
      font-weight: 700;
      letter-spacing: 1px;
    }

    /* Employee info */
    .info {
      width: 100%;
      margin-bottom: 8px;
      font-size: 12px;
    }
    .info td { padding: 3px 4px; vertical-align: bottom; }
    .label { width: 70px; font-weight: 700; }
    .underline {
      display: inline-block;
      border-bottom: 1px solid #000;
      min-width: 180px;
      height: 14px;
      vertical-align: bottom;
    }
    .small-line { min-width: 80px; }

    

    /* Leave table */
    table.leave {
      width: 100%;
      border-collapse: collapse;
      table-layout: fixed;
      font-size: 10.5px;
    }
    table.leave th, table.leave td {
      border: 1px solid #000;
      padding: 4px 6px;
      vertical-align: middle;
      word-wrap: break-word;
    }

    /* Vertical header (letter per line) */
    .vertical {
      font-size: 10px;
      line-height: 10px;
      text-align: center;
      padding: 6px 3px;
      white-space: nowrap;
      letter-spacing: 2px;
    }
    /* narrow column class */
    .col-narrow { width: 100px; }

    /* Particulars column left-aligned */
    .left { text-align: left; padding-left: 6px; font-size: 10px; }

    .remarks { text-align: left; padding-left: 6px; font-size: 9px; }

    /* make header block heights similar to screenshot */
    thead th { background: transparent; }

    /* Smaller font for multi-line small captions */
    .tiny { font-size: 10px; }

    /* Force word-break for long remarks */
    .remarks { word-break: break-word; }

    .fontSize { font-size: 14px; }

    
    /* Add bottom margin for every page */
    @page {
    margin-bottom: 20px;
    margin-top: 20px;
    }


  </style>
</head>
<body>
  <div class="center">
    <h4>Republic of the Philippines</h4>
    <h4>Province of Occidental Mindoro</h4>
    <h4>Municipality of Paluan</h4>
    <h2 style="margin-top: 50px; margin-bottom: 20px">EMPLOYEES LEAVE CARD</h2>
  </div>

  <!-- Employee info -->
  <table class="info">
    <tr>
      <td class="label">NAME:</td>
      <td><span class="underline">${employee.last_name}, ${employee.first_name} ${employee.middle_name || ""}</span></td>

      <td style="width:40px;"></td>

      <td class="label">OFFICE:</td>
      <td><span class="underline small-line">${employee.office || "MO"}</span></td>
    </tr>

    <tr>
      <td class="label">POSITION:</td>
      <td><span class="underline">${employee.position || "Administrative Aide I"}</span></td>

      <td></td>

      <td class="label">FTD:</td>
      <td><span class="underline small-line"></span></td>

      <td style="width:20px;"></td>

      <td class="label">STATUS:</td>
      <td><span class="underline small-line">${employee.employment_status || "Permanent"}</span></td>
    </tr>
  </table>

    <table class="leave">
    <tbody>
        <!-- Header row only once -->
        <tr>
        <td class="vertical col-narrow" rowspan="3">${'PERIOD'.split('').join('<br/>')}</td>
        <td rowspan="3" style="width:120px; text-align: center">PARTICULARS</td>

        <td style="text-align: center" colspan="4">VACATION LEAVE</td>
        <td style="text-align: center" colspan="4">SICK LEAVE</td>

        <td rowspan="3" style="width:90px; text-align: center">REMARKS</td>
        </tr>

        <tr>
            <td class="col-narrow" rowspan="2" style="text-align: center">EARNED</td>
            <td class="tiny" style="line-height: 10px; text-align: center">ABS. UND. W/P</td>
            <td class="col-narrow" rowspan="2" style="text-align: center; width: 60px">BALANCE</td>
            <td class="tiny" style="line-height: 10px; text-align: center">ABS. UND. WOP</td>

            <td class="col-narrow" rowspan="2" style="text-align: center">EARNED</td>
            <td class="tiny" style="text-align: center">ABS.<br/>UND.<br/>W/P</td>
            <td class="col-narrow" rowspan="2" style="text-align: center; width: 60px">BALANCE</td>
            <td class="tiny" style="text-align: center">ABS.<br/>UND.<br/>WOP</td>
        </tr>

        <tr>
        <td></td><td></td><td></td><td></td>
        </tr>

        <!-- Leave data -->
        ${leaveCards.map(lc => `
        <tr>
        <td class="tiny" style="white-space: nowrap;">${lc.period || ""}</td>
        <td class="left">${lc.particulars || ""}</td>

        <td class="tiny fontSize">${lc.vl_earned ?? ""}</td>
        <td class="tiny fontSize">${lc.vl_used ?? ""}</td>
        <td class="tiny fontSize" style="width: 60px">${lc.vl_balance ?? ""}</td>
        <td class="tiny fontSize"></td>

        <td class="tiny fontSize">${lc.sl_earned ?? ""}</td>
        <td class="tiny fontSize">${lc.sl_used ?? ""}</td>
        <td class="tiny fontSize" style="width: 60px">${lc.sl_balance ?? ""}</td>
        <td class="tiny fontSize"></td>

        <td class="remarks">${lc.remarks || ""}</td>
        </tr>
        `).join("")}
    </tbody>
    </table>

</body>
</html>
`;

    // 3️⃣ Convert HTML → PDF using html-pdf-node (Render compatible)
    const tempPdfPath = tempExcelPath.replace(".xlsx", ".pdf");
    
    const options = {
      format: 'Letter',
      printBackground: true,
      landscape: false,
      margin: {
        top: "0",
        bottom: "0",
        left: "0",
        right: "0"
      }
    };

    const file = { content: html };
    
    // Generate PDF buffer
    const pdfBuffer = await htmlPdf.generatePdf(file, options);
    
    // Save to file (optional - only if you need the file)
    fs.writeFileSync(tempPdfPath, pdfBuffer);

    // 4️⃣ Send back PDF
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `attachment; filename="${employee.last_name}, ${employee.first_name}.pdf"`);
    res.send(pdfBuffer);

    // cleanup
    try { fs.unlinkSync(tempExcelPath); } catch(e){/*ignore*/ }
    try { fs.unlinkSync(tempPdfPath); } catch(e){/*ignore*/ }

  } catch (error) {
    console.error("❌ Export failed:", error);
    res.status(500).send("Internal Server Error");
  }
});

export default router;