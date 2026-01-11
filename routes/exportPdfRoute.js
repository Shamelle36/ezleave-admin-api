import express from "express";
import ExcelJS from "exceljs";
import fs from "fs";
import path from "path";
import PDFDocument from "pdfkit";

const router = express.Router();

router.post("/export-pdf", async (req, res) => {
  let pdfDoc = null;
  
  try {
    const { employee, leaveCards } = req.body;

    // 1️⃣ Create workbook (for Excel download - kept as backup)
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
    const tempPdfPath = tempExcelPath.replace(".xlsx", ".pdf");
    pdfDoc = new PDFDocument({ 
      size: 'letter',
      margins: { top: 20, bottom: 20, left: 20, right: 20 },
      bufferPages: true
    });

    // Pipe PDF to file and response
    const writeStream = fs.createWriteStream(tempPdfPath);
    pdfDoc.pipe(writeStream);
    pdfDoc.pipe(res);

    // Set up PDF document
    pdfDoc.font('Helvetica');

    // Header Section
    pdfDoc.fontSize(14).text('Republic of the Philippines', { align: 'center' });
    pdfDoc.fontSize(14).text('Province of Occidental Mindoro', { align: 'center' });
    pdfDoc.fontSize(14).text('Municipality of Paluan', { align: 'center' });
    pdfDoc.moveDown(2);
    pdfDoc.fontSize(21).font('Helvetica-Bold').text('EMPLOYEES LEAVE CARD', { align: 'center' });
    pdfDoc.moveDown(2);

    // Employee Information Section
    pdfDoc.font('Helvetica').fontSize(12);
    
    // Name and Office row
    let yPos = pdfDoc.y;
    pdfDoc.text('NAME:', 20, yPos);
    pdfDoc.text(`${employee.last_name}, ${employee.first_name} ${employee.middle_name || ""}`, 80, yPos);
    
    pdfDoc.text('OFFICE:', 350, yPos);
    pdfDoc.text(employee.office || "MO", 410, yPos);
    
    // Position and Status row
    yPos += 20;
    pdfDoc.text('POSITION:', 20, yPos);
    pdfDoc.text(employee.position || "Administrative Aide I", 80, yPos);
    
    pdfDoc.text('FTD:', 350, yPos);
    pdfDoc.text('', 390, yPos);
    
    pdfDoc.text('STATUS:', 450, yPos);
    pdfDoc.text(employee.employment_status || "Permanent", 510, yPos);
    
    pdfDoc.moveDown(2);

    // Draw underline for form fields
    pdfDoc.moveTo(80, pdfDoc.y - 15).lineTo(280, pdfDoc.y - 15).stroke();
    pdfDoc.moveTo(410, pdfDoc.y - 15).lineTo(490, pdfDoc.y - 15).stroke();
    pdfDoc.moveTo(80, pdfDoc.y + 5).lineTo(280, pdfDoc.y + 5).stroke();
    pdfDoc.moveTo(390, pdfDoc.y + 5).lineTo(430, pdfDoc.y + 5).stroke();
    pdfDoc.moveTo(510, pdfDoc.y + 5).lineTo(590, pdfDoc.y + 5).stroke();

    pdfDoc.moveDown(3);

    // Create Leave Table
    const tableTop = pdfDoc.y;
    const cellPadding = 4;
    const colWidths = [60, 120, 40, 40, 40, 40, 40, 40, 40, 40, 90]; // 11 columns
    const rowHeight = 25;

    // Function to draw cell with text
    const drawCell = (x, y, width, height, text, options = {}) => {
      const { align = 'left', fontSize = 9, bold = false, rotate = false } = options;
      
      // Draw border
      pdfDoc.rect(x, y, width, height).stroke();
      
      // Set font
      pdfDoc.font(bold ? 'Helvetica-Bold' : 'Helvetica').fontSize(fontSize);
      
      // Draw text
      if (rotate) {
        // Vertical text for PERIOD header
        pdfDoc.save();
        pdfDoc.translate(x + width/2, y + height/2);
        pdfDoc.rotate(90);
        pdfDoc.text(text, 0, 0, { align: 'center', width: height });
        pdfDoc.restore();
      } else {
        const textX = align === 'center' ? x + width/2 : x + cellPadding;
        const textY = y + cellPadding;
        const textWidth = width - (cellPadding * 2);
        
        if (align === 'center') {
          pdfDoc.text(text, textX, textY, { align: 'center', width: textWidth });
        } else {
          pdfDoc.text(text, textX, textY, { width: textWidth });
        }
      }
    };

    // Table Headers - Row 1
    let xPos = 20;
    let yPosTable = tableTop;
    
    // PERIOD (vertical)
    drawCell(xPos, yPosTable, colWidths[0], rowHeight * 3, 'PERIOD', { align: 'center', rotate: true });
    xPos += colWidths[0];
    
    // PARTICULARS
    drawCell(xPos, yPosTable, colWidths[1], rowHeight * 3, 'PARTICULARS', { align: 'center', fontSize: 10 });
    xPos += colWidths[1];
    
    // VACATION LEAVE (spans 4 columns)
    drawCell(xPos, yPosTable, colWidths[2] + colWidths[3] + colWidths[4] + colWidths[5], rowHeight, 'VACATION LEAVE', { align: 'center', fontSize: 10 });
    
    // SICK LEAVE (spans 4 columns)
    drawCell(xPos + colWidths[2] + colWidths[3] + colWidths[4] + colWidths[5], yPosTable, colWidths[6] + colWidths[7] + colWidths[8] + colWidths[9], rowHeight, 'SICK LEAVE', { align: 'center', fontSize: 10 });
    
    // REMARKS
    drawCell(xPos + colWidths[2] + colWidths[3] + colWidths[4] + colWidths[5] + colWidths[6] + colWidths[7] + colWidths[8] + colWidths[9], yPosTable, colWidths[10], rowHeight * 3, 'REMARKS', { align: 'center', fontSize: 10 });

    // Row 2
    yPosTable += rowHeight;
    xPos = 20 + colWidths[0] + colWidths[1];
    
    // Vacation Leave sub-headers
    drawCell(xPos, yPosTable, colWidths[2], rowHeight * 2, 'EARNED', { align: 'center', fontSize: 8 });
    xPos += colWidths[2];
    
    drawCell(xPos, yPosTable, colWidths[3], rowHeight, 'ABS. UND. W/P', { align: 'center', fontSize: 7 });
    xPos += colWidths[3];
    
    drawCell(xPos, yPosTable, colWidths[4], rowHeight * 2, 'BALANCE', { align: 'center', fontSize: 8 });
    xPos += colWidths[4];
    
    drawCell(xPos, yPosTable, colWidths[5], rowHeight, 'ABS. UND. WOP', { align: 'center', fontSize: 7 });
    xPos += colWidths[5];
    
    // Sick Leave sub-headers
    drawCell(xPos, yPosTable, colWidths[6], rowHeight * 2, 'EARNED', { align: 'center', fontSize: 8 });
    xPos += colWidths[6];
    
    drawCell(xPos, yPosTable, colWidths[7], rowHeight, 'ABS.\nUND.\nW/P', { align: 'center', fontSize: 7, lineHeight: 1 });
    xPos += colWidths[7];
    
    drawCell(xPos, yPosTable, colWidths[8], rowHeight * 2, 'BALANCE', { align: 'center', fontSize: 8 });
    xPos += colWidths[8];
    
    drawCell(xPos, yPosTable, colWidths[9], rowHeight, 'ABS.\nUND.\nWOP', { align: 'center', fontSize: 7, lineHeight: 1 });

    // Row 3 (empty row for the 2-row spanned cells)
    yPosTable += rowHeight;

    // Now draw the data rows
    yPosTable += rowHeight;
    
    leaveCards.forEach((lc, index) => {
      // Check if we need a new page
      if (yPosTable > 700) {
        pdfDoc.addPage();
        yPosTable = 50;
        tableTop = yPosTable;
      }
      
      xPos = 20;
      
      // PERIOD
      drawCell(xPos, yPosTable, colWidths[0], rowHeight, lc.period || "", { align: 'center', fontSize: 9 });
      xPos += colWidths[0];
      
      // PARTICULARS
      drawCell(xPos, yPosTable, colWidths[1], rowHeight, lc.particulars || "", { align: 'left', fontSize: 9 });
      xPos += colWidths[1];
      
      // Vacation Leave columns
      drawCell(xPos, yPosTable, colWidths[2], rowHeight, lc.vl_earned || "", { align: 'center', fontSize: 12 });
      xPos += colWidths[2];
      
      drawCell(xPos, yPosTable, colWidths[3], rowHeight, lc.vl_used || "", { align: 'center', fontSize: 12 });
      xPos += colWidths[3];
      
      drawCell(xPos, yPosTable, colWidths[4], rowHeight, lc.vl_balance || "", { align: 'center', fontSize: 12 });
      xPos += colWidths[4];
      
      drawCell(xPos, yPosTable, colWidths[5], rowHeight, "", { align: 'center', fontSize: 12 });
      xPos += colWidths[5];
      
      // Sick Leave columns
      drawCell(xPos, yPosTable, colWidths[6], rowHeight, lc.sl_earned || "", { align: 'center', fontSize: 12 });
      xPos += colWidths[6];
      
      drawCell(xPos, yPosTable, colWidths[7], rowHeight, lc.sl_used || "", { align: 'center', fontSize: 12 });
      xPos += colWidths[7];
      
      drawCell(xPos, yPosTable, colWidths[8], rowHeight, lc.sl_balance || "", { align: 'center', fontSize: 12 });
      xPos += colWidths[8];
      
      drawCell(xPos, yPosTable, colWidths[9], rowHeight, "", { align: 'center', fontSize: 12 });
      xPos += colWidths[9];
      
      // REMARKS
      drawCell(xPos, yPosTable, colWidths[10], rowHeight, lc.remarks || "", { align: 'left', fontSize: 9 });
      
      yPosTable += rowHeight;
    });

    // Set response headers
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `attachment; filename="${employee.last_name}, ${employee.first_name}.pdf"`);

    // Finalize PDF
    pdfDoc.end();

    // Wait for PDF to finish writing
    await new Promise((resolve, reject) => {
      writeStream.on('finish', resolve);
      writeStream.on('error', reject);
    });

    // Cleanup Excel file
    try { fs.unlinkSync(tempExcelPath); } catch(e){/*ignore*/ }
    try { fs.unlinkSync(tempPdfPath); } catch(e){/*ignore*/ }

  } catch (error) {
    console.error("❌ Export failed:", error);
    
    // End PDF doc if it exists
    if (pdfDoc) {
      pdfDoc.end();
    }
    
    res.status(500).json({ 
      error: "Internal Server Error", 
      message: error.message
    });
  }
});

export default router;