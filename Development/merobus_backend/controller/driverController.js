const prisma = require("../utils/prisma.js");
const polyline = require("@mapbox/polyline");
const axios = require("axios");

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
    console.log(req.body);

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

    const chatGroup = await prisma.chatGroup.create({
      data: {
        name: `ChatGroup for ${result.newVehicle.vehicleNo}`,
        vehicleId: result.newVehicle.id,
      },
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

const getRoutePoints = async (start, end) => {
  const apiKey = "bdd2485e-33f3-455c-890d-a9ada7a60138";
  const url = `https://graphhopper.com/api/1/route?point=${start[0]},${start[1]}&point=${end[0]},${end[1]}&vehicle=car&key=${apiKey}&points_encoded=false`;

  try {
    const response = await axios.get(url);
    const routePoints = response.data.paths[0].points.coordinates;
    const routePointsLatLng = routePoints.map(([lon, lat]) => [lat, lon]);

    return getSampledPoints(routePointsLatLng, 5); // 5km intervals
  } catch (error) {
    console.error("Error fetching route points:", error);
    return [];
  }
};

const calculateDistance = (point1, point2) => {
  const [lat1, lon1] = point1;
  const [lat2, lon2] = point2;

  const R = 6371; // Earth's radius in kilometers
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;

  return distance;
};

const getSampledPoints = (points, intervalKm) => {
  if (points.length < 2) return points;

  const sampledPoints = [points[0]];
  let accumulatedDistance = 0;
  let lastSampledPoint = points[0];

  for (let i = 1; i < points.length; i++) {
    const currentPoint = points[i];
    const segmentDistance = calculateDistance(lastSampledPoint, currentPoint);

    accumulatedDistance += segmentDistance;

    if (accumulatedDistance >= intervalKm) {
      sampledPoints.push(currentPoint);
      lastSampledPoint = currentPoint;
      accumulatedDistance = 0;
    }
  }

  const lastPoint = points[points.length - 1];
  if (sampledPoints[sampledPoints.length - 1] !== lastPoint) {
    sampledPoints.push(lastPoint);
  }

  return sampledPoints;
};

const createRoute = async (req, res) => {
  try {
    const { name, startPoint, endPoint, busStops, vehicleID, fare } = req.body;
    console.log(req.body);

    const result = await prisma.$transaction(async (tx) => {
      let existingRoute = await tx.route.findFirst({ where: { vehicleID } });

      let route;
      if (existingRoute) {
        console.log("Updating existing route...");
        route = existingRoute;
      } else {
        console.log("Creating new route...");
        route = await tx.route.create({
          data: { name, startPoint, endPoint, vehicleID, fare },
        });
      }

      let coordinates = [];

      if (existingRoute) {
        await tx.routeBusStop.deleteMany({ where: { routeId: route.id } });
      }

      for (let i = 0; i < busStops.length; i++) {
        const stop = busStops[i];

        let busStop = await tx.busStop.findFirst({
          where: { name: stop.name },
        });
        if (!busStop) {
          busStop = await tx.busStop.create({
            data: {
              name: stop.name,
              latitude: stop.latitude,
              longitude: stop.longitude,
            },
          });
        }

        await tx.routeBusStop.create({
          data: {
            routeId: route.id,
            busStopId: busStop.id,
            sequence: stop.sequence,
          },
        });

        coordinates.push([busStop.latitude, busStop.longitude]);

        // ✅ Fetch intermediate route points (except for last stop)
        if (i < busStops.length - 1) {
          const nextStop = busStops[i + 1];
          const routePoints = await getRoutePoints(
            [stop.latitude, stop.longitude],
            [nextStop.latitude, nextStop.longitude]
          );
          coordinates.push(...routePoints); // Append road path
        }
      }

      // ✅ Encode the polyline with intermediate points
      const encodedPolyline = polyline.encode(coordinates);
      console.log("Encoded Polyline:", encodedPolyline);

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

const getMyRoute = async (req, res) => {
  try {
    const { id } = req.query;
    if (!id) {
      return res.status(400).json({ message: "Vehicle ID is required" });
    }

    const route = await prisma.route.findFirst({
      where: {
        vehicleID: parseInt(id),
      },
      select: {
        startPoint: true,
        endPoint: true,
      },
    });
    console.log(route);
    if (!route) {
      return res
        .status(404)
        .json({ message: "No route found for this vehicle" });
    }

    res.status(200).json({ route });
  } catch (error) {
    res
      .status(404)
      .json({ message: "Could not found the route" + error.message });
  }
};

module.exports = {
  addVehicle,
  createRoute,
  getVehicles,
  getSingleVehicle,
  getMyRoute,
};
