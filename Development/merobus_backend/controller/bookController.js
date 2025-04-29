const prisma = require("../utils/prisma.js");
const admin = require("firebase-admin");

const booking = async (req, res) => {
  try {
    const {
      userId,
      vehicleId,
      bookingDate,
      pickUpPoint,
      dropOffPoint,
      totalFare,
      seatNo,
    } = req.body;

    console.log(req.body);

    if (!seatNo || seatNo.length === 0) {
      return res
        .status(400)
        .json({
          success: false,
          message: "At least one seat must be selected",
        });
    }

    const seatNumbers = seatNo.map((seat) => parseInt(seat, 10));

    const result = await prisma.$transaction(async (tx) => {
      const inputDate = new Date(bookingDate);
      const startDate = new Date(inputDate.setUTCHours(0, 0, 0, 0));
      const endDate = new Date(inputDate.setUTCHours(23, 59, 59, 999));

      const existingBookings = await tx.bookSeat.findMany({
        where: {
          seatNo: { in: seatNumbers },
          booking: {
            vehicleId,
            bookingDate: {
              gte: startDate,
              lte: endDate,
            },
          },
        },
      });

      if (existingBookings.length > 0) {
        const bookedSeats = existingBookings.map((seat) => seat.seatNo);
        throw { status: 500, message: "Seats already booked" };
      }

      const newBooking = await tx.booking.create({
        data: {
          userId,
          vehicleId,
          bookingDate,
          pickUpPoint,
          dropOffPoint,
          totalFare,
        },
      });

      const bookingSeats = await tx.bookSeat.createMany({
        data: seatNumbers.map((seat) => ({
          bookingId: newBooking.id,
          seatNo: seat,
        })),
      });

      const user = await tx.user.findUnique({ where: { id: userId } });

      return { newBooking, bookedSeats: seatNumbers };
    });
    const notificationTitle = "Booking Confirmed";
    const notificationBody = `Your seats on vehicle ${vehicleId} are confirmed.`;

    const bookingUser = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });
    if (process.env.NODE_ENV !== "test" && bookingUser?.fcmToken) {
      await admin.messaging().send({
        token: bookingUser.fcmToken,
        notification: { title: notificationTitle, body: notificationBody },
      });
    }
    await prisma.notification.create({
      data: { userId, title: notificationTitle, body: notificationBody },
    });
    return res.status(201).json({
      success: true,
      result,
    });
  } catch (error) {
    if (process.env.NODE_ENV !== "test") {
      console.error("Error creating booking:", error);
    }
    if (error?.status && error?.message) {
      return res
        .status(error.status)
        .json({ success: false, message: error.message });
    }
    return res.status(500).json({ message: error.message || "Server error" });
  }
};

const getBookings = async (req, res) => {
  try {
    const { id } = req.query;
    const bookings = await prisma.booking.findMany({
      where: {
        userId: parseInt(id),
      },
      include: {
        bookingSeats: true,
      },
    });

    return res.status(200).json({ booking: bookings });
  } catch (error) {
    console.error("Error fetching bookings:", error);
    res.status(500).json({ message: error.message || "Server error" });
  }
};

const getSingleBooking = async (req, res) => {
  try {
    const { id } = req.query;
    const booking = await prisma.booking.findFirst({
      where: {
        id: parseInt(id),
      },
      include: {
        bookingSeats: true,
      },
    });
    return res.status(200).json({ book: booking });
  } catch (error) {
    console.error("Error fetching booking:", error);
    res.status(500).json({ message: error.message || "Server error" });
  }
};

const getBookingsByVehicle = async (req, res) => {
  try {
    const { vehicleId, page = 1 } = req.query;
    console.log(vehicleId);
    const bookings = await prisma.booking.findMany({
      where: {
        vehicleId: parseInt(vehicleId),
      },
      include: {
        bookingSeats: true,
      },
      orderBy: {
        createdAt: "desc",
      },
      take: 5,
      skip: (parseInt(page) - 1) * 5,
    });

    return res.status(200).json({ bookingByVehicle: bookings });
  } catch (error) {
    console.error("Error fetching bookings:", error);
    res.status(500).json({ message: error.message || "Server error" });
  }
};

const getBookingByDate = async (req, res) => {
  try {
    const { date, vehicleId, page = 1 } = req.query;
    console.log(req.query);

    if (!date) {
      return res
        .status(400)
        .json({ error: "Date query parameter is required" });
    }
    if (!vehicleId || isNaN(parseInt(vehicleId))) {
      return res
        .status(400)
        .json({ error: "Valid vehicleId parameter is required" });
    }

    const inputDate = new Date(date).toISOString().split("T")[0];

    const startDate = new Date(`${inputDate}T00:00:00.000Z`);
    const endDate = new Date(`${inputDate}T23:59:59.999Z`);

    const bookings = await prisma.booking.findMany({
      where: {
        bookingDate: {
          gte: startDate,
          lte: endDate,
        },
        vehicleId: parseInt(vehicleId),
      },
      include: {
        bookingSeats: true,
      },
      orderBy: {
        createdAt: "desc",
      },
      take: 5,
      skip: (parseInt(page) - 1) * 5,
    });

    res.status(200).json(bookings);
  } catch (error) {
    console.error("Error fetching bookings:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

module.exports = {
  booking,
  getBookings,
  getSingleBooking,
  getBookingsByVehicle,
  getBookingByDate,
};
