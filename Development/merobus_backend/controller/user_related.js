const prisma = require("../utils/prisma.js");
const upload = require("../configs/storage");

const updateUser = async (req, res) => {
  try {
    const { id, username, email, phone, address } = req.body;
    const images = req.file ? `/uploads/${req.file.filename}` : null; // Check if a file was uploaded
  
    // Find the user by ID
    const user = await prisma.user.findFirst({
      where: {
        id: parseInt(id),
      },
    });
  
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
  
    // Update user information in the database
    const updatedUser = await prisma.user.update({
      where: { id: parseInt(id) },
      data: {
        username: username ? username : user.username,
        email: email ? email : user.email,
        phone: phone ? phone : user.phone,
        address: address ? address : user.address,
        images: images ? images : user.images, // Save the image path in the database
      },
    });
  
    return res.status(200).json({
      message: "User updated successfully",
      user: updatedUser,
    });
  } catch (error) {
    console.error("Error updating user:", error);
    return res.status(500).json({ message: "Server error" });
  }
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

    const vehicle = await prisma.vehicle.findFirst({
      where: { ownerId: parseInt(id) },
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const userData = { ...user, vehicleId: vehicle ? vehicle.id : null };

    // Respond with user data
    return res.status(200).json({ userData });
  } catch (error) {
    console.error("Error fetching user:", error);
    return res.status(500).json({ message: "Server error" });
  }
};

module.exports = { updateUser, getUser };
