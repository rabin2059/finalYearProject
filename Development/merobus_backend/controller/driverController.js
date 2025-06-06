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

    const result = await prisma.$transaction(async (tx) => {
      const existingVehicle = await tx.vehicle.findFirst({
        where: { vehicleNo },
      });

      const existingUser = await tx.vehicle.findFirst({
        where: { ownerId },
      });

      if (existingUser) {
        throw new Error("User already has a registered vehicle");
      }

      if (existingVehicle) {
        throw new Error("Vehicle already exists");
      }

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

      let newSeats = [];
      if (seatNo?.length) {
        newSeats = await tx.vehicleSeat.createMany({
          data: seatNo.map((seat) => ({
            vehicleId: newVehicle.id,
            seatNo: seat,
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

    await prisma.userChatGroup.create({
      data: {
        userId: result.newVehicle.ownerId,
        chatGroupId: chatGroup.id,
      },
    });

    res.status(201).json({
      message: "Vehicle and seats added successfully",
      vehicle: result.newVehicle,
      seats: seatNo || [],
      chatGroup,
    });
  } catch (error) {
    console.error("Error adding vehicle:", error);
    res.status(500).json({
      message: "Error adding vehicle",
      error: error.message,
    });
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

        if (i < busStops.length - 1) {
          const nextStop = busStops[i + 1];
          const routePoints = await getRoutePoints(
            [stop.latitude, stop.longitude],
            [nextStop.latitude, nextStop.longitude]
          );
          coordinates.push(...routePoints);
        }
      }

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

const updateRoute = async (req, res) => {
  try {
    const { routeId, startPoint, endPoint, fare, name, busStops } = req.body;

    if (!routeId) {
      return res.status(400).json({ message: "Route ID is required" });
    }

    const existingRoute = await prisma.route.findUnique({
      where: { id: parseInt(routeId) },
    });

    if (!existingRoute) {
      return res.status(404).json({ message: "Route not found" });
    }

    const updatedRoute = await prisma.$transaction(async (tx) => {
      const updated = await tx.route.update({
        where: { id: parseInt(routeId) },
        data: {
          startPoint: startPoint || existingRoute.startPoint,
          endPoint: endPoint || existingRoute.endPoint,
          fare: fare !== undefined ? fare : existingRoute.fare,
          name: name || existingRoute.name,
        },
      });

      if (busStops?.length) {
        await tx.routeBusStop.deleteMany({
          where: { routeId: parseInt(routeId) },
        });

        let coordinates = [];

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

          // 📌  Re‑attach this stop to the route with its sequence
          await tx.routeBusStop.create({
            data: {
              routeId: parseInt(routeId),
              busStopId: busStop.id,
              sequence: stop.sequence,
            },
          });

          if (busStop.latitude !== 0 && busStop.longitude !== 0) {
            coordinates.push([busStop.latitude, busStop.longitude]);
          }

          if (i < busStops.length - 1) {
            const nextStop = busStops[i + 1];
            if (stop.latitude !== 0 && stop.longitude !== 0 && nextStop.latitude !== 0 && nextStop.longitude !== 0) {
              const routePoints = await getRoutePoints(
                [stop.latitude, stop.longitude],
                [nextStop.latitude, nextStop.longitude]
              );
              coordinates.push(...routePoints);
            }
          }
        }

        const encodedPolyline = polyline.encode(coordinates);
        await tx.route.update({
          where: { id: parseInt(routeId) },
          data: { polyline: encodedPolyline },
        });
        console.log(encodedPolyline)
      }

      return updated;
    });

    res.status(200).json({ message: "Route updated successfully", updatedRoute });
  } catch (error) {
    console.error("Error updating route:", error);
    res.status(500).json({ message: "Error updating route", error: error.message });
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

    const bus = vehicles.map((vehicle) => ({
      ...vehicle,
      Route: vehicle.Route.length > 0 ? vehicle.Route[0] : null, 
    }));

    res.json({ message: "Vehicles fetched successfully", bus });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error fetching vehicles" });
  }
};

const getSingleVehicle = async (req, res) => {
  try {
    const { id } = req.query;

    if (!id) {
      return res.status(400).json({ message: "Vehicle ID is required" });
    }

    const vehicle = await prisma.vehicle.findUnique({
      where: { id: parseInt(id) },
      include: {
        owner: true,
        VehicleSeat: { select: { seatNo: true } },

        Route: {
          include: {
            busStops: {
              include: { busStop: true },
              orderBy: { sequence: "asc" },
            },
          },
        },
        Booking: {
          include: {
            user: { select: { id: true, username: true } },
            bookingSeats: { select: { seatNo: true } },
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

const driverHome = async (req, res) => {
  try {
    const userId = parseInt(req.query.userId, 10);
    if (!userId) {
      return res
        .status(400)
        .json({ message: "userId query parameter is required" });
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        username: true,
        email: true,
        images: true,
        status: true,
      },
    });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const totalTrips = await prisma.booking.count({
      where: { vehicle: { ownerId: userId } },
    });

    const earningsAgg = await prisma.booking.aggregate({
      _sum: { totalFare: true },
      where: { vehicle: { ownerId: userId } },
    });
    const totalEarnings = earningsAgg._sum.totalFare ?? 0;

    const ratingAgg = await prisma.driverRating.aggregate({
      _avg: { rating: true },
      where: { driverId: userId },
    });
    const rating = ratingAgg._avg.rating ?? 0;

    const driverStats = {
      totalTrips,
      totalEarnings,
      rating,
      status: user.status ?? "Offline",
    };

    return res.status(200).json({ user, driverStats });
  } catch (error) {
    console.error("Error in driverHome:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

module.exports = {
  addVehicle,
  createRoute,
  getVehicles,
  getSingleVehicle,
  driverHome,
  updateRoute
};
