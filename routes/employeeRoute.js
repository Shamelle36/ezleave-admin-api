import express from "express";
import {
  addEmployee,
  getEmployees,
  getEmployeeById,
  updateEmployee,
  deleteEmployee,
  getEmployeeCount,
  getEmployeeLeaveBalances,
  updateLeaveEntitlement
} from "../controllers/employeeController.js";

const router = express.Router();

router.post("/", addEmployee);
router.get("/", getEmployees);
router.get("/count", getEmployeeCount);
router.get("/:id", getEmployeeById);
router.put("/:id", updateEmployee);
router.delete("/:id", deleteEmployee);
router.get('/:id/leave-balances', getEmployeeLeaveBalances);
router.put("/leave-entitlements/update", updateLeaveEntitlement);

export default router;
