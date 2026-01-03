// socket.js
import { Server } from "socket.io";

/**
 * Store connected clients
 * key: userType:userId
 * value: { socketId, userId, userType, connectedAt, ip }
 */
export const clients = new Map();

let io;

/**
 * 🔌 Setup Socket.IO Server
 */
export const setupSocketServer = (httpServer) => {
  io = new Server(httpServer, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
    },
    transports: ["websocket", "polling"], // Add polling as fallback
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  io.on("connection", (socket) => {
    console.log("🔗 New Socket.IO connection:", socket.id);

    /**
     * ✅ REGISTER USER
     */
    socket.on("register", ({ userId, userType }) => {
      if (!userId || !userType) {
        console.log("❌ Missing userId/userType during register");
        socket.disconnect();
        return;
      }

      const clientId = `${userType}:${userId}`;

      // Remove old connection (prevent duplicates)
      if (clients.has(clientId)) {
        const old = clients.get(clientId);
        io.sockets.sockets.get(old.socketId)?.disconnect(true);
        clients.delete(clientId);
      }

      socket.join(clientId);
      socket.join(`user:${userId}`); // Join user-specific room
      socket.join(`type:${userType}`); // Join type-specific room

      clients.set(clientId, {
        socketId: socket.id,
        userId,
        userType,
        connectedAt: new Date(),
        ip: socket.handshake.address,
      });

      console.log(`✅ Registered client: ${clientId}`);
      console.log("📊 Connected clients:", Array.from(clients.keys()));

      socket.emit("message", {
        type: "connection_established",
        clientId,
        userId,
        userType,
        timestamp: new Date().toISOString(),
      });

      // Notify others about online status
      broadcastOnlineStatus(userId, userType, true);
    });

    /**
     * ✉️ SEND MESSAGE - NEW EVENT HANDLER
     */
    socket.on("send_message", async (data) => {
      console.log("📤 Received send_message event:", data);
      
      const senderEntry = [...clients.entries()].find(
        ([_, c]) => c.socketId === socket.id
      );

      if (!senderEntry) {
        console.log("❌ Sender not found in connected clients");
        return;
      }

      const [senderClientId, senderInfo] = senderEntry;
      const [senderType, senderId] = senderClientId.split(":");
      
      const { receiverId, receiverType, message, tempId } = data;
      
      if (!receiverId || !receiverType || !message) {
        console.log("❌ Missing receiver info or message");
        return;
      }

      const receiverKey = `${receiverType}:${receiverId}`;
      
      // Forward message to receiver if online
      if (clients.has(receiverKey)) {
        console.log(`📨 Forwarding message to ${receiverKey}`);
        
        io.to(receiverKey).emit("message", {
          type: "new_message",
          message: {
            id: tempId || Date.now(),
            sender_id: senderClientId,
            sender_type: senderType,
            receiver_id: receiverKey,
            receiver_type: receiverType,
            message: message,
            time: new Date().toISOString(),
            pinned: false,
            read_status: false,
            sender_name: senderInfo.userId, // You might want to get actual name
            delivered: true
          },
          timestamp: new Date().toISOString(),
        });
      } else {
        console.log(`❌ Receiver ${receiverKey} is offline, message will be delivered via API`);
      }

      // Send confirmation to sender
      socket.emit("message", {
        type: "message_sent",
        tempId,
        message: "Message delivered via WebSocket",
        timestamp: new Date().toISOString(),
      });
    });

    /**
     * ✉️ INCOMING SOCKET EVENTS
     */
    socket.on("message", async (data) => {
      console.log("📥 Received message event:", data);
      
      if (!data?.type) return;

      const senderEntry = [...clients.entries()].find(
        ([_, c]) => c.socketId === socket.id
      );

      if (!senderEntry) return;
      const [senderClientId] = senderEntry;

      switch (data.type) {
        case "typing":
          handleTyping(data, senderClientId);
          break;

        case "messages_read":
          handleMessagesRead(data, senderClientId);
          break;

        case "ping":
          socket.emit("message", { type: "pong" });
          break;
      }
    });

    /**
     * 🔌 DISCONNECT
     */
    socket.on("disconnect", (reason) => {
      console.log(`🔴 Socket disconnected: ${socket.id}, Reason: ${reason}`);
      
      for (const [clientId, client] of clients.entries()) {
        if (client.socketId === socket.id) {
          console.log(`🔴 Removing from clients: ${clientId}`);
          broadcastOnlineStatus(client.userId, client.userType, false);
          clients.delete(clientId);
          break;
        }
      }
    });

    socket.on("error", (error) => {
      console.error("❌ Socket error:", error);
    });
  });

  console.log("🚀 Socket.IO server running");
  return io;
};

