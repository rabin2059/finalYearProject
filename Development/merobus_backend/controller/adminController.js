const prisma = require("../utils/prisma.js");
const requestRole = async (req, res) => {
  try {
    const { userId, licenseNo } = req.body;
    console.log(req.body);
    const images = req.file ? `/uploads/${req.file.filename}` : null; // Check if a file was uploaded
    console.log(images);
    // Validate request body
    if (!userId || !licenseNo || !images) {
      return res
        .status(400)
        .json({ message: "Invalid request body. Missing required fields." });
    }

    // Fetch user
    const user = await prisma.user.findFirst({
      where: {
        id: parseInt(userId),
      },
    });
    console.log(user.role);
    // Check if user exists
    if (!user) {
      return res.status(404).json({ message: "User not found." });
    }

    // Check if user is already a driver
    if (user.role === "DRIVER") {
      return res.status(400).json({ message: "User is already a driver!" });
    }

    // Update user details
    const userDriver = await prisma.user.update({
      where: { id: parseInt(userId) },
      data: {
        licenseNo,
        licenceImage: images,
        status: "onHold",
      },
    });

    return res.status(200).json({
      message: "User role update request successfully submitted.",
      user: userDriver,
    });
  } catch (error) {
    console.error(error.message);
    return res
      .status(500)
      .json({ message: "An error occurred while processing the request." });
  }
};

const validDriverRole = async (req, res) => {
  const { id, status } = req.body;
  try {
    const user = await prisma.user.findFirst({
      where: {
        id: parseInt(id),
      },
    });
    if (!user) return res.status(404).json({ message: "User not found" });
    if (user.role == 2)
      return res.status(404).json({ message: "User is approved driver" });

    const updateRole = await prisma.user.update({
      where: {
        id: parseInt(id),
      },
      data: {
        role: status === "approved" ? "DRIVER" : "USER",
        licenseNo: status === "approved" ? user.licenseNo : null,
        licenceImage: status === "approved" ? user.licenceImage : null,
        status: status,
      },
    });

    return res.status(200).json({
      message: "User role update request successfully submitted.",
      user: updateRole,
    });
  } catch (error) {
    console.log(error);
    return res
      .status(500)
      .json({ message: "An error occurred while processing the request." });
  }
};

const getAllUser = async (req, res) => {
  try {
    const user = await prisma.user.findMany();
    return res.status(200).json({
      message: "User Fetched Successfully",
      user: user,
    });
  } catch {
    return res
      .status(500)
      .json({ message: "An error occurred while fetching users." });
  }
};

module.exports = {
  requestRole,
  validDriverRole,
  getAllUser,
};
