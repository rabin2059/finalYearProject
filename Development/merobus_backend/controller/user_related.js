const prisma = require("../utils/prisma.js");
const upload = require("../configs/storage");

const updateUser = async (req, res) => {
  try {
    const { id, username, email, phone, address } = req.body;
    const images = req.file ? `/uploads/${req.file.filename}` : null; // Check if a file was uploaded
    console.log(images);

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

const passengerHomePage = async (req, res) => {
  try {
    const userId = parseInt(req.query.userId, 10);
    if (!userId) {
      return res
        .status(400)
        .json({ message: "userId query parameter is required" });
    }

    // 1. Fetch basic user info
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        username: true,
        email: true,
        images: true, // matches your HomeScreen’s userImage
      },
    });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // 2. Count total bookings (used for “Recent Trips” card)
    const recentTrips = await prisma.booking.count({
      where: { userId },
    });

    // 3. Sum of all fares as total expenditure
    const expenditureAgg = await prisma.booking.aggregate({
      _sum: { totalFare: true },
      where: { userId },
    });
    const totalExpend = expenditureAgg._sum.totalFare ?? 0;

    return res.status(200).json({
      user,
      recentTrips,
      totalExpend,
    });
  } catch (error) {
    console.error("Error in passengerHomePage:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

const getUpcomingTrip = async (req, res) => {
  try {
    const userId = parseInt(req.query.userId, 10);
    console.log(userId)
    if (!userId) {
      return res
        .status(400)
        .json({ message: "userId query parameter is required" });
    }

    const upcomingTrips = await prisma.booking.findMany({
      where: {
        userId: userId,
        bookingDate: {
          gte: new Date(),
        },
        status: {
          not: "CANCELLED",
        },
      },
      orderBy: {
        bookingDate: "asc",
      },
      include: {
        vehicle: {
          include: {
            Route: true,
          },
        },
      },
    });

    return res.status(200).json({ trips: upcomingTrips });
  } catch (error) {
    console.error("Error in getUpcomingTrip:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

module.exports = { updateUser, getUser, passengerHomePage, getUpcomingTrip };
