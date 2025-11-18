import express from "express";
import { generateCSForm } from "../controllers/csFormController.js";

const router = express.Router();

router.post("/generate-cs-form", generateCSForm);

export default router;
