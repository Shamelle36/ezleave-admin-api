import sql from './config/db.js';
import { WebSocketServer } from 'ws';

// Store connected clients
export const clients = new Map();

export const setupWebSocketServer = (server) => {
  const wss = new WebSocketServer({ server });

  wss.on('connection', (ws, req) => {
    console.log('🔗 New WebSocket connection');
    console.log('📋 Request URL:', req.url);
    console.log('🔍 Headers:', req.headers);
    
    // ✅ FIX: Parse parameters properly from URL
    let userId = null;
    let userType = null;
    
    // Extract query parameters from URL
    const url = req.url;
    if (url.includes('?')) {
      const queryString = url.split('?')[1];
      const params = new URLSearchParams(queryString);
      
      // Accept both userId/userType and adminId/adminType
      userId = params.get('userId') || params.get('adminId');
      userType = params.get('userType') || params.get('adminType');
    }
    
    console.log(`📊 Parsed connection params - userId: ${userId}, userType: ${userType}`);
    
    if (!userId || !userType) {
      console.log('❌ Missing userId/userType or adminId/adminType in connection');
      ws.close(1008, 'Missing user identification');
      return;
    }

    // ✅ CRITICAL FIX: Ensure consistent ID format
    const clientId = `${userType}:${userId}`;
    
    // Remove any existing connection for this client (prevent duplicates)
    if (clients.has(clientId)) {
      const oldClient = clients.get(clientId);
      if (oldClient.ws.readyState === WebSocket.OPEN) {
        oldClient.ws.close(1000, 'New connection replacing old one');
      }
      clients.delete(clientId);
    }
    
    // Store client with metadata
    clients.set(clientId, {
      ws: ws,
      userId: userId,
      userType: userType,
      connectedAt: new Date(),
      ip: req.socket.remoteAddress
    });
    
    console.log(`✅ Client connected: ${clientId}`);
    console.log(`📊 Total connected clients: ${clients.size}`);
    
    // Log all connected clients for debugging
    console.log('📋 Connected clients list:', Array.from(clients.keys()));
    
    // Send connection confirmation
    try {
      ws.send(JSON.stringify({
        type: 'connection_established',
        clientId: clientId,
        userId: userId,
        userType: userType,
        timestamp: new Date().toISOString(),
        message: 'WebSocket connection established successfully'
      }));
    } catch (error) {
      console.error('❌ Error sending connection confirmation:', error);
    }

    // Broadcast online status to relevant users
    broadcastOnlineStatus(userId, userType, true);

    ws.on('message', async (message) => {
      try {
        const data = JSON.parse(message);
        console.log('📨 WebSocket message received from', clientId, ':', data.type || 'unknown');
        
        switch(data.type) {
          case 'new_message':
            await handleNewMessage(data, clientId);
            break;
          case 'typing':
            handleTyping(data, clientId);
            break;
          case 'messages_read':
            handleMessagesRead(data, clientId);
            break;
          case 'ping':
            // Handle ping for connection keep-alive
            ws.send(JSON.stringify({ 
              type: 'pong',
              timestamp: new Date().toISOString() 
            }));
            break;
          case 'connection':
            // Acknowledge connection message
            console.log('👋 Connection message from', clientId);
            break;
          default:
            console.log('❓ Unknown message type from', clientId, ':', data.type);
        }
      } catch (error) {
        console.error('❌ Error processing WebSocket message from', clientId, ':', error);
        console.error('📨 Raw message:', message.toString());
      }
    });

    ws.on('close', (code, reason) => {
      const clientData = clients.get(clientId);
      if (clientData) {
        console.log(`🔌 Client disconnected: ${clientId} - Code: ${code}, Reason: ${reason || 'No reason'}`);
        
        // Broadcast offline status before deleting
        broadcastOnlineStatus(userId, userType, false);
        clients.delete(clientId);
        
        console.log(`📊 Remaining connected clients: ${clients.size}`);
        console.log('📋 Remaining clients:', Array.from(clients.keys()));
      }
    });

    ws.on('error', (error) => {
      console.error('❌ WebSocket error for', clientId, ':', error);
      
      if (clients.has(clientId)) {
        const clientData = clients.get(clientId);
        if (clientData) {
          broadcastOnlineStatus(userId, userType, false);
        }
        clients.delete(clientId);
      }
    });

    // Set up heartbeat for this connection
    setupHeartbeat(ws, clientId);
  });

  console.log('🚀 WebSocket server is running');
  
  // Periodic cleanup of disconnected clients
  setInterval(() => {
    cleanupDisconnectedClients();
  }, 60000); // Cleanup every minute
};

