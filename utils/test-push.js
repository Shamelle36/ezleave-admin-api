// test-push.js
import { sendExpoPush, sendPushNotification } from './fcm.js';

async function test() {
  const expoToken = "ExponentPushToken[_oKEVhIYhpKGKrrJi6rSeZ]"; // Your token
  
  console.log("🧪 Testing push notifications...");
  
  // Test 1: Direct Expo push
  console.log("\n1️⃣ Testing direct Expo push...");
  try {
    const result = await sendExpoPush(
      expoToken,
      "Test Notification ✅",
      "This is a test from the fixed push service."
    );
    console.log("✅ Expo test successful!");
  } catch (error) {
    console.log("❌ Expo test failed:", error.message);
  }
  
  // Test 2: Smart routing
  console.log("\n2️⃣ Testing smart routing...");
  try {
    const result = await sendPushNotification(
      expoToken,
      "Smart Test ✅",
      "This uses the smart routing function."
    );
    console.log("✅ Smart routing successful!");
  } catch (error) {
    console.log("❌ Smart routing failed:", error.message);
  }
}

test();