/**
 * ✅ Send message to a single user - UPDATED
 */
export const sendToUser = (userId, userType, payload) => {
  if (!io) {
    console.log("❌ Socket.IO not initialized");
    return false;
  }

  const clientId = `${userType}:${userId}`;
  console.log(`📤 Attempting to send to ${clientId}`, payload);

  // Check if user is connected
  if (!clients.has(clientId)) {
    console.log(`❌ User ${clientId} is not connected`);
    return false;
  }

  // Send to specific user room
  io.to(clientId).emit("message", payload);
  console.log(`✅ Message sent to ${clientId}`);
  return true;
};

/**
 * ✅ Send to multiple users
 */
export const sendToUsers = (userList, payload) => {
  let successCount = 0;
  let failCount = 0;

  userList.forEach(({ userId, userType }) => {
    sendToUser(userId, userType, payload)
      ? successCount++
      : failCount++;
  });

  console.log(`📤 Sent to ${successCount} users, failed for ${failCount}`);
  return { successCount, failCount };
};

/**
 * 📢 Broadcast to all connected clients
 */
export const broadcastToAll = (payload) => {
  if (!io) return;
  io.emit("message", payload);
};

/**
 * 🟢 Online / Offline Status
 */
const broadcastOnlineStatus = (userId, userType, isOnline) => {
  const statusPayload = {
    type: "online_status",
    userId,
    userType,
    isOnline,
    timestamp: new Date().toISOString(),
  };

  // Emit to all connected clients except the user
  io.emit("message", statusPayload);
  
  console.log(`🌐 ${userId} (${userType}) is now ${isOnline ? 'online' : 'offline'}`);
};

/**
 * ⌨️ Typing Indicator
 */
const handleTyping = ({ receiverId, receiverType, isTyping }, senderId) => {
  console.log(`⌨️ Typing from ${senderId} to ${receiverType}:${receiverId}`);
  
  const receiverKey = `${receiverType}:${receiverId}`;
  
  if (clients.has(receiverKey)) {
    io.to(receiverKey).emit("message", {
      type: "typing",
      senderId: senderId.split(":")[1],
      senderType: senderId.split(":")[0],
      isTyping,
      timestamp: new Date().toISOString(),
    });
  }
};

/**
 * 📖 Read Receipts
 */
const handleMessagesRead = ({ senderId, senderType }, readerId) => {
  console.log(`📖 Read receipt from ${readerId} to ${senderType}:${senderId}`);
  
  const contactKey = `${senderType}:${senderId}`;
  
  if (clients.has(contactKey)) {
    io.to(contactKey).emit("message", {
      type: "message_read",
      readerId: readerId.split(":")[1],
      readerType: readerId.split(":")[0],
      timestamp: new Date().toISOString(),
    });
  }
};

/**
 * 🔍 Utilities
 */
export const getConnectedClients = () =>
  Array.from(clients.entries()).map(([clientId, c]) => ({
    clientId,
    userId: c.userId,
    userType: c.userType,
    connectedAt: c.connectedAt,
    socketId: c.socketId,
    ip: c.ip,
  }));

export const isUserOnline = (userId, userType) => {
  const isOnline = clients.has(`${userType}:${userId}`);
  console.log(`🔍 Check online status for ${userType}:${userId}: ${isOnline ? 'Online' : 'Offline'}`);
  return isOnline;
};

export default {
  setupSocketServer,
  sendToUser,
  sendToUsers,
  broadcastToAll,
  getConnectedClients,
  isUserOnline,
  clients,
};