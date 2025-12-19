// websocketServer.js
import sql from './config/db.js';
import { WebSocketServer } from 'ws';
// Store connected clients
export const clients = new Map();

export const setupWebSocketServer = (server) => {
  const wss = new WebSocketServer({ server });

  wss.on('connection', (ws, req) => {
    console.log('🔗 New WebSocket connection');
    
    // Parse query parameters
    const url = new URL(req.url, `http://${req.headers.host}`);
    const adminId = url.searchParams.get('adminId');
    const adminType = url.searchParams.get('adminType');
    
    if (!adminId || !adminType) {
      ws.close();
      return;
    }

    const clientId = `${adminType}:${adminId}`;
    
    // Store client connection
    clients.set(clientId, ws);
    console.log(`✅ Client connected: ${clientId}, Total clients: ${clients.size}`);

    // Send online status to relevant users
    broadcastOnlineStatus(clientId, true);

    ws.on('message', async (message) => {
      try {
        const data = JSON.parse(message);
        console.log('📨 WebSocket message:', data);

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
          default:
            console.log('Unknown message type:', data.type);
        }
      } catch (error) {
        console.error('❌ Error processing WebSocket message:', error);
      }
    });

    ws.on('close', () => {
      clients.delete(clientId);
      console.log(`🔌 Client disconnected: ${clientId}, Remaining clients: ${clients.size}`);
      
      // Send offline status to relevant users
      broadcastOnlineStatus(clientId, false);
    });

    ws.on('error', (error) => {
      console.error('❌ WebSocket error:', error);
      clients.delete(clientId);
    });
  });

  console.log('🚀 WebSocket server is running');
};

const broadcastOnlineStatus = (clientId, isOnline) => {
  const [userType, userId] = clientId.split(':');
  
  // Notify all clients who might be interested in this user's status
  // For simplicity, we'll notify all connected clients
  // In production, you'd want to only notify relevant contacts
  clients.forEach((client, id) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify({
        type: 'online_status',
        userId: userId,
        userType: userType,
        isOnline: isOnline
      }));
    }
  });
};

const handleNewMessage = async (data, senderId) => {
  try {
    const { receiverId, receiverType, message } = data;
    const receiverClientId = `${receiverType}:${receiverId}`;
    
    // Store message in database (if not already done by REST API)
    // Note: The REST API already stores the message, so we just forward it
    
    // Forward message to receiver if online
    const receiverClient = clients.get(receiverClientId);
    if (receiverClient && receiverClient.readyState === WebSocket.OPEN) {
      receiverClient.send(JSON.stringify({
        type: 'new_message',
        message: message,
        senderId: senderId
      }));
      
      // Send delivery confirmation to sender
      const senderClient = clients.get(senderId);
      if (senderClient && senderClient.readyState === WebSocket.OPEN) {
        senderClient.send(JSON.stringify({
          type: 'message_delivered',
          messageId: message.id
        }));
      }
    }
  } catch (error) {
    console.error('❌ Error handling new message:', error);
  }
};

const handleTyping = (data, senderId) => {
  const { receiverId, receiverType, isTyping } = data;
  const receiverClientId = `${receiverType}:${receiverId}`;
  
  const receiverClient = clients.get(receiverClientId);
  if (receiverClient && receiverClient.readyState === WebSocket.OPEN) {
    receiverClient.send(JSON.stringify({
      type: 'typing',
      senderId: senderId,
      isTyping: isTyping
    }));
  }
};

const handleMessagesRead = (data, senderId) => {
  const { senderId: contactId, senderType: contactType } = data;
  const contactClientId = `${contactType}:${contactId}`;
  
  const contactClient = clients.get(contactClientId);
  if (contactClient && contactClient.readyState === WebSocket.OPEN) {
    contactClient.send(JSON.stringify({
      type: 'message_read',
      senderId: senderId
    }));
  }
};

// Helper function to send message to specific user
export const sendToUser = (userId, userType, message) => {
  const clientId = `${userType}:${userId}`;
  const client = clients.get(clientId);
  
  if (client && client.readyState === WebSocket.OPEN) {
    client.send(JSON.stringify(message));
    return true;
  }
  return false;
};

// You can also export everything as a single object if preferred
export default {
  setupWebSocketServer,
  sendToUser,
  clients
};