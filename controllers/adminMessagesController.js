import sql from "../config/db.js";
import { sendToUser } from "../socket.js";
/**
 * ✅ Helper function to create admin_messages table if it doesn't exist
 */
async function createAdminMessagesTable() {
  try {
    await sql`
      CREATE TABLE IF NOT EXISTS admin_messages (
        id SERIAL PRIMARY KEY,
        sender_id VARCHAR(255) NOT NULL,
        sender_type VARCHAR(50) NOT NULL CHECK (sender_type IN ('user', 'useradmin', 'admin_account')),
        receiver_id VARCHAR(255) NOT NULL,
        receiver_type VARCHAR(50) NOT NULL CHECK (receiver_type IN ('user', 'useradmin', 'admin_account')),
        message TEXT NOT NULL,
        time TIMESTAMP DEFAULT NOW(),
        pinned BOOLEAN DEFAULT FALSE,
        read_status BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;

    // Create indexes if they don't exist
    try {
      await sql`
        CREATE INDEX IF NOT EXISTS idx_admin_messages_sender ON admin_messages(sender_id);
      `;
      await sql`
        CREATE INDEX IF NOT EXISTS idx_admin_messages_receiver ON admin_messages(receiver_id);
      `;
      await sql`
        CREATE INDEX IF NOT EXISTS idx_admin_messages_time ON admin_messages(time DESC);
      `;
      await sql`
        CREATE INDEX IF NOT EXISTS idx_admin_messages_pinned ON admin_messages(pinned);
      `;
    } catch (indexError) {
      console.log("Indexes already exist or error creating indexes:", indexError.message);
    }

    console.log("✅ admin_messages table checked/created successfully");
  } catch (error) {
    console.error("❌ Error creating admin_messages table:", error);
    throw error;
  }
}

/**
 * 📋 Get all accounts from users, useradmin, and admin_accounts tables
 * (for admin messaging system to message any type of user)
 */
export async function getAllAccountsForAdmin(req, res) {
  try {
    const { current_admin_id, current_admin_type } = req.query;
    
    // Optional check for missing parameters
    if (!current_admin_id || !current_admin_type) {
      return res.status(400).json({ 
        success: false, 
        message: "Missing current_admin_id or current_admin_type" 
      });
    }

    // Create admin_messages table if it doesn't exist
    await createAdminMessagesTable();

    // Fetch all regular users
    const regularUsers = await sql`
      SELECT 
        user_id as id,
        email,
        first_name,
        last_name,
        'user' as account_type,
        CONCAT(first_name, ' ', last_name) as full_name,
        NULL as role,
        NULL as department
      FROM users
      ORDER BY first_name ASC;
    `;

    // Fetch all useradmins (excluding current admin if applicable)
    let userAdmins;
    if (current_admin_type === 'useradmin') {
      userAdmins = await sql`
        SELECT 
          id,
          email,
          full_name,
          'useradmin' as account_type,
          full_name,
          role,
          NULL as department
        FROM useradmin
        WHERE id != ${current_admin_id}
        ORDER BY full_name ASC;
      `;
    } else {
      userAdmins = await sql`
        SELECT 
          id,
          email,
          full_name,
          'useradmin' as account_type,
          full_name,
          role,
          NULL as department
        FROM useradmin
        ORDER BY full_name ASC;
      `;
    }

    // Fetch all admin_accounts (excluding current admin if applicable)
    let adminAccounts;
    if (current_admin_type === 'admin_account') {
      adminAccounts = await sql`
        SELECT 
          id,
          email,
          full_name,
          'admin_account' as account_type,
          full_name,
          role,
          department
        FROM admin_accounts
        WHERE id != ${current_admin_id} AND is_active = true
        ORDER BY full_name ASC;
      `;
    } else {
      adminAccounts = await sql`
        SELECT 
          id,
          email,
          full_name,
          'admin_account' as account_type,
          full_name,
          role,
          department
        FROM admin_accounts
        WHERE is_active = true
        ORDER BY full_name ASC;
      `;
    }

    // Combine all results
    const allAccounts = [
      ...regularUsers,
      ...userAdmins,
      ...adminAccounts
    ];

    // Sort by full_name for better UX
    allAccounts.sort((a, b) => {
      const nameA = a.full_name || `${a.first_name} ${a.last_name}`;
      const nameB = b.full_name || `${b.first_name} ${b.last_name}`;
      return nameA.localeCompare(nameB);
    });

    res.status(200).json({ 
      success: true, 
      data: allAccounts,
      counts: {
        users: regularUsers.length,
        useradmins: userAdmins.length,
        admin_accounts: adminAccounts.length,
        total: allAccounts.length
      }
    });
  } catch (error) {
    console.error("❌ Error fetching all accounts:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
}

/**
 * 💬 Get conversation between admin and a specific contact
 */
export async function getAdminConversation(req, res) {
  try {
    const { admin_id, admin_type, contact_id, contact_type } = req.params;

    if (!admin_id || !admin_type || !contact_id || !contact_type) {
      return res.status(400).json({ 
        success: false, 
        message: "Missing required parameters" 
      });
    }

    // Create admin_messages table if it doesn't exist
    await createAdminMessagesTable();

    // Create identifiers for both parties
    const adminIdentifier = `${admin_type}:${admin_id}`;
    const contactIdentifier = `${contact_type}:${contact_id}`;

    const messages = await sql`
      SELECT 
        m.id,
        m.sender_id,
        m.sender_type,
        m.receiver_id,
        m.receiver_type,
        m.message,
        m.time,
        m.pinned,
        m.read_status,
        -- Get sender info based on type
        CASE 
          WHEN m.sender_type = 'user' THEN (
            SELECT CONCAT(u.first_name, ' ', u.last_name) 
            FROM users u 
            WHERE u.user_id = m.sender_id
          )
          WHEN m.sender_type = 'useradmin' THEN (
            SELECT ua.full_name 
            FROM useradmin ua 
            WHERE ua.id = CAST(SPLIT_PART(m.sender_id, ':', 2) AS INTEGER)
          )
          WHEN m.sender_type = 'admin_account' THEN (
            SELECT aa.full_name 
            FROM admin_accounts aa 
            WHERE aa.id = CAST(SPLIT_PART(m.sender_id, ':', 2) AS INTEGER)
          )
        END as sender_name,
        -- Get receiver info based on type
        CASE 
          WHEN m.receiver_type = 'user' THEN (
            SELECT CONCAT(u.first_name, ' ', u.last_name) 
            FROM users u 
            WHERE u.user_id = m.receiver_id
          )
          WHEN m.receiver_type = 'useradmin' THEN (
            SELECT ua.full_name 
            FROM useradmin ua 
            WHERE ua.id = CAST(SPLIT_PART(m.receiver_id, ':', 2) AS INTEGER)
          )
          WHEN m.receiver_type = 'admin_account' THEN (
            SELECT aa.full_name 
            FROM admin_accounts aa 
            WHERE aa.id = CAST(SPLIT_PART(m.receiver_id, ':', 2) AS INTEGER)
          )
        END as receiver_name
      FROM admin_messages m
      WHERE (m.sender_id = ${adminIdentifier} AND m.receiver_id = ${contactIdentifier})
         OR (m.sender_id = ${contactIdentifier} AND m.receiver_id = ${adminIdentifier})
      ORDER BY m.time ASC;
    `;

    res.status(200).json({ success: true, data: messages });
  } catch (error) {
    console.error("❌ Error fetching admin conversation:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
}

/**
 * 💬 Get all messages for a specific admin (from all tables)
 */
export async function getAdminMessages(req, res) {
  try {
    const { admin_id, admin_type } = req.params;

    if (!admin_id || !admin_type) {
      return res.status(400).json({ 
        success: false, 
        message: "Missing admin_id or admin_type" 
      });
    }

    // Create admin_messages table if it doesn't exist
    await createAdminMessagesTable();

    // Create the sender identifier correctly
    const senderIdentifier = `${admin_type}:${admin_id}`;

    const messages = await sql`
      SELECT 
        m.id,
        m.sender_id,
        m.sender_type,
        m.receiver_id,
        m.receiver_type,
        m.message,
        m.time,
        m.pinned,
        m.read_status,
        -- Get sender info based on type
        CASE 
          WHEN m.sender_type = 'user' THEN (
            SELECT CONCAT(u.first_name, ' ', u.last_name) 
            FROM users u 
            WHERE u.user_id = SPLIT_PART(m.sender_id, ':', 2)
          )
          WHEN m.sender_type = 'useradmin' THEN (
            SELECT ua.full_name 
            FROM useradmin ua 
            WHERE ua.id = CAST(SPLIT_PART(m.sender_id, ':', 2) AS INTEGER)
          )
          WHEN m.sender_type = 'admin_account' THEN (
            SELECT aa.full_name 
            FROM admin_accounts aa 
            WHERE aa.id = CAST(SPLIT_PART(m.sender_id, ':', 2) AS INTEGER)
          )
        END as sender_name,
        -- Get receiver info based on type
        CASE 
          WHEN m.receiver_type = 'user' THEN (
            SELECT CONCAT(u.first_name, ' ', u.last_name) 
            FROM users u 
            WHERE u.user_id = SPLIT_PART(m.receiver_id, ':', 2)
          )
          WHEN m.receiver_type = 'useradmin' THEN (
            SELECT ua.full_name 
            FROM useradmin ua 
            WHERE ua.id = CAST(SPLIT_PART(m.receiver_id, ':', 2) AS INTEGER)
          )
          WHEN m.receiver_type = 'admin_account' THEN (
            SELECT aa.full_name 
            FROM admin_accounts aa 
            WHERE aa.id = CAST(SPLIT_PART(m.receiver_id, ':', 2) AS INTEGER)
          )
        END as receiver_name
      FROM admin_messages m
      WHERE m.sender_id = ${senderIdentifier} OR m.receiver_id = ${senderIdentifier}
      ORDER BY m.pinned DESC, m.time DESC;
    `;

    res.status(200).json({ success: true, data: messages });
  } catch (error) {
    console.error("❌ Error fetching admin messages:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
}

/**
 * 📇 Get contacts that the admin has messaged (from all tables)
 */
export async function getAdminContacts(req, res) {
  try {
    const { admin_id, admin_type } = req.params;

    if (!admin_id || !admin_type) {
      return res.status(400).json({ 
        success: false, 
        message: "Missing admin_id or admin_type" 
      });
    }

    // Create admin_messages table if it doesn't exist
    await createAdminMessagesTable();

    const senderIdentifier = `${admin_type}:${admin_id}`;

    const contacts = await sql`
      SELECT DISTINCT 
        CASE 
          WHEN m.sender_id = ${senderIdentifier} THEN m.receiver_id
          ELSE m.sender_id
        END as contact_id,
        CASE 
          WHEN m.sender_id = ${senderIdentifier} THEN m.receiver_type
          ELSE m.sender_type
        END as contact_type,
        CASE 
          WHEN m.sender_id = ${senderIdentifier} AND m.receiver_type = 'user' THEN (
            SELECT CONCAT(u.first_name, ' ', u.last_name) 
            FROM users u 
            WHERE u.user_id = SPLIT_PART(m.receiver_id, ':', 2)
          )
          WHEN m.sender_id = ${senderIdentifier} AND m.receiver_type = 'useradmin' THEN (
            SELECT ua.full_name 
            FROM useradmin ua 
            WHERE ua.id = CAST(SPLIT_PART(m.receiver_id, ':', 2) AS INTEGER)
          )
          WHEN m.sender_id = ${senderIdentifier} AND m.receiver_type = 'admin_account' THEN (
            SELECT aa.full_name 
            FROM admin_accounts aa 
            WHERE aa.id = CAST(SPLIT_PART(m.receiver_id, ':', 2) AS INTEGER)
          )
          WHEN m.receiver_id = ${senderIdentifier} AND m.sender_type = 'user' THEN (
            SELECT CONCAT(u.first_name, ' ', u.last_name) 
            FROM users u 
            WHERE u.user_id = SPLIT_PART(m.sender_id, ':', 2)
          )
          WHEN m.receiver_id = ${senderIdentifier} AND m.sender_type = 'useradmin' THEN (
            SELECT ua.full_name 
            FROM useradmin ua 
            WHERE ua.id = CAST(SPLIT_PART(m.sender_id, ':', 2) AS INTEGER)
          )
          WHEN m.receiver_id = ${senderIdentifier} AND m.sender_type = 'admin_account' THEN (
            SELECT aa.full_name 
            FROM admin_accounts aa 
            WHERE aa.id = CAST(SPLIT_PART(m.sender_id, ':', 2) AS INTEGER)
          )
        END as contact_name,
        CASE 
          WHEN m.sender_id = ${senderIdentifier} AND m.receiver_type = 'user' THEN (
            SELECT u.email FROM users u WHERE u.user_id = SPLIT_PART(m.receiver_id, ':', 2)
          )
          WHEN m.sender_id = ${senderIdentifier} AND m.receiver_type = 'useradmin' THEN (
            SELECT ua.email FROM useradmin ua WHERE ua.id = CAST(SPLIT_PART(m.receiver_id, ':', 2) AS INTEGER)
          )
          WHEN m.sender_id = ${senderIdentifier} AND m.receiver_type = 'admin_account' THEN (
            SELECT aa.email FROM admin_accounts aa WHERE aa.id = CAST(SPLIT_PART(m.receiver_id, ':', 2) AS INTEGER)
          )
          WHEN m.receiver_id = ${senderIdentifier} AND m.sender_type = 'user' THEN (
            SELECT u.email FROM users u WHERE u.user_id = SPLIT_PART(m.sender_id, ':', 2)
          )
          WHEN m.receiver_id = ${senderIdentifier} AND m.sender_type = 'useradmin' THEN (
            SELECT ua.email FROM useradmin ua WHERE ua.id = CAST(SPLIT_PART(m.sender_id, ':', 2) AS INTEGER)
          )
          WHEN m.receiver_id = ${senderIdentifier} AND m.sender_type = 'admin_account' THEN (
            SELECT aa.email FROM admin_accounts aa WHERE aa.id = CAST(SPLIT_PART(m.sender_id, ':', 2) AS INTEGER)
          )
        END as contact_email
      FROM admin_messages m
      WHERE m.sender_id = ${senderIdentifier} OR m.receiver_id = ${senderIdentifier}
      ORDER BY contact_name ASC;
    `;

    res.status(200).json({ success: true, data: contacts });
  } catch (error) {
    console.error("❌ Error fetching admin contacts:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
}

export async function sendAdminMessage(req, res) {
  try {
    console.log('📨 Received request body:', req.body);
    
    // Check if body exists
    if (!req.body) {
      return res.status(400).json({ 
        success: false, 
        message: "Request body is missing. Make sure you're sending JSON data with 'Content-Type: application/json'" 
      });
    }

    const { 
      sender_id, 
      sender_type, 
      receiver_id, 
      receiver_type, 
      message 
    } = req.body;

    // Validate required fields
    const missingFields = [];
    if (!sender_id) missingFields.push('sender_id');
    if (!sender_type) missingFields.push('sender_type');
    if (!receiver_id) missingFields.push('receiver_id');
    if (!receiver_type) missingFields.push('receiver_type');
    if (!message) missingFields.push('message');

    if (missingFields.length > 0) {
      return res.status(400).json({ 
        success: false, 
        message: `Missing required fields: ${missingFields.join(', ')}` 
      });
    }

    // Create admin_messages table if it doesn't exist
    await createAdminMessagesTable();

    // Validate sender exists based on type
    let senderExists = false;
    let senderName = '';
    let senderEmail = '';
    
    console.log(`🔍 Validating sender: ${sender_type} with ID: ${sender_id}`);
    
    switch(sender_type) {
      case 'useradmin':
        const userAdmin = await sql`SELECT id, full_name, email FROM useradmin WHERE id = ${sender_id}`;
        console.log('🔍 UserAdmin query result:', userAdmin);
        senderExists = userAdmin.length > 0;
        if (senderExists) {
          senderName = userAdmin[0].full_name;
          senderEmail = userAdmin[0].email;
        }
        break;
      case 'admin_account':
        const adminAcc = await sql`SELECT id, full_name, email FROM admin_accounts WHERE id = ${sender_id} AND is_active = true`;
        console.log('🔍 Admin_account query result:', adminAcc);
        senderExists = adminAcc.length > 0;
        if (senderExists) {
          senderName = adminAcc[0].full_name;
          senderEmail = adminAcc[0].email;
        }
        break;
      case 'user':
        const user = await sql`SELECT user_id, first_name, last_name, email FROM users WHERE user_id = ${sender_id}`;
        console.log('🔍 User query result:', user);
        senderExists = user.length > 0;
        if (senderExists) {
          senderName = `${user[0].first_name} ${user[0].last_name}`;
          senderEmail = user[0].email;
        }
        break;
      default:
        return res.status(400).json({ 
          success: false, 
          message: `Invalid sender_type: ${sender_type}. Must be 'useradmin', 'admin_account', or 'user'` 
        });
    }

    if (!senderExists) {
      return res.status(404).json({ 
        success: false, 
        message: `Sender not found or inactive. Type: ${sender_type}, ID: ${sender_id}` 
      });
    }

    // Validate receiver exists based on type
    let receiverExists = false;
    let receiverName = '';
    let receiverEmail = '';
    
    console.log(`🔍 Validating receiver: ${receiver_type} with ID: ${receiver_id}`);
    
    switch(receiver_type) {
      case 'useradmin':
        const userAdmin = await sql`SELECT id, full_name, email FROM useradmin WHERE id = ${receiver_id}`;
        console.log('🔍 UserAdmin (receiver) query result:', userAdmin);
        receiverExists = userAdmin.length > 0;
        if (receiverExists) {
          receiverName = userAdmin[0].full_name;
          receiverEmail = userAdmin[0].email;
        }
        break;
      case 'admin_account':
        const adminAcc = await sql`SELECT id, full_name, email FROM admin_accounts WHERE id = ${receiver_id} AND is_active = true`;
        console.log('🔍 Admin_account (receiver) query result:', adminAcc);
        receiverExists = adminAcc.length > 0;
        if (receiverExists) {
          receiverName = adminAcc[0].full_name;
          receiverEmail = adminAcc[0].email;
        }
        break;
      case 'user':
        const user = await sql`SELECT user_id, first_name, last_name, email FROM users WHERE user_id = ${receiver_id}`;
        console.log('🔍 User (receiver) query result:', user);
        receiverExists = user.length > 0;
        if (receiverExists) {
          receiverName = `${user[0].first_name} ${user[0].last_name}`;
          receiverEmail = user[0].email;
        }
        break;
      default:
        return res.status(400).json({ 
          success: false, 
          message: `Invalid receiver_type: ${receiver_type}. Must be 'useradmin', 'admin_account', or 'user'` 
        });
    }

    if (!receiverExists) {
      return res.status(404).json({ 
        success: false, 
        message: `Receiver not found or inactive. Type: ${receiver_type}, ID: ${receiver_id}` 
      });
    }

    // Create unique identifiers
    const senderIdentifier = `${sender_type}:${sender_id}`;
    const receiverIdentifier = `${receiver_type}:${receiver_id}`;

    console.log('📝 Creating message with identifiers:', {
      senderIdentifier,
      receiverIdentifier,
      sender_type,
      receiver_type,
      message_length: message.length
    });

    // Insert message into admin_messages table
    const result = await sql`
      INSERT INTO admin_messages (
        sender_id, 
        sender_type, 
        receiver_id, 
        receiver_type, 
        message, 
        time, 
        pinned, 
        read_status
      ) VALUES (
        ${senderIdentifier},
        ${sender_type},
        ${receiverIdentifier},
        ${receiver_type},
        ${message},
        NOW(),
        false,
        false
      ) RETURNING *;
    `;

    console.log('✅ Message inserted successfully:', result[0]);

    // ✅ ADD NOTIFICATION FOR RECEIVER (WITH PUSH NOTIFICATION)
    const notificationMessage = `New message from ${senderName}: ${message.substring(0, 100)}${message.length > 100 ? '...' : ''}`;
    
    console.log(`📢 Creating notification for receiver: ${receiver_id}`);
    console.log(`📢 Notification message: ${notificationMessage}`);
    
    try {
      // Check if notifications table exists
      const tableCheck = await sql`
        SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_schema = 'public' 
          AND table_name = 'notifications'
        );
      `;
      
      console.log(`📊 Notifications table exists: ${tableCheck[0]?.exists}`);
      
      if (tableCheck[0]?.exists) {
        // Insert into notifications table
        const notificationResult = await sql`
          INSERT INTO notifications (
            user_id,
            message,
            read,
            created_at
          ) VALUES (
            ${receiver_id},
            ${notificationMessage},
            false,
            NOW()
          ) RETURNING *;
        `;
        
        console.log(`✅ Database notification created:`, notificationResult[0]);
        console.log(`📋 Notification ID: ${notificationResult[0]?.id}`);
        
        // ✅ SEND PUSH NOTIFICATION WITH REPLY SUPPORT
        try {
          // Check if user has a push token
          const tokenResult = await sql`
            SELECT expo_push_token FROM employee_push_tokens WHERE user_id = ${receiver_id} LIMIT 1
          `;
          
          if (tokenResult.length > 0 && tokenResult[0].expo_push_token) {
            console.log(`📱 Found push token for user ${receiver_id}, sending push notification with reply support...`);
            
            // Send push notification via Expo WITH REPLY ACTION
            const pushResponse = await fetch("https://exp.host/--/api/v2/push/send", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                to: tokenResult[0].expo_push_token,
                sound: "default",
                title: `New Message from ${senderName}`,
                body: message.substring(0, 100) + (message.length > 100 ? '...' : ''),
                // ✅ ADD REPLY ACTION FOR ANDROID
                android: {
                  channelId: "messages",
                  actions: [
                    {
                      title: "Reply",
                      actionId: "reply",
                      icon: "ic_reply",
                      type: "text",
                      placeholder: "Type a reply..."
                    },
                    {
                      title: "Mark as Read",
                      actionId: "read",
                      icon: "ic_done"
                    }
                  ]
                },
                // ✅ ADD CATEGORY FOR IOS QUICK REPLIES
                categoryId: "MESSAGE_REPLY",
                // ✅ ADD EXTRA DATA FOR REPLY FUNCTIONALITY
                data: { 
                  type: 'new_message',
                  notificationType: 'direct_message',
                  senderId: sender_id,
                  senderType: sender_type,
                  senderName: senderName,
                  messageId: result[0].id,
                  conversationId: `${sender_type}:${sender_id}`, // For grouping notifications
                  replyAction: "REPLY_TO_MESSAGE",
                  timestamp: new Date().toISOString(),
                  // For deep linking to specific conversation
                  url: `yourapp://messages/${sender_type}/${sender_id}`
                }
              }),
            });
            
            const pushResult = await pushResponse.json();
            console.log("📤 Push notification with reply sent:", pushResult);
            
            if (pushResult.data && pushResult.data.status === 'ok') {
              console.log("✅ Push notification with reply delivered successfully");
            } else {
              console.warn("⚠️ Push notification may not have been delivered:", pushResult);
            }
          } else {
            console.log(`📱 No push token found for user ${receiver_id}. User might need to enable notifications in the app.`);
          }
        } catch (pushError) {
          console.warn("⚠️ Could not send push notification:", pushError.message);
        }
      } else {
        console.error('❌ Notifications table does not exist!');
      }
    } catch (notificationError) {
      console.error("❌ Error creating notification:", notificationError);
      console.error("❌ Full error details:", {
        message: notificationError.message,
        code: notificationError.code,
        detail: notificationError.detail
      });
      // Don't fail the whole request if notification fails
    }

   // In your sendAdminMessage function, update the WebSocket sending part:

