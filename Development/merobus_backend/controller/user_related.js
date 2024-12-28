const prisma = require("../utils/prisma.js");

const updateUser = async (req, res) => {
  const { id, username, email, phone, address } = req.body;

  const user = await prisma.user.findFirst({
    where: {
      id: parseInt(id),
    },
  });

  if (!user) {
    return res.status(404).json({ message: "User not found" });
  }

  const updatedUser = await prisma.user.update({
    where: { id: parseInt(id) },
    data: { username, email, phone, address },
  });

  return res
    .status(200)
    .json({ message: "User updated successfully", user: updatedUser });
};

const getUser = async (req, res) => {
  try {
    const { id } = req.query; // Extract `id` from the query string

    // Validate ID
    if (!id || isNaN(id)) {
      return res.status(400).json({ message: "Invalid or missing ID" });
    }

    // Fetch user from database
    const user = await prisma.user.findFirst({
      where: { id: parseInt(id) },
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Respond with user data
    return res.status(200).json({ user });
  } catch (error) {
    console.error("Error fetching user:", error);
    return res.status(500).json({ message: "Server error" });
  }
};

module.exports = { updateUser, getUser };
