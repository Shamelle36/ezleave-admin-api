// routes/employeeRoutes.js
import express from "express";
import {
  addEmployee,
  getEmployees,
  getEmployeeById,
  updateEmployee,
  deleteEmployee,
  getEmployeeCount,
  getEmployeeLeaveBalances,
  updateLeaveEntitlement,
  getAllSignatures,
  getEmployeeSignature,
  uploadEmployeeSignature,
  deleteEmployeeSignature
} from "../controllers/employeeController.js";
import { signatureStorage } from "../config/cloudinary.js";
import multer from "multer";

const router = express.Router();

// Configure multer for temporary file storage before Cloudinary upload
const upload = multer({ 
  dest: 'uploads/temp/',
  limits: {
    fileSize: 2 * 1024 * 1024 // 2MB
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/png', 'image/jpeg', 'image/jpg', 'image/svg+xml'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only PNG, JPEG, JPG, SVG are allowed.'));
    }
  }
});

// Employee routes
router.post("/", addEmployee);
router.get("/", getEmployees);
router.get("/count", getEmployeeCount);
router.get("/:id", getEmployeeById);
router.put("/:id", updateEmployee);
router.delete("/:id", deleteEmployee);
router.get('/:id/leave-balances', getEmployeeLeaveBalances);
router.put("/leave-entitlements/update", updateLeaveEntitlement);

// Signature routes
router.get("/signatures/all", getAllSignatures);
router.get("/:id/signature", getEmployeeSignature);
router.post("/:id/signature", upload.single('signature'), uploadEmployeeSignature);
router.delete("/:id/signature", deleteEmployeeSignature);

export default router;