import express from "express";
import { generateCSForm, saveSignature, removeSignatureBackground, getLeavePDFs, downloadPDF } from "../controllers/csFormController.js";

const router = express.Router();

router.post("/generate-cs-form", generateCSForm);
router.post("/save-signature", saveSignature)
router.post('/remove-signature-background', removeSignatureBackground);
router.get('/leave-pdfs/:leave_application_id', getLeavePDFs);
router.get('/download-pdf/:pdf_id', downloadPDF);

export default router;
