import express from "express";
import { generateCSForm, saveSignature } from "../controllers/csFormController.js";

const router = express.Router();

router.post("/generate-cs-form", generateCSForm);
router.post("/save-signature", saveSignature)

export default router;
