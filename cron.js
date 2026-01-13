import cron from "node-cron";
import { autoEarnLeaveCredits } from "./controllers/leaveCardController.js";

// Schedule: 12:01 AM on the 1st day of every month
cron.schedule(
  "1 0 1 * *",  // minute 1, hour 0, day 1 of every month
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
