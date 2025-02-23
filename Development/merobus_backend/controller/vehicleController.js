const prisma = require("../utils/prisma.js");
const polyline = require("@mapbox/polyline");
const turf = require("@turf/turf");

const getRoute = async (req, res) => {
  try {
    const { startLat, startLng, endLat, endLng } = req.query;

    if (!startLat || !startLng || !endLat || !endLng) {
      return res.status(400).json({ message: "Start and End coordinates are required" });
    }

    const startPoint = [parseFloat(startLng), parseFloat(startLat)];
    const endPoint = [parseFloat(endLng), parseFloat(endLat)];

    // ✅ Fetch all routes with polylines
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

    console.log("Fetched Routes:", routes);

    const validRoutes = routes.filter((route) => {
      if (!route.polyline) return false;

      const decodedPolyline = polyline.decode(route.polyline);
      console.log(`Decoded Polyline for route ${route.name}:`, decodedPolyline);

      const routeLine = turf.lineString(
        decodedPolyline.map(([lat, lng]) => [lng, lat]) // ✅ Ensure correct format
      );

      // 🔥 Use `nearestPointOnLine()` to find closest points
      const closestStart = turf.nearestPointOnLine(routeLine, turf.point(startPoint));
      const closestEnd = turf.nearestPointOnLine(routeLine, turf.point(endPoint));

      // ✅ Debug distances
      const startDistance = turf.distance(turf.point(startPoint), closestStart) * 1000; // Convert to meters
      const endDistance = turf.distance(turf.point(endPoint), closestEnd) * 1000; // Convert to meters

      console.log(`Route: ${route.name}`);
      console.log(`Start Distance: ${startDistance.toFixed(2)} meters`);
      console.log(`End Distance: ${endDistance.toFixed(2)} meters`);

      // ✅ Increase threshold distance
      const thresholdDistance = 100000; // 100 km
      const isStartNearRoute = startDistance <= thresholdDistance;
      const isEndNearRoute = endDistance <= thresholdDistance;

      return isStartNearRoute && isEndNearRoute;
    });

    console.log("Valid Routes:", validRoutes);

    if (validRoutes.length === 0) {
      return res.status(404).json({ message: "No vehicles pass through both locations" });
    }

    // ✅ Return matched vehicles
    const vehicles = validRoutes.map((route) => ({
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
    }));

    return res.status(200).json({ vehicles });
  } catch (error) {
    console.error("Error fetching available vehicles:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

module.exports = { getRoute };