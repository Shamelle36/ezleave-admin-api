// backend/server.js
import express from "express";
import dotenv from "dotenv";
import authRoute from "./routes/authRoute.js";
import auditLogRoutes from "./routes/auditLogRoute.js";
import cors from "cors";
import announcementRoute from "./routes/announcementRoute.js";
import employeeRoute from "./routes/employeeRoute.js";
import leaveRequestRoute from "./routes/leaveRequestRoute.js";
import attendanceRoute from "./routes/attendanceRoute.js";
import exportRoute from "./routes/exportRoute.js";
import adminAuthRoute from "./routes/adminAuthRoute.js";
import leaveCardRoutes from "./routes/leaveCardRoute.js";
import exportRoutes from "./routes/exportPdfRoute.js";
import csFormRoutes from "./routes/csFormRoutes.js";
import path from "path";


dotenv.config();
const app = express();

app.use(cors({
  origin: ["http://localhost:3001", "http://192.168.254.101:3001"],
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  credentials: true
}));

app.use(express.json());
app.use("/api/auth", authRoute);
app.use("/api/audit-logs", auditLogRoutes);
app.use("/api/announcements", announcementRoute);

app.use("/uploads", express.static(path.join(process.cwd(), "uploads")));

app.use("/api/employees", employeeRoute);
app.use("/api/leave-requests", leaveRequestRoute);
app.use("/api/attendance", attendanceRoute);
app.use("/api/export", exportRoute);
app.use("/api/authAdmin", adminAuthRoute);
app.use("/api/leave-cards", leaveCardRoutes);
app.use("/api/exportPdf", exportRoutes);
app.use("/api", csFormRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
