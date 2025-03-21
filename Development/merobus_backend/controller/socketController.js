const express = require("express");
const http = require("http");
const socketIO = require("socket.io");
const { logger } = require("../utils/logger");
const prisma = require("../utils/prisma");

const app = express();
const server = http.createServer(app);

const io = socketIO(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
    credentials: true,
  },
  transports: ["websocket"],
  upgradeTimeout: 0,
  upgrade: false,
  pingInterval: 10000,
  pingTimeout: 60000,
  connectTimeout: 60000,
  polling: {
    requestTimeout: 60000,
  },
  allowEIO3: true,
  maxHttpBufferSize: 5e6,
});

app.get("/", (req, res) => {
  res.send("Socket.io server is running");
});

app.get("/socket-status", (req, res) => {
  res.json({
    activeConnections: io.engine.clientsCount,
    socketIds: Object.keys(io.sockets.sockets),
  });
});

const activeUsers = new Map();
const userSocketMapping = new Map();

io.on("connection", (socket) => {
  const transport = socket.conn.transport.name;
  logger.info(`New client connected: ${socket.id} (transport: ${transport})`);

  let heartbeatInterval;
  const startHeartbeat = () => {
    clearInterval(heartbeatInterval);
    heartbeatInterval = setInterval(() => {
      if (socket.connected) {
        socket.emit("__ping");
      } else {
        clearInterval(heartbeatInterval);
      }
    }, 10000);
  };

  startHeartbeat();

  socket.on("__pong", () => {
    logger.debug(`Received heartbeat response from ${socket.id}`);
  });

  socket.on("login", async (userId) => {
    try {
      userId = userId.toString();
      logger.info(
        `User ${userId} logged in via socket ${socket.id} (transport: ${socket.conn.transport.name})`
      );

      userSocketMapping.set(socket.id, userId);

      activeUsers.set(userId, {
        socketId: socket.id,
        socket: socket,
      });

      socket.broadcast.emit("user_status", { userId, status: "online" });

      const activeUsersList = Array.from(activeUsers.keys());
      socket.emit("active_users", activeUsersList);

      socket.emit("login_success", { userId });
    } catch (error) {
      logger.error(`Error during login: ${error.message}`);
      socket.emit("error", { message: "Login failed", error: error.message });
    }
  });

  socket.on("ping", () => {
    logger.info(`Received ping from ${socket.id}`);
    socket.emit("pong", { time: new Date().toISOString() });
  });

  socket.on("send_message", async (data) => {
    try {
      logger.info(`Message from user ${data.senderId}: ${data.text}`);
      const { senderId, chatGroupId, text } = data;

      if (!senderId || !chatGroupId || !text) {
        throw new Error("Missing required fields");
      }

      try {
        const chatGroup = await prisma.chatGroup.findUnique({
          where: { id: parseInt(chatGroupId) },
        });

        if (!chatGroup) {
          throw new Error("Chat group not found");
        }

        const newMessage = await prisma.message.create({
          data: {
            text,
            senderId: parseInt(senderId),
            chatGroupId: parseInt(chatGroupId),
            isRead: false,
          },
          include: {
            sender: {
              select: {
                id: true,
                username: true,
              },
            },
          },
        });

        const chatGroupWithUsers = await prisma.chatGroup.findUnique({
          where: { id: parseInt(chatGroupId) },
        });

        if (!chatGroupWithUsers || !chatGroupWithUsers.users) {
          logger.warn(`No users found in chat group ${chatGroupId}`);
        } else {
          chatGroupWithUsers.users.forEach((user) => {
            const userId = user.id.toString();
            if (activeUsers.has(userId) && userId !== senderId.toString()) {
              const userInfo = activeUsers.get(userId);
              if (userInfo && userInfo.socket && userInfo.socket.connected) {
                userInfo.socket.emit("new_message", {
                  id: newMessage.id,
                  text: newMessage.text,
                  senderId: newMessage.senderId,
                  senderName: newMessage.sender.username,
                  chatGroupId: newMessage.chatGroupId,
                  createdAt: newMessage.createdAt,
                  isRead: newMessage.isRead,
                });
              }
            }
          });
        }

        socket.emit("message_sent", {
          id: newMessage.id,
          text: newMessage.text,
          senderId: newMessage.senderId,
          senderName: newMessage.sender.username,
          chatGroupId: newMessage.chatGroupId,
          createdAt: newMessage.createdAt,
          isRead: newMessage.isRead,
        });
      } catch (dbError) {
        logger.error(`Database error: ${dbError.message}`);
        socket.emit("error", {
          message: "Database error",
          error: dbError.message,
        });
      }
    } catch (error) {
      logger.error(`Error sending message: ${error.message}`);
      socket.emit("error", {
        message: "Failed to send message",
        error: error.message,
      });
    }
  });

  socket.on("message_read", async (messageId) => {
    try {
      await prisma.message.update({
        where: { id: parseInt(messageId) },
        data: { isRead: true },
      });

      socket.emit("message_read_confirmed", { messageId });
    } catch (error) {
      logger.error(`Error marking message as read: ${error.message}`);
      socket.emit("error", {
        message: "Failed to mark message as read",
        error: error.message,
      });
    }
  });

  socket.on("typing", (data) => {
    try {
      const { userId, chatGroupId } = data;
      socket.to(`group_${chatGroupId}`).emit("user_typing", { userId });
    } catch (error) {
      logger.error(`Error in typing event: ${error.message}`);
    }
  });

  socket.on("join_group", (data) => {
    try {
      const { userId, chatGroupId } = data;
      socket.join(`group_${chatGroupId}`);
      logger.info(`User ${userId} joined group chat ${chatGroupId}`);
      socket.emit("group_joined", { chatGroupId });
    } catch (error) {
      logger.error(`Error joining group: ${error.message}`);
      socket.emit("error", {
        message: "Failed to join group",
        error: error.message,
      });
    }
  });

  socket.on("leave_group", (data) => {
    try {
      const { userId, chatGroupId } = data;
      socket.leave(`group_${chatGroupId}`);
      logger.info(`User ${userId} left group chat ${chatGroupId}`);
      socket.emit("group_left", { chatGroupId });
    } catch (error) {
      logger.error(`Error leaving group: ${error.message}`);
      socket.emit("error", {
        message: "Failed to leave group",
        error: error.message,
      });
    }
  });

  socket.on("fetch_group_history", async (data) => {
    try {
      const { chatGroupId } = data;
      logger.info(`Fetching history for group ${chatGroupId}`);

      const messages = await prisma.message.findMany({
        where: {
          chatGroupId: parseInt(chatGroupId),
        },
        include: {
          sender: {
            select: {
              id: true,
              username: true,
            },
          },
        },
        orderBy: { createdAt: "asc" },
      });

      const formattedMessages = messages.map((msg) => ({
        id: msg.id,
        text: msg.text,
        senderId: msg.senderId,
        senderName: msg.sender?.username || "Unknown User",
        chatGroupId: msg.chatGroupId,
        createdAt: msg.createdAt,
        isRead: msg.isRead,
      }));

      socket.emit("group_history", formattedMessages);
    } catch (error) {
      logger.error(`Error fetching group history: ${error.message}`);
      socket.emit("error", {
        message: "Failed to fetch group chat history",
        error: error.message,
      });
    }
  });

  socket.on("logout", (userId) => {
    try {
      userId = userId.toString();
      logger.info(`User ${userId} logged out`);

      if (activeUsers.has(userId)) {
        activeUsers.delete(userId);
        userSocketMapping.delete(socket.id);
        socket.broadcast.emit("user_status", { userId, status: "offline" });
      }
    } catch (error) {
      logger.error(`Error during logout: ${error.message}`);
    }
  });

  socket.on("disconnect", (reason) => {
    try {
      logger.info(`Client disconnected: ${socket.id}, reason: ${reason}`);

      clearInterval(heartbeatInterval);

      const userId = userSocketMapping.get(socket.id);
      if (userId) {
        userSocketMapping.delete(socket.id);

        const userInfo = activeUsers.get(userId);
        if (userInfo && userInfo.socketId === socket.id) {
          activeUsers.delete(userId);
          socket.broadcast.emit("user_status", { userId, status: "offline" });
        }
      }
    } catch (error) {
      logger.error(`Error during disconnect handling: ${error.message}`);
    }
  });

  socket.on("error", (error) => {
    logger.error(`Socket error for ${socket.id}: ${error}`);
  });
});

module.exports = { app, server, io, activeUsers };
