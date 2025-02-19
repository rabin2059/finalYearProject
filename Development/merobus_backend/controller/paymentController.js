import prisma from "../utils/prisma.js";

const payment = async (req, res) => {
  try {
    const { userId, bookingId, paymentMethod, amount } = req.body;
    // Check if booking exists
    const booking = await prisma.booking.findFirst({
      where: {
        id: bookingId,
      },
    });

    if (!booking) {
      return res.status(404).json({ message: "Booking not found" });
    }

    // Create payment record
    const payment = await prisma.payment.create({
      data: {
        userId: userId,
        bookingId: bookingId,
        paymentMethod: paymentMethod,
        amount: amount,
      },
    });

    return res.status(200).json({ payment: payment });
  } catch (error) {
    console.error("Error creating payment:", error);
    res.status(500).json({ message: error.message || "Server error" });
  }
};
