const express = require("express");
const { createServer } = require("http");
const { Server } = require("socket.io");

const app = express();
const server = createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*",
  },
});

const UserSocketMap = {};
const activeRooms = new Set(); // Track active chat rooms

function getReceiverSocketId(userId) {
  return UserSocketMap[userId];
}

io.on("connection", (socket) => {
  console.log("a user connected", socket.id);
  const userId = socket.handshake.query.userId;
  console.log("User Id:", userId);

  if (userId) {
    UserSocketMap[userId] = socket.id;
    // broadcast to all clients
    io.emit("getOnlineUsers", Object.keys(UserSocketMap));
  }

  // Handle joining a chat room
  socket.on("joinRoom", (roomId) => {
    socket.join(roomId);
    activeRooms.add(roomId);
    console.log(`User ${userId} joined room ${roomId}`);
  });

  // Handle leaving a chat room
  socket.on("leaveRoom", (roomId) => {
    socket.leave(roomId);
    console.log(`User ${userId} left room ${roomId}`);
  });

  // Handle group messages
  socket.on("sendMessage", ({ roomId, message }) => {
    // ✅ Use `socket.to(roomId).emit()` to send message to others in the room
    socket.to(roomId).emit("receiveMessage", message);
  });

  socket.on("disconnect", () => {
    console.log("user disconnected", socket.id);
    if (userId) {
      delete UserSocketMap[userId];
      // broadcast to all clients
      io.emit("getOnlineUsers", Object.keys(UserSocketMap));
    }
  });
});

module.exports = { io, app, server, getReceiverSocketId, activeRooms };
