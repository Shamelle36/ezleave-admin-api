import sql from "../config/db.js";
import { sendToUser } from "../websocket.js";
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
      ) RETURNING id, time;
    `;

    console.log('✅ Message inserted successfully:', result[0]);

    // Prepare response data
    const responseData = {
      message_id: result[0].id,
      sent_at: result[0].time,
      sender: {
        id: sender_id,
        type: sender_type,
        name: senderName,
        email: senderEmail
      },
      receiver: {
        id: receiver_id,
        type: receiver_type,
        name: receiverName,
        email: receiverEmail
      },
      message: message
    };

    sendToUser(receiver_id, receiver_type, {
      type: 'new_message',
      message: responseData
    });

    sendToUser(sender_id, sender_type, {
      type: 'message_delivered',
      messageId: result[0].id
    });

    res.status(201).json({ 
      success: true, 
      message: "Message sent successfully",
      data: responseData
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