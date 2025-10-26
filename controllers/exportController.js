import ExcelJS from "exceljs";
import PDFDocument from "pdfkit";
import { Document, Packer, Paragraph, Table, TableRow, TableCell } from "docx";
import sql from "../config/db.js";

export const exportAttendance = async (req, res) => {
  try {
    const { date, format } = req.query; // ?date=YYYY-MM-DD&format=excel

    // 🟢 Query with sql instead of pool
    const rows = await sql`
      SELECT name, pin, am_checkin, am_checkout, pm_checkin, pm_checkout, attendance_date
      FROM attendance_logs
      WHERE attendance_date = ${date}
    `;

    if (format === "excel") {
      // ---------- Excel ----------
      const workbook = new ExcelJS.Workbook();
      const worksheet = workbook.addWorksheet("Attendance Logs");

      worksheet.columns = [
        { header: "Name", key: "name", width: 25 },
        { header: "PIN", key: "pin", width: 10 },
        { header: "AM Check-in", key: "am_checkin", width: 20 },
        { header: "AM Check-out", key: "am_checkout", width: 20 },
        { header: "PM Check-in", key: "pm_checkin", width: 20 },
        { header: "PM Check-out", key: "pm_checkout", width: 20 },
        { header: "Date", key: "attendance_date", width: 15 },
      ];

      rows.forEach((r) => worksheet.addRow(r));

      res.setHeader(
        "Content-Disposition",
        `attachment; filename=attendance_${date}.xlsx`
      );
      res.setHeader(
        "Content-Type",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      );
      await workbook.xlsx.write(res);
      res.end();

    } else if (format === "word") {
      // ---------- Word ----------
      const tableRows = [
        new TableRow({
          children: [
            new TableCell({ children: [new Paragraph("Name")] }),
            new TableCell({ children: [new Paragraph("PIN")] }),
            new TableCell({ children: [new Paragraph("AM Check-in")] }),
            new TableCell({ children: [new Paragraph("AM Check-out")] }),
            new TableCell({ children: [new Paragraph("PM Check-in")] }),
            new TableCell({ children: [new Paragraph("PM Check-out")] }),
            new TableCell({ children: [new Paragraph("Date")] }),
          ],
        }),
      ];

      rows.forEach((r) => {
        tableRows.push(
          new TableRow({
            children: [
              new TableCell({ children: [new Paragraph(r.name)] }),
              new TableCell({ children: [new Paragraph(r.pin.toString())] }),
              new TableCell({ children: [new Paragraph(r.am_checkin?.toString() || "-")] }),
              new TableCell({ children: [new Paragraph(r.am_checkout?.toString() || "-")] }),
              new TableCell({ children: [new Paragraph(r.pm_checkin?.toString() || "-")] }),
              new TableCell({ children: [new Paragraph(r.pm_checkout?.toString() || "-")] }),
              new TableCell({ children: [new Paragraph(r.attendance_date.toString())] }),
            ],
          })
        );
      });

      const doc = new Document({
        sections: [
          {
            children: [new Paragraph("Attendance Logs"), new Table({ rows: tableRows })],
          },
        ],
      });

      const buffer = await Packer.toBuffer(doc);

      res.setHeader(
        "Content-Disposition",
        `attachment; filename=attendance_${date}.docx`
      );
      res.setHeader(
        "Content-Type",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      );
      res.send(buffer);

    } else if (format === "pdf") {
        // ---------- PDF ----------
        const doc = new PDFDocument({ margin: 40, size: "A4" });

        res.setHeader("Content-Disposition", `attachment; filename=attendance_${date}.pdf`);
        res.setHeader("Content-Type", "application/pdf");

        doc.pipe(res);

        // Helpers
        const formatTime = (value) => {
            if (!value) return "-";
            const d = new Date(value);
            return d.toLocaleTimeString("en-US", {
            hour: "2-digit",
            minute: "2-digit",
            });
        };

        const formatDate = (value) => {
            if (!value) return "-";
            const d = new Date(value);
            return d.toLocaleDateString("en-US", {
            year: "numeric",
            month: "long",
            day: "numeric",
            });
        };

        // Title
        doc.fontSize(18).text("Attendance Logs", { align: "center" });
        doc.moveDown(0.5);
        doc.fontSize(12).text(`Date: ${formatDate(date)}`, { align: "center" });
        doc.moveDown(2);

        // Table settings
        const startX = 40;
        let y = 160;
        const colWidths = [110, 50, 70, 70, 70, 70, 100];
        const rowHeight = 25;

        const headers = ["Name", "PIN", "AM In", "AM Out", "PM In", "PM Out", "Date"];

        // Draw a table cell
        const drawCell = (text, x, y, width, height, isHeader = false) => {
            // cell border
            doc.rect(x, y, width, height).stroke();

            // background for header
            if (isHeader) {
            doc.rect(x, y, width, height).fill("#f0f0f0").stroke();
            doc.fillColor("#000000").font("Helvetica-Bold");
            } else {
            doc.fillColor("#333333").font("Helvetica");
            }

            // text centered
            doc
            .fontSize(9)
            .text(text || "-", x + 2, y + 7, { width: width - 4, align: "center" });

            doc.fillColor("#000000");
        };

        // Draw header row
        let x = startX;
        headers.forEach((h, i) => {
            drawCell(h, x, y, colWidths[i], rowHeight, true);
            x += colWidths[i];
        });
        y += rowHeight;

        // Draw data rows
        rows.forEach((r) => {
            const rowData = [
            r.name,
            r.pin.toString(),
            formatTime(r.am_checkin),
            formatTime(r.am_checkout),
            formatTime(r.pm_checkin),
            formatTime(r.pm_checkout),
            formatDate(r.attendance_date),
            ];

            let x = startX;
            rowData.forEach((d, i) => {
            drawCell(d, x, y, colWidths[i], rowHeight, false);
            x += colWidths[i];
            });
            y += rowHeight;
        });

        doc.end();
        } else {
      return res.status(400).send("Invalid format. Use excel, word, or pdf.");
    }

  } catch (err) {
    console.error("❌ Export Error:", err.message);
    res.status(500).send("Failed to export attendance");
  }
};
