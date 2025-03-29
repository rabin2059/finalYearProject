const prisma = require("../utils/prisma.js");
const polyline = require("@mapbox/polyline");
const turf = require("@turf/turf");
const { activeBuses } = require("./socketController.js");

const getRoute = async (req, res) => {
  try {
    const { activeBuses } = require("./socketController.js");
    const { startLat, startLng, endLat, endLng } = req.query;

    if (!startLat || !startLng || !endLat || !endLng) {
      return res
        .status(400)
        .json({ message: "Start and End coordinates are required" });
    }

    const startPoint = [parseFloat(startLng), parseFloat(startLat)];
    const endPoint = [parseFloat(endLng), parseFloat(endLat)];

    const routes = await prisma.route.findMany({
      select: {
        id: true,
        name: true,
        polyline: true,
        vehicle: {
          select: {
            id: true,
            model: true,
            vehicleType: true,
            owner: {
              select: { id: true, username: true, email: true, phone: true },
            },
          },
        },
      },
    });

    // Attach live location to each vehicle
    routes.forEach((route) => {
      if (route.vehicle && activeBuses.has(route.vehicle.id)) {
        route.vehicle.location = activeBuses.get(route.vehicle.id).location;
      }
    });

    console.log("Fetched Routes:", routes);

    const validRoutes = routes.filter((route) => {
      if (!route.polyline) return false;

      const decodedPolyline = polyline.decode(route.polyline);
      console.log(`Decoded Polyline for route ${route.name}:`, decodedPolyline);

      const routeLine = turf.lineString(
        decodedPolyline.map(([lat, lng]) => [lng, lat])
      );

      const closestStart = turf.nearestPointOnLine(
        routeLine,
        turf.point(startPoint)
      );
      const closestEnd = turf.nearestPointOnLine(
        routeLine,
        turf.point(endPoint)
      );

      const startDistance =
        turf.distance(turf.point(startPoint), closestStart) * 1000;
      const endDistance =
        turf.distance(turf.point(endPoint), closestEnd) * 1000;

      console.log(`Route: ${route.name}`);
      console.log(`Start Distance: ${startDistance.toFixed(2)} meters`);
      console.log(`End Distance: ${endDistance.toFixed(2)} meters`);

      const thresholdDistance = 100000;
      const isStartNearRoute = startDistance <= thresholdDistance;
      const isEndNearRoute = endDistance <= thresholdDistance;

      return isStartNearRoute && isEndNearRoute;
    });

    console.log("Valid Routes:", validRoutes);

    if (validRoutes.length === 0) {
      return res
        .status(404)
        .json({ message: "No vehicles pass through both locations" });
    }

    const vehiclesWithLiveData = validRoutes.map((route) => {
      const routeBuses = Array.from(activeBuses.entries())
        .filter(
          ([_, busInfo]) => busInfo.routeId == route.id && busInfo.isActive
        )
        .map(([busId, busInfo]) => ({
          busId,
          busNumber: busInfo.busNumber,
          driverName: busInfo.driverName,
          location: busInfo.location || null,
          lastUpdated: busInfo.lastUpdated || null,
        }));

      return {
        routeId: route.id,
        routeName: route.name,
        vehicleId: route.vehicle.id,
        vehicleModel: route.vehicle.model,
        vehicleType: route.vehicle.vehicleType,
        driver: {
          id: route.vehicle.owner.id,
          name: route.vehicle.owner.username,
          email: route.vehicle.owner.email,
          phone: route.vehicle.owner.phone,
        },
        polyline: route.polyline,
        activeBuses: routeBuses,
        hasActiveBuses: routeBuses.length > 0,
      };
    });

    vehiclesWithLiveData.sort((a, b) => {
      if (a.hasActiveBuses && !b.hasActiveBuses) return -1;
      if (!a.hasActiveBuses && b.hasActiveBuses) return 1;

      if (a.hasActiveBuses && b.hasActiveBuses) {
        return b.activeBuses.length - a.activeBuses.length;
      }

      return 0;
    });

    return res.status(200).json({
      vehicles: vehiclesWithLiveData,
      totalBuses: vehiclesWithLiveData.reduce(
        (acc, route) => acc + route.activeBuses.length,
        0
      ),
    });
  } catch (error) {
    console.error("Error fetching available vehicles:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

const getActiveBuses = (req, res) => {
  try {
    const { latitude, longitude, radius } = req.query;

    if (latitude && longitude && radius) {
      const lat = parseFloat(latitude);
      const lng = parseFloat(longitude);
      const radiusKm = parseFloat(radius) || 5;

      const nearbyBuses = calculateNearbyBuses(lat, lng, radiusKm);

      return res.status(200).json({
        count: nearbyBuses.length,
        buses: nearbyBuses,
      });
    }

    const allBuses = Array.from(activeBuses.entries()).map(
      ([busId, busInfo]) => ({
        busId,
        routeId: busInfo.routeId,
        busNumber: busInfo.busNumber,
        driverName: busInfo.driverName,
        location: busInfo.location || null,
        lastUpdated: busInfo.lastUpdated || null,
        isActive: busInfo.isActive,
      })
    );

    return res.status(200).json({
      count: allBuses.length,
      buses: allBuses,
    });
  } catch (error) {
    console.error("Error fetching active buses:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

function calculateNearbyBuses(latitude, longitude, radius, routeId) {
  const nearbyBuses = [];

  const EARTH_RADIUS = 6371;

  const lat1 = (latitude * Math.PI) / 180;
  const lon1 = (longitude * Math.PI) / 180;

  for (const [busId, busInfo] of activeBuses.entries()) {
    if (!busInfo.location || !busInfo.isActive) continue;

    if (routeId && busInfo.routeId !== routeId) continue;

    const lat2 = (busInfo.location.latitude * Math.PI) / 180;
    const lon2 = (busInfo.location.longitude * Math.PI) / 180;

    const dLat = lat2 - lat1;
    const dLon = lon2 - lon1;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = EARTH_RADIUS * c;

    if (distance <= radius) {
      nearbyBuses.push({
        busId,
        routeId: busInfo.routeId,
        busNumber: busInfo.busNumber,
        driverName: busInfo.driverName,
        vehicleId: busInfo.vehicleId,
        vehicleModel: busInfo.vehicleModel,
        vehicleType: busInfo.vehicleType,
        latitude: busInfo.location.latitude,
        longitude: busInfo.location.longitude,
        speed: busInfo.location.speed || 0,
        heading: busInfo.location.heading || 0,
        lastUpdated: busInfo.lastUpdated,
        distance: Math.round(distance * 1000),
      });
    }
  }

  return nearbyBuses.sort((a, b) => a.distance - b.distance);
}

module.exports = {
  getRoute,
  getActiveBuses,
};
