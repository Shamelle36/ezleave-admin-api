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
    transports: ["websocket"],
  });

  io.on("connection", (socket) => {
    console.log("🔗 New Socket.IO connection:", socket.id);

    /**
     * ✅ REGISTER USER
     * replaces ws query parsing
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

      broadcastOnlineStatus(userId, userType, true);
    });

    /**
     * ✉️ INCOMING SOCKET EVENTS
     */
    socket.on("message", async (data) => {
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

        case "new_message":
          await handleNewMessage(data, senderClientId);
          break;

        case "ping":
          socket.emit("message", { type: "pong" });
          break;
      }
    });

    /**
     * 🔌 DISCONNECT
     */
    socket.on("disconnect", () => {
      for (const [clientId, client] of clients.entries()) {
        if (client.socketId === socket.id) {
          console.log(`🔴 Disconnected: ${clientId}`);
          broadcastOnlineStatus(client.userId, client.userType, false);
          clients.delete(clientId);
          break;
        }
      }
    });
  });

  console.log("🚀 Socket.IO server running");
};

/**
 * ✅ Send message to a single user
 */
export const sendToUser = (userId, userType, payload) => {
  if (!io) return false;

  const clientId = `${userType}:${userId}`;
  const client = clients.get(clientId);

  if (!client) {
    console.log(`❌ User offline: ${clientId}`);
    return false;
  }

  io.to(clientId).emit("message", payload);
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

  clients.forEach((_, clientId) => {
    if (clientId !== `${userType}:${userId}`) {
      io.to(clientId).emit("message", statusPayload);
    }
  });
};

/**
 * ⌨️ Typing Indicator
 */
const handleTyping = ({ receiverId, receiverType, isTyping }, senderId) => {
  const receiverKey = `${receiverType}:${receiverId}`;

  io.to(receiverKey).emit("message", {
    type: "typing",
    senderId: senderId.split(":")[1],
    senderType: senderId.split(":")[0],
    isTyping,
    timestamp: new Date().toISOString(),
  });
};

/**
 * 📖 Read Receipts
 */
const handleMessagesRead = ({ senderId, senderType }, readerId) => {
  const contactKey = `${senderType}:${senderId}`;

  io.to(contactKey).emit("message", {
    type: "message_read",
    senderId: readerId.split(":")[1],
    senderType: readerId.split(":")[0],
    timestamp: new Date().toISOString(),
  });
};

/**
 * ✉️ Forward message
 */
const handleNewMessage = async ({ receiverId, receiverType, message }, senderId) => {
  const receiverKey = `${receiverType}:${receiverId}`;

  io.to(receiverKey).emit("message", {
    type: "new_message",
    message,
    senderId: senderId.split(":")[1],
    senderType: senderId.split(":")[0],
    timestamp: new Date().toISOString(),
  });
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

export const isUserOnline = (userId, userType) =>
  clients.has(`${userType}:${userId}`);

export default {
  setupSocketServer,
  sendToUser,
  sendToUsers,
  broadcastToAll,
  getConnectedClients,
  isUserOnline,
  clients,
};
