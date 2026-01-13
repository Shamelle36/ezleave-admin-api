import cron from "node-cron";
import { autoEarnLeaveCredits } from "./controllers/leaveCardController.js";

cron.schedule(
  "55 12 13 * *",  // Every 13th of the month at 12:55 PM Manila time
  async () => {
    console.log("🔔 CRON TRIGGERED — Monthly Leave Earn PH time");

    try {
      await autoEarnLeaveCredits();
      console.log("🎉 CRON SUCCESS — Monthly Leave Earn Completed");
    } catch (err) {
      console.error("❌ CRON FAILED:", err);
    }
  },
  {
    timezone: "Asia/Manila",
  }
);
