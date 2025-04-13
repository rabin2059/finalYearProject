const prisma = require("../utils/prisma.js");

const startTrip = async (req, res) => {
  try {
    const { vehicleId } = req.query;
    console.log(req.body);
    const vehicle = await prisma.vehicle.findUnique({
      where: {
        id: parseInt(vehicleId),
      },
    });
    if (!vehicle) {
      return res.status(404).json({ message: "Vehicle not found" });
    }
    const vehicleTrip = await prisma.vehicle.update({
      where: {
        id: parseInt(vehicleId),
      },
      data: {
        actualDeparture: new Date(),
      },
    });

    res.status(200).json({
      message: "Trip started successfully",
      vehicleTrip,
    });
  } catch (error) {
    console.error("Error starting trip:", error);
    res.status(500).json({ message: error.message || "Server error" });
  }
};

const endTrip = async (req, res) => {
  try {
    const { vehicleId } = req.query;
    const id = parseInt(vehicleId);

    const vehicle = await prisma.vehicle.findUnique({
      where: { id },
    });

    if (!vehicle) {
      return res.status(404).json({ message: "Vehicle not found" });
    }

    const result = await prisma.$transaction(async (tx) => {
      const updatedVehicle = await tx.vehicle.update({
        where: { id },
        data: {
          actualArrival: new Date(),
        },
      });

      const { departure, arrivalTime, actualDeparture, actualArrival } =
        updatedVehicle;
      console.log("Departure:", departure);
      console.log("Arrival Time:", arrivalTime);
      console.log("Actual Departure:", actualDeparture);
      console.log("Actual Arrival:", actualArrival);

      const depDiff =
        new Date(actualDeparture).getTime() - new Date(departure).getTime();
      const arrDiff = actualArrival.getTime() - new Date(arrivalTime).getTime();
      console.log(depDiff, arrDiff);

      let tripCategory;
      if (depDiff < 0 && arrDiff < 0) {
        tripCategory = "early";
      } else if (depDiff > 0 && arrDiff > 0) {
        tripCategory = "late";
      } else if (depDiff < 0 && arrDiff > 0) {
        tripCategory = "earlyStartLateArrival";
      } else if (depDiff > 0 && arrDiff < 0) {
        tripCategory = "lateStartEarlyArrival";
      } else {
        tripCategory = "onTime";
      }

      const performance = await tx.vehiclePerformance.upsert({
        where: { vehicleId: id },
        update: {
          totalTrips: { increment: 1 },
          earlyCount: { increment: tripCategory === "early" ? 1 : 0 },
          onTimeCount: { increment: tripCategory === "onTime" ? 1 : 0 },
          lateCount: { increment: tripCategory === "late" ? 1 : 0 },
          earlyStartLateArrivalCount: {
            increment: tripCategory === "earlyStartLateArrival" ? 1 : 0,
          },
          lateStartEarlyArrivalCount: {
            increment: tripCategory === "lateStartEarlyArrival" ? 1 : 0,
          },
          generatedAt: new Date(),
        },
        create: {
          vehicleId: id,
          totalTrips: 1,
          earlyCount: tripCategory === "early" ? 1 : 0,
          onTimeCount: tripCategory === "onTime" ? 1 : 0,
          lateCount: tripCategory === "late" ? 1 : 0,
          earlyStartLateArrivalCount:
            tripCategory === "earlyStartLateArrival" ? 1 : 0,
          lateStartEarlyArrivalCount:
            tripCategory === "lateStartEarlyArrival" ? 1 : 0,
          category: tripCategory,
        },
      });

      const countMap = {
        early: performance.earlyCount,
        onTime: performance.onTimeCount,
        late: performance.lateCount,
        earlyStartLateArrival: performance.earlyStartLateArrivalCount,
        lateStartEarlyArrival: performance.lateStartEarlyArrivalCount,
      };

      const dominantCategory = Object.entries(countMap).reduce((a, b) =>
        b[1] > a[1] ? b : a
      )[0];

      await tx.vehicle.update({
        where: { id },
        data: {
          timingCategory: dominantCategory,
        },
      });

      return updatedVehicle;
    });

    res.status(200).json({
      message: "Trip ended and performance updated",
      updatedVehicle: result,
    });
  } catch (error) {
    console.error("Error ending trip:", error);
    res.status(500).json({ message: error.message || "Server error" });
  }
};

const categorizeVehicle = async (req, res) => {
  try {
  } catch (error) {
    console.error("Error categorizing vehicle:", error);
    res.status(500).json({ message: error.message || "Server error" });
  }
};

module.exports = {
  startTrip,
  endTrip,
  categorizeVehicle,
};
