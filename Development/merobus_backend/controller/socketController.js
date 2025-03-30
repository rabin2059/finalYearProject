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
const activeBuses = new Map();

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

  socket.on("check_group_membership", async (data) => {
    try {
      const { userId, chatGroupId } = data;
      const userIdInt = parseInt(userId);
      const chatGroupIdInt = parseInt(chatGroupId);

      logger.info(
        `Checking if user ${userId} is member of group ${chatGroupId}`
      );

      // Find if the user is a member of the chat group
      const membership = await prisma.userChatGroup.findUnique({
        where: {
          userId_chatGroupId: {
            userId: userIdInt,
            chatGroupId: chatGroupIdInt,
          },
        },
      });

      const isMember = !!membership;

      // If user is a member, make sure they're in the socket room
      if (isMember) {
        socket.join(`group_${chatGroupId}`);
      }

      const isInRoom = socket.rooms.has(`group_${chatGroupId}`);
      const joinedAt = membership?.joinedAt || new Date();

      socket.emit("membership_status", {
        userId,
        chatGroupId,
        isMember,
        isInRoom,
        joinedAt: joinedAt.toISOString(),
      });

      // Join the room if needed
      if (isMember && !isInRoom) {
        socket.join(`group_${chatGroupId}`);
      }
    } catch (error) {
      logger.error(`Error checking group membership: ${error.message}`);
      socket.emit("error", {
        message: "Failed to check group membership",
        error: error.message,
      });
    }
  });

  socket.on("fetch_messages_since", async (data) => {
    try {
      const { chatGroupId, since } = data;
      logger.info(`Fetching messages for group ${chatGroupId} since ${since}`);

      const sinceDate = new Date(since);

      const messages = await prisma.message.findMany({
        where: {
          chatGroupId: parseInt(chatGroupId),
          createdAt: {
            gte: sinceDate,
          },
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

      socket.emit("messages_since", formattedMessages);
    } catch (error) {
      logger.error(`Error fetching messages since date: ${error.message}`);
      socket.emit("error", {
        message: "Failed to fetch messages",
        error: error.message,
      });
    }
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
          include: {
            users: {
              select: {
                id: true,
                username: true,
              },
            },
          },
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
                  chatGroupId: newMessage.chatGroupId,
                  createdAt: newMessage.createdAt,
                  isRead: newMessage.isRead,
                  senderName: newMessage.sender?.username || "Unknown User",
                });
              }
            }
          });
        }

        socket.emit("message_sent", {
          id: newMessage.id,
          text: newMessage.text,
          senderId: newMessage.senderId,
          chatGroupId: newMessage.chatGroupId,
          createdAt: newMessage.createdAt,
          isRead: newMessage.isRead,
          senderName: newMessage.sender?.username || "Unknown User",
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

  socket.on("join_group", async (data) => {
    try {
      const { userId, chatGroupId } = data;
      const userIdInt = parseInt(userId);
      const chatGroupIdInt = parseInt(chatGroupId);

      // Check if user is already a member
      const existingMembership = await prisma.userChatGroup.findUnique({
        where: {
          userId_chatGroupId: {
            userId: userIdInt,
            chatGroupId: chatGroupIdInt,
          },
        },
      });

      if (existingMembership) {
        // User is already a member, just join the socket room
        socket.join(`group_${chatGroupId}`);
        socket.emit("group_joined", {
          chatGroupId,
          joinedAt: existingMembership.joinedAt.toISOString(),
        });
        return;
      }

      const now = new Date();

      // First connect the user to the chat group (many-to-many relation)
      const updatedGroup = await prisma.chatGroup.update({
        where: {
          id: chatGroupIdInt,
        },
        data: {
          users: {
            connect: {
              id: userIdInt,
            },
          },
        },
        include: {
          users: {
            select: {
              id: true,
              username: true,
            },
          },
        },
      });

      // Then create the UserChatGroup entry with the join date
      await prisma.userChatGroup.create({
        data: {
          userId: userIdInt,
          chatGroupId: chatGroupIdInt,
          joinedAt: now,
          isActive: true,
        },
      });

      // Join the socket room
      socket.join(`group_${chatGroupId}`);

      // Notify other users in the group
      socket.to(`group_${chatGroupId}`).emit("group_members_updated", {
        chatGroupId,
        users: updatedGroup.users,
      });

      logger.info(`User ${userId} joined group chat ${chatGroupId}`);
      socket.emit("group_joined", {
        chatGroupId,
        joinedAt: now.toISOString(),
      });
    } catch (error) {
      logger.error(`Error joining group: ${error.message}`);
      socket.emit("error", {
        message: "Failed to join group",
        error: error.message,
      });
    }
  });

  async function getUserJoinDate(userId, chatGroupId) {
    try {
      const userChatGroup = await prisma.userChatGroup.findUnique({
        where: {
          userId_chatGroupId: {
            userId: userId,
            chatGroupId: chatGroupId,
          },
        },
      });

      return userChatGroup?.joinedAt || null;
    } catch (error) {
      logger.error(`Error getting user join date: ${error.message}`);
      return null;
    }
  }

  socket.on("join_room", (data) => {
    try {
      const { chatGroupId } = data;
      socket.join(`group_${chatGroupId}`);
      logger.info(`Socket ${socket.id} joined room for group ${chatGroupId}`);
    } catch (error) {
      logger.error(`Error joining room: ${error.message}`);
      socket.emit("error", {
        message: "Failed to join room",
        error: error.message,
      });
    }
  });

  socket.on("leave_group", async (data) => {
    try {
      const { userId, chatGroupId } = data;
      const userIdInt = parseInt(userId);
      const chatGroupIdInt = parseInt(chatGroupId);

      // Update the UserChatGroup to mark it as inactive instead of deleting
      await prisma.userChatGroup.update({
        where: {
          userId_chatGroupId: {
            userId: userIdInt,
            chatGroupId: chatGroupIdInt,
          },
        },
        data: {
          isActive: false,
        },
      });

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

  socket.on("register-driver", (data) => {
    const { vehicleId } = data;

    logger.info(`Driver registered for vehicle ${vehicleId}`);

    activeBuses.set(vehicleId, {
      socketId: socket.id,
      location: null,
      isActive: true,
      lastUpdated: new Date(),
    });

    const activeDriverList = Array.from(activeBuses.keys());
    socket.emit("active_buses", activeDriverList);
  });

  socket.on("get_active_buses", () => {
    const activeDriverList = Array.from(activeBuses.keys());
    console.log(activeDriverList);
    logger.info(`Sending active buses: ${activeDriverList}`);
    socket.emit("active_buses", activeDriverList);
  });

  socket.on("driver-location", ({ vehicleId, lat, lng }) => {
    if (activeBuses.has(vehicleId)) {
      activeBuses.get(vehicleId).location = { lat, lng };
      io.emit("vehicle-location", { vehicleId, lat, lng });
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
      for (const [vehicleId, data] of activeBuses.entries()) {
        if (data.socketId === socket.id) {
          activeBuses.delete(vehicleId);
          logger.info(`Vehicle ${vehicleId} removed from active buses`);
          break;
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

module.exports = { app, server, io, activeUsers, activeBuses };
