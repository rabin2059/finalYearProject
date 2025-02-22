const prisma = require("../utils/prisma.js");
const polyline = require("@mapbox/polyline");

const addVehicle = async (req, res) => {
  try {
    const {
      vehicleNo,
      model,
      vehicleType,
      registerAs,
      ownerId,
      seatNo,
      departure,
      arrivalTime,
    } = req.body;

    const result = await prisma.$transaction(async (tx) => {
      // ✅ Check if vehicle already exists
      const existingVehicle = await tx.vehicle.findFirst({
        where: { vehicleNo },
      });

      if (existingVehicle) {
        throw new Error("Vehicle already exists"); // Auto rollback on error
      }

      // ✅ Create vehicle
      const newVehicle = await tx.vehicle.create({
        data: {
          vehicleNo,
          model,
          vehicleType,
          registerAs,
          departure,
          arrivalTime,
          ownerId,
        },
      });

      // ✅ Insert seats only if provided
      let newSeats = [];
      if (seatNo.length) {
        newSeats = await tx.vehicleSeat.createMany({
          data: seatNo.map((seat) => ({
            vehicleId: newVehicle.id,
            seatNo: seat, // ✅ Ensure correct field mapping
          })),
        });
      }

      return { newVehicle, newSeats };
    });

    res.status(201).json({
      message: "Vehicle and seats added successfully",
      vehicle: result.newVehicle,
      seats: seatNo || [],
    });
  } catch (error) {
    console.error("Error adding vehicle:", error);
    res
      .status(500)
      .json({ message: "Error adding vehicle", error: error.message });
  }
};

const createRoute = async (req, res) => {
  try {
    const { name, startPoint, endPoint, busStops, vehicleID, fare } = req.body;
    console.log(req.body);

    const result = await prisma.$transaction(async (tx) => {
      // ✅ Check if a route already exists for this vehicle
      let existingRoute = await tx.route.findFirst({
        where: { vehicleID },
      });

      let route;
      if (existingRoute) {
        console.log("Updating existing route...");
        route = existingRoute; // Use the existing route
      } else {
        console.log("Creating new route...");
        // Create the Route
        route = await tx.route.create({
          data: {
            name,
            startPoint,
            endPoint,
            vehicleID,
            fare,
          },
        });
      }

      let coordinates = [];

      // ✅ Delete existing bus stops if updating a route
      if (existingRoute) {
        await tx.routeBusStop.deleteMany({
          where: { routeId: route.id },
        });
      }

      // ✅ Process each bus stop
      for (let i = 0; i < busStops.length; i++) {
        const stopName = busStops[i];

        console.log(stopName);
        // Check if bus stop exists
        let busStop = await tx.busStop.findFirst({
          where: {
            name: stopName.name,
          },
        });

        // If bus stop doesn't exist, create it
        if (!busStop) {
          busStop = await tx.busStop.create({
            data: {
              name: stopName.name,
              latitude: stopName.latitude,
              longitude: stopName.longitude,
            },
          });
        }

        console.log("bus", busStop);

        // Associate the bus stop with the route
        await tx.routeBusStop.create({
          data: {
            routeId: route.id,
            busStopId: busStop.id,
            sequence: stopName.sequence,
          },
        });

        // Store the coordinates for polyline encoding
        coordinates.push([busStop.latitude, busStop.longitude]);
      }

      // ✅ Encode the polyline
      const encodedPolyline = polyline.encode(coordinates);
      console.log("Encoded Polyline:", encodedPolyline);

      // ✅ Update or create the route with the polyline
      await tx.route.update({
        where: { id: route.id },
        data: { polyline: encodedPolyline, name, startPoint, endPoint, fare },
      });

      return route;
    });

    res.status(201).json({
      message: "Route created or updated successfully",
      result,
    });
  } catch (error) {
    console.error(error);
    res
      .status(500)
      .json({ error: "An error occurred while creating/updating the route" });
  }
};

const getVehicles = async (req, res) => {
  try {
    const vehicles = await prisma.vehicle.findMany({
      include: {
        owner: true,
        VehicleSeat: true,
        Booking: {
          include: {
            bookingSeats: true,
          },
        },
        Route: {
          include: {
            busStops: true,
          },
        },
      },
    });

    // Transform vehicles data to have Route as an object instead of an array
    const bus = vehicles.map((vehicle) => ({
      ...vehicle,
      Route: vehicle.Route.length > 0 ? vehicle.Route[0] : null, // Convert array to single object
    }));

    res.json({ message: "Vehicles fetched successfully", bus });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error fetching vehicles" });
  }
};

const getSingleVehicle = async (req, res) => {
  try {
    const { id } = req.query; // Get vehicle ID from URL params

    if (!id) {
      return res.status(400).json({ message: "Vehicle ID is required" });
    }

    const vehicle = await prisma.vehicle.findUnique({
      where: { id: parseInt(id) }, // Ensure ID is an integer
      include: {
        owner: true, // Fetch owner details
        VehicleSeat: { select: { seatNo: true } }, // Fetch seats
        Booking: {
          include: {
            user: { select: { id: true, username: true } }, // Fetch booked users
            bookingSeats: { select: { seatNo: true } }, // Fetch booked seats
          },
        },
        Route: {
          include: {
            busStops: {
              include: { busStop: true },
              orderBy: { sequence: "asc" }, // Fetch stops in order
            },
          },
        },
      },
    });

    if (!vehicle) {
      return res.status(404).json({ message: "Vehicle not found" });
    }

    res.status(200).json({ vehicle: vehicle });
  } catch (error) {
    console.error("Error fetching vehicle:", error);
    res
      .status(500)
      .json({ message: "Error fetching vehicle", error: error.message });
  }
};

module.exports = { addVehicle, createRoute, getVehicles, getSingleVehicle };