// ✅ Enhanced sendToUser function with better error handling
export const sendToUser = (userId, userType, message) => {
  const clientId = `${userType}:${userId}`;
  
  console.log(`🔍 Looking for WebSocket client: ${clientId}`);
  console.log(`📊 Currently connected clients:`, Array.from(clients.keys()));
  
  const clientData = clients.get(clientId);
  
  if (!clientData) {
    console.log(`❌ WebSocket client not found: ${clientId}`);
    return false;
  }
  
  if (clientData.ws.readyState !== WebSocket.OPEN) {
    console.log(`❌ WebSocket client not connected/ready: ${clientId}, State: ${clientData.ws.readyState}`);
    
    // Remove stale client
    if (clients.has(clientId)) {
      clients.delete(clientId);
    }
    return false;
  }
  
  try {
    console.log(`✅ Sending WebSocket message to ${clientId}:`, message.type || message);
    const messageString = JSON.stringify(message);
    clientData.ws.send(messageString);
    return true;
  } catch (error) {
    console.error(`❌ Error sending to ${clientId}:`, error);
    
    // Remove problematic client
    if (clients.has(clientId)) {
      clients.delete(clientId);
    }
    return false;
  }
};

// ✅ Enhanced broadcastOnlineStatus
const broadcastOnlineStatus = (userId, userType, isOnline) => {
  const status = isOnline ? 'online' : 'offline';
  console.log(`📢 Broadcasting ${status} status for ${userType}:${userId}`);
  
  const statusMessage = {
    type: 'online_status',
    userId: userId,
    userType: userType,
    isOnline: isOnline,
    timestamp: new Date().toISOString()
  };
  
  let sentCount = 0;
  clients.forEach((clientData, clientId) => {
    // Don't send to self
    if (clientId === `${userType}:${userId}`) {
      return;
    }
    
    if (clientData.ws.readyState === WebSocket.OPEN) {
      try {
        clientData.ws.send(JSON.stringify(statusMessage));
        sentCount++;
      } catch (error) {
        console.error(`❌ Error sending online status to ${clientId}:`, error);
      }
    }
  });
  
  console.log(`📤 Online status sent to ${sentCount} clients`);
};

// ✅ Enhanced handleTyping
const handleTyping = (data, senderId) => {
  const { receiverId, receiverType, isTyping } = data;
  const receiverClientId = `${receiverType}:${receiverId}`;
  
  console.log(`⌨️ Typing status: ${senderId} -> ${receiverClientId}: ${isTyping}`);
  
  const receiverClient = clients.get(receiverClientId);
  if (receiverClient && receiverClient.ws.readyState === WebSocket.OPEN) {
    try {
      const typingMessage = {
        type: 'typing',
        senderId: senderId.split(':')[1],
        senderType: senderId.split(':')[0],
        isTyping: isTyping,
        timestamp: new Date().toISOString()
      };
      
      receiverClient.ws.send(JSON.stringify(typingMessage));
      console.log(`✅ Typing indicator sent to ${receiverClientId}`);
    } catch (error) {
      console.error(`❌ Error sending typing indicator to ${receiverClientId}:`, error);
    }
  } else {
    console.log(`❌ Cannot send typing indicator - receiver ${receiverClientId} is offline`);
  }
};

// ✅ Enhanced handleMessagesRead
const handleMessagesRead = (data, senderId) => {
  const { senderId: contactId, senderType: contactType } = data;
  const contactClientId = `${contactType}:${contactId}`;
  
  console.log(`📖 Messages read notification: ${senderId} -> ${contactClientId}`);
  
  const contactClient = clients.get(contactClientId);
  if (contactClient && contactClient.ws.readyState === WebSocket.OPEN) {
    try {
      contactClient.ws.send(JSON.stringify({
        type: 'message_read',
        senderId: senderId.split(':')[1],
        senderType: senderId.split(':')[0],
        timestamp: new Date().toISOString()
      }));
      console.log(`✅ Messages read notification sent to ${contactClientId}`);
    } catch (error) {
      console.error(`❌ Error sending read notification to ${contactClientId}:`, error);
    }
  }
};

