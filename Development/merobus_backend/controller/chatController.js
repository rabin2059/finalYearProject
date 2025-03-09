const prisma = require("../utils/prisma.js");
const { io } = require("./socketController.js");
const fs = require("fs").promises;
const path = require("path");

// Create chat logs directory if it doesn't exist
const CHAT_LOGS_DIR = path.join(__dirname, "../chat_logs");
fs.mkdir(CHAT_LOGS_DIR, { recursive: true }).catch(console.error);

const saveMessageToFile = async (roomId, senderId, message) => {
  console.log("first");
  try {
    const logFile = path.join(CHAT_LOGS_DIR, `${roomId}.txt`);
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] ${senderId || "Unknown"}: ${
      message.text
    }\n`;

    console.log(`📂 Saving message to: ${logFile}`); // ✅ Debug: Check file path
    console.log(`✍️ Log Entry: ${logEntry}`); // ✅ Debug: Check log entry content

    await fs.appendFile(logFile, logEntry, "utf8");

    console.log("✅ Message saved to file successfully!");
  } catch (error) {
    console.error("🚨 Error saving message to file:", error);
  }
};

const getMessages = async (req, res) => {
  try {
    const { roomId } = req.params;

    console.log(roomId);
    const chatGroupId = parseInt(roomId, 10);

    if (isNaN(chatGroupId)) {
      return res.status(400).json({ error: "Invalid room ID" });
    }

    // ✅ Fetch messages from Prisma
    const messages = await prisma.message.findMany({
      where: {
        chatGroupId: chatGroupId, // ✅ Pass integer instead of string
      },
      orderBy: {
        createdAt: "asc",
      },
    });

    // Get messages from file
    try {
      const logFile = path.join(CHAT_LOGS_DIR, `${roomId}.txt`);
      const fileExists = await fs
        .access(logFile)
        .then(() => true)
        .catch(() => false);

      if (fileExists) {
        const fileContent = await fs.readFile(logFile, "utf8");
        console.log(fileContent);
        res.status(200).json({
          messages,
          chatLog: fileContent,
        });
      } else {
        res.status(200).json({
          messages,
          chatLog: "",
        });
      }
    } catch (error) {
      console.error("Error reading chat log file:", error);
      res.status(200).json({ messages });
    }
  } catch (error) {
    console.log("Error in getting messages", error.message);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

const sendMessage = async (req, res) => {
  try {
    const { message, senderId, roomId } = req.body;

    // ✅ Save message to file
    await saveMessageToFile(roomId, senderId, message);

    // ✅ Get sender's socket ID (you need a function to track connected users)
    const senderSocketId = getUserSocketId(senderId);

    // ✅ Broadcast message to all users EXCEPT the sender
    if (senderSocketId) {
      socket.to(roomId).emit("receiveMessage", {
        ...message,
        isSentByMe: false,
      });
    } else {
      io.to(roomId).emit("receiveMessage", {
        ...message,
        isSentByMe: false,
      });
    }

    res.status(201).json({ message });
  } catch (error) {
    console.log("Error in sending message", error.message);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

module.exports = { getMessages, sendMessage };
