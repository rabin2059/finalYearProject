const prisma = require("../utils/prisma.js");

const createVehicleReview = async (req, res) => {
  const { driverId, rating, review } = req.body;
  const userId = req.user.userId;
  console.log(req.body);

  if (!driverId || typeof rating !== "number") {
    return res
      .status(400)
      .json({ message: "Driver ID and rating are required." });
  }

  if (rating < 1 || rating > 5) {
    return res.status(400).json({ message: "Rating must be between 1 and 5." });
  }

  if (!review) return res.status(400).json({ message: "Review is Required" });

  try {
    const newReview = await prisma.driverRating.create({
      data: {
        driverId,
        userId,
        rating,
        review,
      },
    });

    return res
      .status(201)
      .json({ message: "Review added successfully", result: newReview });
  } catch (error) {
    console.error("Error adding review:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

const getVehicleRatings = async (req, res) => {
  const { driverId } = req.params;
  console.log(driverId);

  if (!driverId) {
    return res.status(400).json({ message: "Driver ID is required." });
  }

  const id = parseInt(driverId);
  console.log("idfgdg", id);

  try {
    const ratings = await prisma.driverRating.findMany({
      where: {
        driverId: id,
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            images: true,
          },
        },
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    return res
      .status(200)
      .json({ message: "Ratings fetched successfully", result: ratings });
  } catch (error) {
    console.error("Error fetching ratings:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

module.exports = {
  createVehicleReview,
  getVehicleRatings,
};
