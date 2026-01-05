import fetch from "node-fetch";
import { google } from "googleapis";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import sql from "../config/db.js";

// Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ======================
// FIND SERVICE ACCOUNT FILE
// ======================
function findServiceAccountFile() {
  console.log("🔍 Searching for service account file...");
  console.log("Current directory:", process.cwd());
  console.log("Script directory:", __dirname);
  
  const searchPaths = [
    // Common locations relative to current directory
    "./ezleave-push-firebase-adminsdk-fbsvc-ba624a8fd4.json",
    "../ezleave-push-firebase-adminsdk-fbsvc-ba624a8fd4.json",
    "../../ezleave-push-firebase-adminsdk-fbsvc-ba624a8fd4.json",
    // Relative to this script's directory
    path.join(__dirname, "ezleave-push-firebase-adminsdk-fbsvc-ba624a8fd4.json"),
    path.join(__dirname, "..", "ezleave-push-firebase-adminsdk-fbsvc-ba624a8fd4.json"),
    path.join(__dirname, "../..", "ezleave-push-firebase-adminsdk-fbsvc-ba624a8fd4.json"),
    // Absolute path from your project structure
    "C:/Users/Shamelle Tadeja/ezleave_admin/backend/ezleave-push-firebase-adminsdk-fbsvc-ba624a8fd4.json",
    path.join(process.cwd(), "ezleave-push-firebase-adminsdk-fbsvc-ba624a8fd4.json"),
  ];

  for (const filePath of searchPaths) {
    if (fs.existsSync(filePath)) {
      console.log(`✅ Found service account: ${path.resolve(filePath)}`);
      return filePath;
    }
  }
  
  // List JSON files in parent directories to help debug
  console.log("\n📁 Available JSON files:");
  const dirsToCheck = [process.cwd(), __dirname, path.join(__dirname, "..")];
  
  for (const dir of dirsToCheck) {
    try {
      const files = fs.readdirSync(dir);
      const jsonFiles = files.filter(f => f.endsWith('.json'));
      if (jsonFiles.length > 0) {
        console.log(`  In ${dir}:`);
        jsonFiles.forEach(file => console.log(`    📄 ${file}`));
      }
    } catch (e) {
      // Ignore directory errors
    }
  }
  
  throw new Error("❌ Service account file not found. Please place it in the backend root directory.");
}

// ======================
// LOAD SERVICE ACCOUNT
// ======================
let serviceAccount;
let SERVICE_ACCOUNT_PATH;

try {
  SERVICE_ACCOUNT_PATH = findServiceAccountFile();
  const rawData = fs.readFileSync(SERVICE_ACCOUNT_PATH, "utf8");
  serviceAccount = JSON.parse(rawData);
  console.log(`✅ Loaded service account for project: ${serviceAccount.project_id}`);
} catch (error) {
  console.error("❌ Failed to load service account:", error.message);
  console.log("\n💡 TIP: Place your service account JSON file in:");
  console.log("   C:\\Users\\Shamelle Tadeja\\ezleave_admin\\backend\\");
  console.log("   Or in the same folder as fcm.js");
  
  // Continue without service account - we can still use Expo service
  serviceAccount = null;
  console.log("⚠️ Will use Expo push service only (no FCM v1)");
}

// In your fcm.js, replace the entire sendPushToUser function with this:
export async function sendPushToUser(userId, title, body, data = {}) {
  try {
    console.log(`🎯 Looking up tokens for user: ${userId}`);
    
    // SIMPLE QUERY - no complex conditions that could cause SQL errors
    const tokens = await sql`
      SELECT expo_push_token 
      FROM employee_push_tokens 
      WHERE user_id = ${userId}
    `;
    
    console.log(`📱 Found ${tokens.length} token(s) in database`);
    
    // DEBUG: Show what we found
    if (tokens.length > 0) {
      tokens.forEach((row, index) => {
        console.log(`  Token ${index + 1}: "${row.expo_push_token}"`);
        console.log(`    Length: ${row.expo_push_token?.length} chars`);
        console.log(`    Is Expo token: ${row.expo_push_token?.startsWith?.('ExponentPushToken[')}`);
      });
    }
    
    if (tokens.length === 0) {
      console.log(`❌ No tokens found for user ${userId}`);
      return {
        success: false,
        message: "No tokens found in database",
        user_id: userId
      };
    }
    
    // Filter for valid Expo tokens
    const validTokens = tokens
      .map(row => row.expo_push_token)
      .filter(token => 
        token && 
        typeof token === 'string' && 
        token.startsWith('ExponentPushToken[')
      );
    
    console.log(`✅ Valid Expo tokens found: ${validTokens.length}`);
    
    if (validTokens.length === 0) {
      console.log(`❌ No valid Expo tokens found`);
      return {
        success: false,
        message: "No valid Expo tokens found in database",
        user_id: userId,
        debug: {
          raw_tokens: tokens.map(t => t.expo_push_token),
          issues: "Tokens don't start with 'ExponentPushToken['"
        }
      };
    }
    
    // Use the first valid token
    const expoToken = validTokens[0];
    console.log(`📤 Using token: ${expoToken.substring(0, 30)}...`);
    
    // Send the notification
    const result = await sendExpoPush(
      expoToken,
      title,
      body,
      {
        ...data,
        user_id: userId,
        timestamp: new Date().toISOString()
      }
    );
    
    return {
      success: true,
      result,
      user_id: userId,
      tokens_found: tokens.length,
      valid_tokens: validTokens.length,
      token_used: expoToken.substring(0, 10) + '...'
    };
    
  } catch (error) {
    console.error("❌ Error in sendPushToUser:", error.message);
    console.error("Stack trace:", error.stack);
    
    // Check if it's a SQL error
    if (error.message.includes('SQL') || error.message.includes('syntax')) {
      console.error("⚠️ This appears to be a SQL syntax error");
      console.error("Try running this SQL manually:");
      console.error(`  SELECT expo_push_token FROM employee_push_tokens WHERE user_id = '${userId}'`);
    }
    
    return {
      success: false,
      error: error.message,
      user_id: userId,
      is_sql_error: error.message.includes('SQL') || error.message.includes('syntax')
    };
  }
}

