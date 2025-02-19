const prisma = require("../utils/prisma.js");

const booking = async (req, res) => {
  try {
    const {
      userId,
      vehicleId,
      bookingDate,
      pickUpPoint,
      dropOffPoint,
      seatNo,
    } = req.body;

    console.log(req.body);

    if (!seatNo || seatNo.length === 0) {
      return res
        .status(400)
        .json({ message: "At least one seat must be selected" });
    }

    // 🔥 Convert seatNo array to an array of integers
    const seatNumbers = seatNo.map((seat) => parseInt(seat, 10));

    const result = await prisma.$transaction(async (tx) => {
      // ✅ Check for existing booked seats
      const existingBookings = await tx.bookSeat.findMany({
        where: {
          seatNo: { in: seatNumbers }, // Now correctly passing as an array of integers
          booking: {
            vehicleId: vehicleId,
            bookingDate: bookingDate,
          },
        },
      });

      if (existingBookings.length > 0) {
        const bookedSeats = existingBookings.map((seat) => seat.seatNo);
        throw new Error(`Seats already booked: ${bookedSeats.join(", ")}`);
      }

      // ✅ Create new booking
      const newBooking = await tx.booking.create({
        data: {
          userId,
          vehicleId,
          bookingDate,
          pickUpPoint,
          dropOffPoint,
        },
      });

      // ✅ Insert seats only if provided
      const bookingSeats = await tx.bookSeat.createMany({
        data: seatNumbers.map((seat) => ({
          bookingId: newBooking.id,
          seatNo: seat,
        })),
      });

      return { newBooking, bookedSeats: seatNumbers };
    });
    console.log("yes booked", result);
    return res.status(201).json({
      success: true,
      result,
    });
  } catch (error) {
    console.error("Error creating booking:", error);
    res.status(500).json({ message: error.message || "Server error" });
  }
};

const getBookings = async (req, res) => {
  try {
    const { id } = req.query;
    const bookings = await prisma.booking.findMany({
      where: {
        vehicleId: parseInt(id),
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
        userId: parseInt(id),
      },
      include: {
        bookingSeats: true,
      },
    });
    return res.status(200).json({ booking: booking });
  } catch (error) {
    console.error("Error fetching booking:", error);
    res.status(500).json({ message: error.message || "Server error" });
  }
};

module.exports = { booking, getBookings, getSingleBooking };