// ✅ Setup heartbeat for a specific connection
const setupHeartbeat = (ws, clientId) => {
  let isAlive = true;
  
  const heartbeatInterval = setInterval(() => {
    if (!isAlive) {
      console.log(`💀 Client ${clientId} failed heartbeat, terminating`);
      ws.terminate();
      clearInterval(heartbeatInterval);
      
      if (clients.has(clientId)) {
        const clientData = clients.get(clientId);
        if (clientData) {
          broadcastOnlineStatus(clientData.userId, clientData.userType, false);
        }
        clients.delete(clientId);
      }
      return;
    }
    
    isAlive = false;
    
    try {
      if (ws.readyState === WebSocket.OPEN) {
        ws.ping();
      } else {
        clearInterval(heartbeatInterval);
      }
    } catch (error) {
      console.error(`❌ Error sending ping to ${clientId}:`, error);
      clearInterval(heartbeatInterval);
    }
  }, 30000); // 30 seconds
  
  ws.on('pong', () => {
    isAlive = true;
  });
  
  ws.on('close', () => {
    clearInterval(heartbeatInterval);
  });
};

// ✅ Cleanup disconnected clients
const cleanupDisconnectedClients = () => {
  const initialCount = clients.size;
  let removedCount = 0;
  
  clients.forEach((clientData, clientId) => {
    if (clientData.ws.readyState !== WebSocket.OPEN) {
      console.log(`🧹 Removing stale client: ${clientId}`);
      clients.delete(clientId);
      removedCount++;
      
      // Broadcast offline status
      if (clientData.userId && clientData.userType) {
        broadcastOnlineStatus(clientData.userId, clientData.userType, false);
      }
    }
  });
  
  if (removedCount > 0) {
    console.log(`🧹 Cleanup removed ${removedCount} stale clients. Remaining: ${clients.size}`);
  }
};

// ✅ Get all connected clients (for debugging/admin)
export const getConnectedClients = () => {
  const connectedList = [];
  
  clients.forEach((clientData, clientId) => {
    connectedList.push({
      clientId: clientId,
      userId: clientData.userId,
      userType: clientData.userType,
      connectedAt: clientData.connectedAt,
      readyState: clientData.ws.readyState,
      ip: clientData.ip
    });
  });
  
  return connectedList;
};

// ✅ Check if a user is online
export const isUserOnline = (userId, userType) => {
  const clientId = `${userType}:${userId}`;
  const clientData = clients.get(clientId);
  
  return !!(clientData && clientData.ws.readyState === WebSocket.OPEN);
};

// ✅ Send message to multiple users
export const sendToUsers = (userList, message) => {
  let successCount = 0;
  let failCount = 0;
  
  userList.forEach(({ userId, userType }) => {
    const sent = sendToUser(userId, userType, message);
    if (sent) {
      successCount++;
    } else {
      failCount++;
    }
  });
  
  return { successCount, failCount };
};

// ✅ Broadcast to all connected clients
export const broadcastToAll = (message) => {
  let sentCount = 0;
  let failCount = 0;
  
  clients.forEach((clientData, clientId) => {
    if (clientData.ws.readyState === WebSocket.OPEN) {
      try {
        clientData.ws.send(JSON.stringify(message));
        sentCount++;
      } catch (error) {
        console.error(`❌ Error broadcasting to ${clientId}:`, error);
        failCount++;
      }
    }
  });
  
  console.log(`📢 Broadcast completed: ${sentCount} sent, ${failCount} failed`);
  return { sentCount, failCount };
};

// Add this function to your websocket.js
const handleNewMessage = async (data, senderId) => {
  try {
    const { receiverId, receiverType, message } = data;
    const receiverClientId = `${receiverType}:${receiverId}`;
    
    console.log(`📤 Forwarding message from ${senderId} to ${receiverClientId}`);
    
    // Forward message to receiver if online
    const receiverClient = clients.get(receiverClientId);
    if (receiverClient && receiverClient.ws.readyState === WebSocket.OPEN) {
      receiverClient.ws.send(JSON.stringify({
        type: 'new_message',
        message: message,
        senderId: senderId.split(':')[1],
        senderType: senderId.split(':')[0],
        timestamp: new Date().toISOString()
      }));
      console.log(`✅ Message forwarded to ${receiverClientId}`);
    } else {
      console.log(`❌ Receiver ${receiverClientId} is offline`);
    }
  } catch (error) {
    console.error('❌ Error handling new message:', error);
  }
};

export default {
  setupWebSocketServer,
  sendToUser,
  sendToUsers,
  broadcastToAll,
  getConnectedClients,
  isUserOnline,
  clients,
  handleNewMessage
};