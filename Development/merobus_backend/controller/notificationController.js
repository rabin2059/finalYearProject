const admin = require("firebase-admin");
const prisma = require("../utils/prisma");

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  const serviceAccount = require("../configs/serviceAcountKey.json");
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

// Send a notification to a specific user
const sendNotification = async (req, res) => {
  const { token, title, body } = req.body;

  if (!token || !title || !body) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  const message = {
    notification: {
      title,
      body,
    },
    token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Notification sent:", response);
    return res.status(200).json({ success: true, response });
  } catch (error) {
    console.error("Error sending notification:", error);
    return res.status(500).json({ success: false, error: error.message });
  }
};

// Save a notification entry in the database
const logNotification = async (req, res) => {
  const { userId, title, body } = req.body;

  if (!userId || !title || !body) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  try {
    const notification = await prisma.notification.create({
      data: {
        userId: parseInt(userId),
        title,
        body,
      },
    });

    return res.status(201).json({ success: true, notification });
  } catch (error) {
    console.error("Error saving notification:", error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// Get notifications for a user
const getUserNotifications = async (req, res) => {
  const { userId, page = 1 } = req.query;

  if (!userId) {
    return res.status(400).json({ message: "Missing userId" });
  }

  try {
    const notifications = await prisma.notification.findMany({
      where: {
        userId: parseInt(userId),
      },
      orderBy: {
        createdAt: "desc",
      },
      take: 10,
      skip: (parseInt(page) - 1) * 10,
    });

    return res.status(200).json({ notifications });
  } catch (error) {
    console.error("Error fetching notifications:", error);
    res.status(500).json({ success: false, error: error.message });
  }
};

module.exports = {
  sendNotification,
  logNotification,
  getUserNotifications,
};
