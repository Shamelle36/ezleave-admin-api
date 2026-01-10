import express from "express";
import ExcelJS from "exceljs";
import fs from "fs";
import path from "path";
import PDFDocument from "pdfkit";

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

    // 2️⃣ Create PDF using PDFKit
    const doc = new PDFDocument({
      size: 'LETTER',
      margin: 20,
      bufferPages: true
    });

    // Collect PDF data
    const chunks = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    
    // Set fonts
    doc.font('Helvetica');

    // Header Section
    doc.fontSize(14)
       .text('Republic of the Philippines', { align: 'center' })
       .moveDown(0.3);
    doc.text('Province of Occidental Mindoro', { align: 'center' })
       .moveDown(0.3);
    doc.text('Municipality of Paluan', { align: 'center' })
       .moveDown(1.5);
    
    // Title
    doc.fontSize(21)
       .font('Helvetica-Bold')
       .text('EMPLOYEES LEAVE CARD', { align: 'center' })
       .moveDown(2);

    // Employee Information
    doc.fontSize(12)
       .font('Helvetica');
    
    // Name and Office
    doc.text(`NAME: ${employee.last_name}, ${employee.first_name} ${employee.middle_name || ''}`, 50, doc.y);
    doc.text(`OFFICE: ${employee.office || 'MO'}`, 400, doc.y);
    doc.moveDown(1);
    
    // Position and Status
    doc.text(`POSITION: ${employee.position || 'Administrative Aide I'}`, 50, doc.y);
    doc.text(`STATUS: ${employee.employment_status || 'Permanent'}`, 400, doc.y);
    doc.moveDown(2);

    // Table Header
    const startX = 50;
    const startY = doc.y;
    const rowHeight = 25;
    const colWidths = [60, 120, 40, 40, 40, 40, 40, 40, 40, 40, 80]; // 11 columns
    
    // Draw table borders
    let currentX = startX;
    let currentY = startY;
    
    // Column headers (simplified version)
    const headers = [
      "PERIOD",
      "PARTICULARS",
      "VL\nEARNED",
      "VL\nUSED",
      "VL\nBALANCE",
      "VL\nWOP",
      "SL\nEARNED",
      "SL\nUSED",
      "SL\nBALANCE",
      "SL\nWOP",
      "REMARKS"
    ];
    
    // Draw header row
    doc.fontSize(9).font('Helvetica-Bold');
    headers.forEach((header, i) => {
      doc.rect(currentX, currentY, colWidths[i], rowHeight).stroke();
      doc.text(header, currentX + 5, currentY + 8, {
        width: colWidths[i] - 10,
        align: 'center'
      });
      currentX += colWidths[i];
    });
    
    // Data rows
    doc.fontSize(8).font('Helvetica');
    leaveCards.forEach((lc, rowIndex) => {
      currentY += rowHeight;
      currentX = startX;
      
      const rowData = [
        lc.period || "",
        lc.particulars || "",
        lc.vl_earned || "",
        lc.vl_used || "",
        lc.vl_balance || "",
        "", // VL WOP (empty)
        lc.sl_earned || "",
        lc.sl_used || "",
        lc.sl_balance || "",
        "", // SL WOP (empty)
        lc.remarks || ""
      ];
      
      // Draw cells for this row
      rowData.forEach((cell, i) => {
        doc.rect(currentX, currentY, colWidths[i], rowHeight).stroke();
        doc.text(cell.toString(), currentX + 5, currentY + 8, {
          width: colWidths[i] - 10,
          align: i === 1 || i === 10 ? 'left' : 'center' // Left align for particulars and remarks
        });
        currentX += colWidths[i];
      });
      
      // Check for page break
      if (currentY > 700) {
        doc.addPage();
        currentY = 50;
      }
    });

    // Add footer
    doc.addPage();
    doc.fontSize(10)
       .text('--- End of Leave Card ---', { align: 'center', underline: true })
       .moveDown(1);
    
    // Finalize PDF
    doc.end();

    // Wait for PDF to finish
    const pdfBuffer = await new Promise((resolve) => {
      doc.on('end', () => {
        const buffer = Buffer.concat(chunks);
        resolve(buffer);
      });
    });

    // 3️⃣ Send back PDF
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `attachment; filename="${employee.last_name}, ${employee.first_name}.pdf"`);
    res.send(pdfBuffer);

    // 4️⃣ Cleanup Excel file
    try { 
      fs.unlinkSync(tempExcelPath); 
    } catch(e) { 
      console.log("Cleanup error:", e.message);
    }

  } catch (error) {
    console.error("❌ Export failed:", error);
    res.status(500).json({ 
      error: "PDF generation failed",
      message: error.message 
    });
  }
});

export default router;