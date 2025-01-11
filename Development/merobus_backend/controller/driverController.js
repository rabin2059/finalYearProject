const prisma = require("../utils/prisma.js");

const getVehicles = async (req, res) => {
  try {
    const vehicles = await prisma.vehicle.findMany({
      include: {
        route: {
          include: {
            busStops: {
              include: {
                busStop: true,
              },
              orderBy: {
                sequence: "asc",
              },
            },
          },
        },
      },
    });

    const formattedVehicles = vehicles.map((vehicle) => ({
      id: vehicle.id,
      vehicleNo: vehicle.vehicleNo,
      model: vehicle.model,
      ownerId: vehicle.ownerId,
      route: vehicle.route
        ? {
            id: vehicle.route.id,
            startPoint: vehicle.route.startPoint,
            endPoint: vehicle.route.endPoint,
            busStops: vehicle.route.busStops.map((rs) => ({
              id: rs.busStop.id,
              name: rs.busStop.name,
              latitude: rs.busStop.latitude,
              longitude: rs.busStop.longitude,
            })),
          }
        : null,
    }));

    res.json(formattedVehicles);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error fetching vehicles" });
  }
};

module.exports = { getVehicles };
