// backend/server.js
import express from "express";
import dotenv from "dotenv";
import authRoute from "./routes/authRoute.js";
import auditLogRoutes from "./routes/auditLogRoute.js";
import cors from "cors";
import announcementRoute from "./routes/announcementRoute.js";
import employeeRoute from "./routes/employeeRoute.js";
import path from "path";


dotenv.config();
const app = express();

app.use(cors({
  origin: "http://localhost:3000",
  methods: ["GET", "POST", "PUT", "DELETE"],
  credentials: true
}));

app.use(express.json());
app.use("/api/auth", authRoute);
app.use("/api/audit-logs", auditLogRoutes);
app.use("/api/announcements", announcementRoute);

app.use("/uploads", express.static(path.join(process.cwd(), "uploads")));

app.use("/api/employees", employeeRoute);


const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
