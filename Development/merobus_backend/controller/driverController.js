const prisma = require("../utils/prisma.js");

const addVehicle = async (req, res) => {
  try {
    const { vehicleNo, model, ownerId } = req.body;
    const existingVehicle = await prisma.vehicle.findFirst({
      where: {
        vehicleNo: vehicleNo,
      },
    });

    if (existingVehicle) {
      return res.status(400).json({ message: "Vehicle already exists" });
    }

    const newVehicle = await prisma.vehicle.create({
      data: {
        vehicleNo: vehicleNo,
        model: model,
        ownerId: ownerId,
      },
    });

    res
      .status(201)
      .json({ message: "Vehicle added successfully", vehicle: newVehicle });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error adding vehicle" });
  }
};

const createRoute = async (req, res) => {
  try {
    const { name, startPoint, endPoint, busStops, vehicleID } = req.body;
    console.log(req.body);

    const result = await prisma.$transaction(async (prisma) => {
      // Create the Route
      const route = await prisma.route.create({
        data: {
          name,
          startPoint,
          endPoint,
          vehicleID,
        },
      });

      // Process each bus stop
      for (let i = 0; i < busStops.length; i++) {
        const stopName = busStops[i];
        console.log(stopName);
        // Check if bus stop exists
        let busStop = await prisma.busStop.findFirst({
          where: {
            name: stopName.name,
          },
        });

        // If bus stop doesn't exist, create it
        if (!busStop) {
          busStop = await prisma.busStop.create({
            data: {
              name: stopName.name,
              latitude: stopName.latitude,
              longitude: stopName.longitude,
            },
          });
        }

        console.log("bus", busStop);
        // Associate the bus stop with the route
        await prisma.routeBusStop.create({
          data: {
            routeId: route.id,
            busStopId: busStop.id,
            sequence: stopName.sequence,
          },
        });
      }

      return route;
    });

    res.status(201).json({ message: "Route created successfully", result });
  } catch (error) {
    console.error(error);
    res
      .status(500)
      .json({ error: "An error occurred while creating the route" });
  }
};

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

module.exports = { addVehicle, createRoute, getVehicles };
