// controller/chatController.js
const prisma = require("../utils/prisma");
const { logger } = require("../utils/logger");
const { activeUsers } = require("./socketController");

const getUserChatGroups = async (req, res) => {
  try {
    const { userId } = req.params;
    console.log(req.params);
    if (!userId) {
      return res.status(400).json({ error: "User ID is required" });
    }

    const numericUserId = parseInt(userId);
    const chatGroups = await prisma.chatGroup.findMany({
      where: {
        UserChatGroup: {
          some: {
            userId: numericUserId,
            isActive: true,
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
        vehicle: {
          select: {
            id: true,
            vehicleNo: true,
            model: true,
          },
        },
        _count: {
          select: { messages: true },
        },
      },
    });

    console.log(chatGroups);

    const formattedGroups = chatGroups.map((group) => ({
      id: group.id,
      name: group.name,
      vehicleId: group.vehicleId,
      vehicleInfo: group.vehicle,
      createdAt: group.createdAt,
      members: group.users.map((user) => ({
        id: user.id,
        username: user.username,
        isOnline: activeUsers.has(user.id.toString()),
      })),
      messageCount: group._count.messages,
    }));

    res.status(200).json({ chatGroups: formattedGroups });
  } catch (error) {
    logger.error(`Error fetching user chat groups: ${error.message}`);
    res
      .status(500)
      .json({ error: "Failed to fetch chat groups", details: error.message });
  }
};

const getChatGroupMessages = async (req, res) => {
  try {
    const { groupId } = req.params;

    if (!groupId) {
      return res.status(400).json({ error: "Chat group ID is required" });
    }

    // Fetch messages for the chat group
    const messages = await prisma.message.findMany({
      where: {
        chatGroupId: parseInt(groupId),
      },
      include: {
        sender: {
          select: {
            id: true,
            username: true,
          },
        },
      },
      orderBy: {
        createdAt: "asc",
      },
    });

    // Transform messages to match expected format
    const formattedMessages = messages.map((msg) => ({
      id: msg.id,
      text: msg.text,
      senderId: msg.senderId,
      senderName: msg.sender.username,
      chatGroupId: msg.chatGroupId,
      createdAt: msg.createdAt,
      isRead: msg.isRead,
    }));

    res.status(200).json({ messages: formattedMessages });
  } catch (error) {
    logger.error(`Error fetching chat group messages: ${error.message}`);
    res
      .status(500)
      .json({ error: "Failed to fetch messages", details: error.message });
  }
};

// Create a new chat group
const createChatGroup = async (req, res) => {
  try {
    const { name, vehicleId, userIds } = req.body;

    if (!name || !userIds || !Array.isArray(userIds) || userIds.length === 0) {
      return res
        .status(400)
        .json({ error: "Name and at least one user ID are required" });
    }

    // Create chat group
    const chatGroup = await prisma.chatGroup.create({
      data: {
        name,
        vehicleId: vehicleId ? parseInt(vehicleId) : null,
        users: {
          connect: userIds.map((id) => ({ id: parseInt(id) })),
        },
      },
      include: {
        users: {
          select: {
            id: true,
            username: true,
          },
        },
        vehicle: vehicleId
          ? {
              select: {
                id: true,
                vehicleNo: true,
                model: true,
              },
            }
          : false,
      },
    });

    res.status(201).json({
      message: "Chat group created successfully",
      chatGroup: {
        id: chatGroup.id,
        name: chatGroup.name,
        vehicleId: chatGroup.vehicleId,
        vehicleInfo: chatGroup.vehicle,
        createdAt: chatGroup.createdAt,
        members: chatGroup.users.map((user) => ({
          id: user.id,
          username: user.username,
          isOnline: activeUsers.has(user.id.toString()),
        })),
      },
    });
  } catch (error) {
    logger.error(`Error creating chat group: ${error.message}`);
    res
      .status(500)
      .json({ error: "Failed to create chat group", details: error.message });
  }
};

// Add a user to a chat group
const addUserToChatGroup = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { userId } = req.body;

    console.log("i joined");

    if (!groupId || !userId) {
      return res
        .status(400)
        .json({ error: "Group ID and user ID are required" });
    }

    // Check if user is already in the group
    const existingMember = await prisma.chatGroup.findFirst({
      where: {
        id: parseInt(groupId),
        users: {
          some: {
            id: parseInt(userId),
          },
        },
      },
    });

    if (existingMember) {
      return res
        .status(400)
        .json({ error: "User is already a member of this chat group" });
    }

    // Add user to chat group
    const updatedGroup = await prisma.chatGroup.update({
      where: {
        id: parseInt(groupId),
      },
      data: {
        users: {
          connect: {
            id: parseInt(userId),
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

    res.status(200).json({
      message: "User added to chat group successfully",
      members: updatedGroup.users.map((user) => ({
        id: user.id,
        username: user.username,
        isOnline: activeUsers.has(user.id.toString()),
      })),
    });
  } catch (error) {
    logger.error(`Error adding user to chat group: ${error.message}`);
    res.status(500).json({
      error: "Failed to add user to chat group",
      details: error.message,
    });
  }
};

// Remove a user from a chat group
const removeUserFromChatGroup = async (req, res) => {
  try {
    const { groupId, userId } = req.params;

    if (!groupId || !userId) {
      return res
        .status(400)
        .json({ error: "Group ID and user ID are required" });
    }

    // Remove user from chat group
    const updatedGroup = await prisma.chatGroup.update({
      where: {
        id: parseInt(groupId),
      },
      data: {
        users: {
          disconnect: {
            id: parseInt(userId),
          },
        },
      },
    });

    res.status(200).json({
      message: "User removed from chat group successfully",
    });
  } catch (error) {
    logger.error(`Error removing user from chat group: ${error.message}`);
    res.status(500).json({
      error: "Failed to remove user from chat group",
      details: error.message,
    });
  }
};

// Get unread message count for a user
const getUnreadMessageCount = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({ error: "User ID is required" });
    }

    // Find chat groups where the user is a member
    const chatGroups = await prisma.chatGroup.findMany({
      where: {
        users: {
          some: {
            id: parseInt(userId),
          },
        },
      },
      select: {
        id: true,
      },
    });

    const groupIds = chatGroups.map((group) => group.id);

    // Count unread messages for each group
    const unreadCounts = await Promise.all(
      groupIds.map(async (groupId) => {
        const count = await prisma.message.count({
          where: {
            chatGroupId: groupId,
            senderId: {
              not: parseInt(userId),
            },
            isRead: false,
          },
        });

        return { groupId, count };
      })
    );

    // Calculate total unread count
    const totalUnread = unreadCounts.reduce(
      (total, item) => total + item.count,
      0
    );

    res.status(200).json({
      totalUnread,
      groupCounts: unreadCounts.reduce((acc, item) => {
        acc[item.groupId] = item.count;
        return acc;
      }, {}),
    });
  } catch (error) {
    logger.error(`Error getting unread message count: ${error.message}`);
    res.status(500).json({
      error: "Failed to get unread message count",
      details: error.message,
    });
  }
};

// Mark messages as read
const markMessagesAsRead = async (req, res) => {
  try {
    const { userId, groupId } = req.params;

    if (!userId || !groupId) {
      return res
        .status(400)
        .json({ error: "User ID and group ID are required" });
    }

    // Mark all messages in the group as read
    await prisma.message.updateMany({
      where: {
        chatGroupId: parseInt(groupId),
        senderId: {
          not: parseInt(userId),
        },
        isRead: false,
      },
      data: {
        isRead: true,
      },
    });

    res.status(200).json({
      message: "Messages marked as read successfully",
    });
  } catch (error) {
    logger.error(`Error marking messages as read: ${error.message}`);
    res.status(500).json({
      error: "Failed to mark messages as read",
      details: error.message,
    });
  }
};

const chatGroupOfVehicle = async (req, res) => {
  try {
    const { vehicleId } = req.params;
    const checkChatGroup = await prisma.chatGroup.findFirst({
      where: {
        vehicleId: parseInt(vehicleId),
      },
    });

    return res.status(200).json({ success: true, message: checkChatGroup });
  } catch (error) {
    logger.error(`Error checking chat group of vehicle: ${error.message}`);
    res.status(500).json({
      success: false,
      message: "Failed to check chat group of vehicle",
      details: error.message,
    });
  }
};

module.exports = {
  getUserChatGroups,
  getChatGroupMessages,
  createChatGroup,
  addUserToChatGroup,
  removeUserFromChatGroup,
  getUnreadMessageCount,
  markMessagesAsRead,
  chatGroupOfVehicle,
};