export async function sendExpoPush(token, title, body, data = {}) {
  try {
    console.log("\n📤 Sending via Expo Push API...");
    console.log(`📱 Token: ${token.substring(0, 30)}...`);
    
    if (!token.startsWith("ExponentPushToken")) {
      console.warn("⚠️ This doesn't look like a standard Expo token");
    }

    const message = {
      to: token,
      sound: 'default',
      title: title,
      body: body,
      data: data,
      priority: 'high',
      channelId: 'default'
    };

    const response = await fetch('https://exp.host/--/api/v2/push/send', {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Accept-encoding': 'gzip, deflate',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify([message]),
    });

    const result = await response.json();
    console.log('📤 Expo API Response:', JSON.stringify(result, null, 2));
    
    if (result.errors || result.data?.[0]?.status === 'error') {
      const errorMsg = result.errors?.[0]?.message || result.message || "Unknown error";
      throw new Error(`Expo push failed: ${errorMsg}`);
    }
    
    console.log('✅ Expo push sent successfully!');
    return result;
  } catch (error) {
    console.error('❌ Expo push error:', error.message);
    throw error;
  }
}

// ======================
// FCM v1 SERVICE (OPTIONAL)
// ======================
async function getAccessToken() {
  if (!serviceAccount) {
    throw new Error("No service account loaded. Cannot use FCM v1.");
  }
  
  try {
    console.log("\n🔄 Getting FCM access token...");
    
    const jwtClient = new google.auth.JWT(
      serviceAccount.client_email,
      null,
      serviceAccount.private_key,
      ["https://www.googleapis.com/auth/firebase.messaging"]
    );

    const tokens = await jwtClient.authorize();
    console.log("✅ FCM access token obtained");
    return tokens.access_token;
  } catch (error) {
    console.error("❌ Failed to get FCM access token:", error.message);
    throw error;
  }
}

export async function sendFcmPush(token, title, body, data = {}) {
  try {
    console.log("\n📤 Attempting FCM v1 push...");
    
    // Auto-switch to Expo for Expo tokens
    if (token.startsWith("ExponentPushToken")) {
      console.log("🔄 Detected Expo token, switching to Expo service...");
      return await sendExpoPush(token, title, body, data);
    }
    
    const accessToken = await getAccessToken();
    
    const message = {
      message: {
        token: token,
        notification: { 
          title: title, 
          body: body 
        },
        data: {
          ...data,
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        },
        android: {
          priority: "high"
        }
      }
    };

    const projectId = serviceAccount.project_id;
    console.log(`🌐 Project ID: ${projectId}`);

    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(message),
      }
    );

    const result = await response.json();
    console.log("📤 FCM response:", result);
    
    if (response.status !== 200) {
      throw new Error(`FCM API error: ${JSON.stringify(result)}`);
    }
    
    return result;
  } catch (error) {
    console.error("❌ FCM push error:", error.message);
    throw error;
  }
}

// ======================
// SMART PUSH FUNCTION
// ======================
export async function sendPushNotification(token, title, body, data = {}) {
  console.log("\n🎯 Smart push notification...");
  console.log(`📱 Token: ${token.substring(0, 30)}...`);
  
  // Always use Expo service (it works with Expo tokens)
  return await sendExpoPush(token, title, body, data);
}

// ======================
// DIRECT TEST FUNCTION
// ======================
export async function testExpoPush() {
  const expoToken = "ExponentPushToken[u-0ZRkFJ97JSDVrTOY1NHh]"; // Your token
  
  console.log("\n🧪 Testing Expo push service...");
  console.log("==================================");
  
  try {
    const result = await sendExpoPush(
      expoToken,
      "Test Notification ✅",
      "This is a test from the fixed push service.",
      { test: true, timestamp: new Date().toISOString() }
    );
    
    console.log("\n✅ Test successful!");
    return result;
  } catch (error) {
    console.log("\n❌ Test failed:", error.message);
    throw error;
  }
}