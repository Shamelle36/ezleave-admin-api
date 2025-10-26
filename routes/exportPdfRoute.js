import express from "express";
import ExcelJS from "exceljs";
import fs from "fs";
import path from "path";
import puppeteer from "puppeteer";

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

    // Table header
    sheet.addRow(["PERIOD", "PARTICULARS", "VL Earned", "VL Used", "VL Balance", "SL Earned", "SL Used", "SL Balance", "Remarks"]);

    // Leave data
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

    const tempExcelPath = path.resolve(`temp/${employee.last_name}_${employee.first_name}.xlsx`);
    await workbook.xlsx.writeFile(tempExcelPath);

    // 2️⃣ Build styled HTML (exact layout like your uploaded image)
    const html = `
    
        <html>
        <head>
            <style>
            body {
                font-family: Arial, sans-serif;
                font-size: 11px;
            }
            h3, h4, h2 {
                text-align: center;
                margin: 0;
                padding: 0;
                font-size: 14px;
                font-weight: normal;
            }
            h2 {
                font-size: 30px;
                font-weight: bold;
                margin-top: 50px;
                margin-bottom: 50px;
                text-transform: uppercase;
                fon-family: 'Arial Black', sans-serif;
                font-weight: bold;
            }
            table {
                border-collapse: collapse;
                width: 100%;
                table-layout: fixed;
                margin-top: 12px;
            }
            th, td {
                border: 1px solid #000;
                padding: 3px 4px;
                text-align: center;
                vertical-align: middle;
                word-wrap: break-word;
            }
            .vertical {
                font-size: 8px;
            }

            /* Employee Info Section */
            .info-table {
                width: 100%;
                border: none;
                margin-bottom: 12px;
                font-size: 15px;
            }
            .info-table td {
                border: none;
                padding: 4px 6px;
                vertical-align: bottom;
                text-align: left;
            }
            .label {
                font-weight: bold;
                width: 70px;
                white-space: nowrap;
                
            }
            .underline {
                display: inline-block;
                border-bottom: 1px solid #000;
                height: 14px;
                min-width: 180px;
                vertical-align: bottom;
                margin-left: 6px;
            }
            .small-line {
                min-width: 100px;
            }
            .column {
                font-weight: normal;
                font-size: 12px;
            },
            .value {
                font-size: 10px;
            }
            </style>
        </head>
        <body>
            <h4>Republic of the Philippines</h4>
            <h4>Province of Occidental Mindoro</h4>
            <h4>Municipality of Paluan</h4>
            <h2>EMPLOYEES LEAVE CARD</h2>

            <!-- LEFT-ALIGNED INFO SECTION -->
            <table class="info-table">
            <tr>
                <td class="label">NAME:</td>
                <td><span class="underline">${employee.last_name}, ${employee.first_name} ${employee.middle_name || ""}</span></td>
                <td style="width:50px;"></td>
                <td class="label">OFFICE:</td>
                <td><span class="underline">${employee.office || "MO"}</span></td>
            </tr>
            <tr>
                <td class="label">POSITION:</td>
                <td><span class="underline">${employee.position || "Administrative Aide I"}</span></td>
                <td style="width:50px;"></td>
                <td class="label">FTD:</td>
                <td><span class="underline small-line"></span></td>
                <td
                    class="label">STATUS: <span class="underline">${employee.employment_status || "Permanent"}<span>
                </td>
                    </tr>
            </table>

            <!-- LEAVE TABLE -->
            <table>
            <thead>
                <tr>
                <th rowspan="3" class="vertical">PERIOD</th>
                <th rowspan="3" class="vertical">PARTICULARS</th>
                <th colspan="4" class="column">VACATION LEAVE</th>
                <th colspan="4" class="column">SICK LEAVE</th>
                <th rowspan="3" class="column">REMARKS</th>
                </tr>
                <tr>
                <th rowspan="2" class="column">EARNED</th>
                <th class="column">ABS.<br>UND.<br>W/P</th>
                <th rowspan="2" class="column">BALANCE</th>
                <th class="column">ABS.<br>UND.<br>WOP</th>
                <th rowspan="2" class="column">EARNED</th>
                <th class="column">ABS.<br>UND.<br>W/P</th>
                <th rowspan="2" class="column">BALANCE</th>
                <th class="column">ABS.<br>UND.<br>WOP</th>
                </tr>
                <tr><th></th><th></th><th></th><th></th></tr>
            </thead>
            <tbody>
                ${leaveCards.map(lc => `
                <tr>
                    <td  class="value">${lc.period || ""}</td>
                    <td  style="text-align:left;">${lc.particulars || ""}</td>
                    <td>${lc.vl_earned ?? ""}</td>
                    <td>${lc.vl_used ?? ""}</td>
                    <td>${lc.vl_balance ?? ""}</td>
                    <td></td>
                    <td>${lc.sl_earned ?? ""}</td>
                    <td>${lc.sl_used ?? ""}</td>
                    <td>${lc.sl_balance ?? ""}</td>
                    <td></td>
                    <td style="text-align:left; font-size: 8px">${lc.remarks || ""}</td>
                </tr>
                `).join("")}
            </tbody>
            </table>
        </body>
        </html>
    `;


    // 3️⃣ Convert HTML → PDF using Puppeteer
    const tempPdfPath = tempExcelPath.replace(".xlsx", ".pdf");
    const browser = await puppeteer.launch({ headless: true });
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: "networkidle0" });
    await page.pdf({
      path: tempPdfPath,
      format: "A4",
      printBackground: true,
      landscape: false,
      margin: { top: "0.6in", bottom: "0.6in", left: "0.5in", right: "0.5in" },
    });
    await browser.close();

    // 4️⃣ Send back PDF
    const fileBuffer = fs.readFileSync(tempPdfPath);
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `attachment; filename="${employee.last_name}, ${employee.first_name}.pdf"`);
    res.send(fileBuffer);

    fs.unlinkSync(tempExcelPath);
    fs.unlinkSync(tempPdfPath);
  } catch (error) {
    console.error("❌ Export failed:", error);
    res.status(500).send("Internal Server Error");
  }
});

export default router;
