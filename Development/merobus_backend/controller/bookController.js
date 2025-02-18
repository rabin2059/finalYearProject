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

    // ✅ Use Prisma Transaction
    const result = await prisma.$transaction(async (tx) => {
      // ✅ Check if booking already exists
      const existingBooking = await tx.booking.findFirst({
        where: {
          vehicleId: vehicleId,
          bookingDate: bookingDate, // Ensure correct format
        },
      });

      if (existingBooking) {
        throw new Error("Booking already exists"); // Transaction will automatically roll back
      }

      // ✅ Create new booking
      const newBooking = await tx.booking.create({
        data: {
          userId: userId,
          vehicleId: vehicleId,
          bookingDate: bookingDate,
          pickUpPoint: pickUpPoint,
          dropOffPoint: dropOffPoint,
        },
      });

      // ✅ Insert seats only if provided
      let bookingSeats = [];
      if (seatNo.length) {
        bookingSeats = await tx.bookSeat.createMany({
          data: seatNo.map((seat) => ({
            bookingId: newBooking.id,
            seatNo: seat, // ✅ Ensure correct field mapping
          })),
        });
      }

      return { newBooking, bookingSeats };
    });

    return res.status(201).json({
      message: "Booking created successfully",
      booking: result.newBooking,
      seats: seatNo || [],
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
        vehicleIdId: parseInt(id),
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
    });
    return res.status(200).json({ booking: booking });
  } catch (error) {
    console.error("Error fetching booking:", error);
    res.status(500).json({ message: error.message || "Server error" });
  }
};

module.exports = { booking, getBookings, getSingleBooking };