// ✅ Prepare message data for WebSocket
const messageData = {
  id: result[0].id,
  sender_id: senderIdentifier,
  sender_type: sender_type,
  receiver_id: receiverIdentifier,
  receiver_type: receiver_type,
  message: message,
  time: result[0].time,
  sender_name: senderName,
  receiver_name: receiverName,
  pinned: false,
  read_status: false,
  delivered: true
};

// ✅ SEND VIA WEBSOCKET - FIXED STRUCTURE
const receiverSent = sendToUser(receiver_id, receiver_type, {
  type: 'new_message',
  message: messageData,
  timestamp: new Date().toISOString()
});

console.log(`📤 WebSocket delivery to ${receiver_id} (${receiver_type}): ${receiverSent ? 'SUCCESS' : 'FAILED - User offline'}`);

// ✅ Also send to sender for confirmation
sendToUser(sender_id, sender_type, {
  type: 'message_sent',
  message: {
    id: result[0].id,
    messageId: result[0].id,
    timestamp: result[0].time,
    receiverName: receiverName,
    delivered: receiverSent
  },
  timestamp: new Date().toISOString()
});

    console.log(`📤 WebSocket attempted: ${receiverSent ? 'Sent' : 'User offline'}`);
    console.log(`📨 Full message data:`, messageData);

    // Also check if notification was inserted by querying it
    try {
      const checkNotification = await sql`
        SELECT * FROM notifications 
        WHERE user_id = ${receiver_id} 
        ORDER BY created_at DESC 
        LIMIT 1;
      `;
      
      if (checkNotification.length > 0) {
        console.log(`🔍 Latest notification for ${receiver_id}:`, checkNotification[0]);
      } else {
        console.log(`⚠️ No recent notifications found for ${receiver_id}`);
      }
    } catch (checkError) {
      console.error("❌ Error checking notification:", checkError);
    }

    res.status(201).json({ 
      success: true, 
      message: "Message sent successfully",
      data: messageData,
      notification_sent: true,
      push_notification_sent: true,
      reply_supported: true, // Indicate reply is supported
      websocket_delivered: receiverSent
    });

  } catch (error) {
    console.error("❌ Error sending admin message:", error);
    
    // Provide more specific error messages
    let errorMessage = "Server error";
    let statusCode = 500;
    
    if (error.code === '23503') { // Foreign key violation
      errorMessage = "Invalid sender or receiver reference";
      statusCode = 400;
    } else if (error.code === '23505') { // Unique constraint violation
      errorMessage = "Duplicate message detected";
      statusCode = 400;
    } else if (error.code === '23514') { // Check constraint violation
      errorMessage = "Invalid data format";
      statusCode = 400;
    }
    
    res.status(statusCode).json({ 
      success: false, 
      message: errorMessage,
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
}

/**
 * 💬 Handle notification replies from mobile devices
 */
export async function handleNotificationReply(req, res) {
  try {
    console.log('📱 Received notification reply:', req.body);
    
    const { 
      notificationId,
      messageId,
      senderId,
      senderType,
      senderName,
      receiverId,
      receiverType,
      replyText,
      pushToken,
      timestamp
    } = req.body;

    if (!replyText || !senderId || !receiverId) {
      return res.status(400).json({ 
        success: false, 
        message: "Missing required fields: replyText, senderId, receiverId" 
      });
    }

    // Determine who is replying (reverse the sender/receiver)
    // If notification came from senderId, then receiver is replying
    const replierId = receiverId; // The one who received the original message
    const replierType = receiverType;
    const originalSenderId = senderId;
    const originalSenderType = senderType;

    // Create identifiers
    const replierIdentifier = `${replierType}:${replierId}`;
    const originalSenderIdentifier = `${originalSenderType}:${originalSenderId}`;

    console.log('📝 Processing reply:', {
      originalSender: originalSenderIdentifier,
      replier: replierIdentifier,
      replyText
    });

    // Insert reply as a new message
    const result = await sql`
      INSERT INTO admin_messages (
        sender_id, 
        sender_type, 
        receiver_id, 
        receiver_type, 
        message, 
        time, 
        pinned, 
        read_status
      ) VALUES (
        ${replierIdentifier},
        ${replierType},
        ${originalSenderIdentifier},
        ${originalSenderType},
        ${replyText},
        NOW(),
        false,
        false
      ) RETURNING *;
    `;

    console.log('✅ Reply message inserted successfully:', result[0]);

    // Get replier's name for notification
    let replierName = '';
    switch(replierType) {
      case 'useradmin':
        const userAdmin = await sql`SELECT full_name FROM useradmin WHERE id = ${replierId}`;
        replierName = userAdmin[0]?.full_name || 'User';
        break;
      case 'admin_account':
        const adminAcc = await sql`SELECT full_name FROM admin_accounts WHERE id = ${replierId} AND is_active = true`;
        replierName = adminAcc[0]?.full_name || 'User';
        break;
      case 'user':
        const user = await sql`SELECT first_name, last_name FROM users WHERE user_id = ${replierId}`;
        replierName = user[0] ? `${user[0].first_name} ${user[0].last_name}` : 'User';
        break;
    }

    // Create notification for original sender
    const notificationMessage = `Reply from ${replierName}: ${replyText.substring(0, 100)}${replyText.length > 100 ? '...' : ''}`;
    
    try {
      await sql`
        INSERT INTO notifications (
          user_id,
          message,
          read,
          created_at
        ) VALUES (
          ${originalSenderId},
          ${notificationMessage},
          false,
          NOW()
        );
      `;
      console.log(`✅ Created notification for original sender ${originalSenderId}`);
    } catch (notifError) {
      console.error("❌ Error creating reply notification:", notifError.message);
    }

    // Send push notification to original sender about the reply
    try {
      // Get original sender's push token
      const tokenResult = await sql`
        SELECT expo_push_token FROM employee_push_tokens WHERE user_id = ${originalSenderId} LIMIT 1
      `;
      
      if (tokenResult.length > 0 && tokenResult[0].expo_push_token) {
        console.log(`📱 Sending reply notification to ${originalSenderId}`);
        
        const pushResponse = await fetch("https://exp.host/--/api/v2/push/send", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            to: tokenResult[0].expo_push_token,
            sound: "default",
            title: `Reply from ${replierName}`,
            body: replyText.substring(0, 100) + (replyText.length > 100 ? '...' : ''),
            android: {
              channelId: "messages",
              actions: [
                {
                  title: "Reply",
                  actionId: "reply",
                  icon: "ic_reply",
                  type: "text",
                  placeholder: "Type a reply..."
                }
              ]
            },
            categoryId: "MESSAGE_REPLY",
            data: { 
              type: 'message_reply',
              notificationType: 'direct_message',
              senderId: replierId,
              senderType: replierType,
              senderName: replierName,
              messageId: result[0].id,
              conversationId: `${replierType}:${replierId}`,
              replyAction: "REPLY_TO_MESSAGE",
              timestamp: new Date().toISOString(),
              url: `yourapp://messages/${replierType}/${replierId}`
            }
          }),
        });
        
        console.log("📤 Reply notification sent to original sender");
      }
    } catch (pushError) {
      console.warn("⚠️ Could not send reply notification:", pushError.message);
    }

    // Send WebSocket notification if original sender is online
    sendToUser(originalSenderId, originalSenderType, {
      type: 'new_message',
      message: {
        id: result[0].id,
        sender_id: replierIdentifier,
        sender_type: replierType,
        receiver_id: originalSenderIdentifier,
        receiver_type: originalSenderType,
        message: replyText,
        time: result[0].time,
        sender_name: replierName,
        receiver_name: senderName, // Original sender's name
        pinned: false,
        read_status: false
      }
    });

    res.status(201).json({ 
      success: true, 
      message: "Reply sent successfully",
      data: {
        messageId: result[0].id,
        timestamp: result[0].time,
        sentTo: originalSenderId
      }
    });

  } catch (error) {
    console.error("❌ Error handling notification reply:", error);
    res.status(500).json({ 
      success: false, 
      message: "Server error",
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
}

/**
 * 📌 Pin/Unpin a message
 */
export async function togglePinMessage(req, res) {
  try {
    const { message_id } = req.params;
    const { pinned } = req.body;

    if (typeof pinned !== 'boolean') {
      return res.status(400).json({ 
        success: false, 
        message: "Pinned status is required and must be boolean" 
      });
    }

    // Create admin_messages table if it doesn't exist
    await createAdminMessagesTable();

    await sql`
      UPDATE admin_messages 
      SET pinned = ${pinned} 
      WHERE id = ${message_id};
    `;

    res.status(200).json({ 
      success: true, 
      message: `Message ${pinned ? 'pinned' : 'unpinned'} successfully` 
    });
  } catch (error) {
    console.error("❌ Error toggling pin status:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
}

/**
 * 📊 Get message statistics for admin dashboard
 */
export async function getMessageStats(req, res) {
  try {
    const { admin_id, admin_type } = req.query;

    if (!admin_id || !admin_type) {
      return res.status(400).json({ 
        success: false, 
        message: "Missing admin_id or admin_type" 
      });
    }

    // Create admin_messages table if it doesn't exist
    await createAdminMessagesTable();

    const senderIdentifier = `${admin_type}:${admin_id}`;

    const stats = await sql`
      SELECT 
        COUNT(*) as total_messages,
        SUM(CASE WHEN read_status = false AND receiver_id = ${senderIdentifier} THEN 1 ELSE 0 END) as unread_count,
        SUM(CASE WHEN pinned = true THEN 1 ELSE 0 END) as pinned_count,
        COUNT(DISTINCT CASE WHEN sender_id != ${senderIdentifier} THEN sender_id END) as unique_senders
      FROM admin_messages
      WHERE sender_id = ${senderIdentifier} OR receiver_id = ${senderIdentifier};
    `;

    res.status(200).json({ 
      success: true, 
      data: stats[0] || {
        total_messages: 0,
        unread_count: 0,
        pinned_count: 0,
        unique_senders: 0
      }
    });
  } catch (error) {
    console.error("❌ Error fetching message stats:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
}

/**
 * 🔄 Mark messages as read
 */
export async function markMessagesAsRead(req, res) {
  try {
    const { admin_id, admin_type, contact_id, contact_type } = req.body;

    if (!admin_id || !admin_type || !contact_id || !contact_type) {
      return res.status(400).json({ 
        success: false, 
        message: "Missing required fields" 
      });
    }

    // Create admin_messages table if it doesn't exist
    await createAdminMessagesTable();

    const receiverIdentifier = `${admin_type}:${admin_id}`;
    const senderIdentifier = `${contact_type}:${contact_id}`;

    await sql`
      UPDATE admin_messages 
      SET read_status = true 
      WHERE sender_id = ${senderIdentifier} 
        AND receiver_id = ${receiverIdentifier}
        AND read_status = false;
    `;

    res.status(200).json({ 
      success: true, 
      message: "Messages marked as read" 
    });
  } catch (error) {
    console.error("❌ Error marking messages as read:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
}