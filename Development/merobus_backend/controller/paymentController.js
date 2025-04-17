const admin = require("firebase-admin");
const prisma = require("../utils/prisma.js");
const {
  initializeKhaltiPayment,
  verifyKhaltiPayment,
} = require("../controller/khalti.js");

const initialzeKhalti = async (req, res) => {
  try {
    const { bookingId, userId, amount, website_url } = req.body;

    const booking = await prisma.booking.findFirst({
      where: { id: parseInt(bookingId) },
    });

    if (!booking) {
      return res.status(404).json({ message: "Booking not found" });
    }

    const bookPayment = await prisma.payment.create({
      data: {
        bookingId: parseInt(bookingId),
        userId: parseInt(userId),
        amount: amount * 100,
        paymentMethod: "Khalti",
      },
    });

    const paymentInitiate = await initializeKhaltiPayment({
      amount: amount * 100,
      purchase_order_id: bookPayment.id,
      purchase_order_name: "Book Payment",
      return_url: "http://localhost:3089/api/v1/makePayment",
      website_url,
    });

    return res.status(200).json({ paymentInitiate });
  } catch (error) {
    console.error("Error initializing Khalti payment:", error);
    res.status(500).json({ message: error.message || "Server error" });
  }
};

const makePayment = async (req, res) => {
  try {
    const {
      pidx,
      txnId,
      amount,
      phone,
      purchase_order_id,
      purchase_order_name,
      transaction_id,
    } = req.query;

    console.log(req.query);

    const paymentInfo = await verifyKhaltiPayment(pidx);
    console.log(paymentInfo);

    if (
      paymentInfo?.status !== "Completed" ||
      paymentInfo?.transaction_id !== transaction_id ||
      paymentInfo?.total_amount !== Number(amount)
    ) {
      return res.status(400).json({ message: "Payment verification failed" });
    }

    const paymentCheck = await prisma.payment.findFirst({
      where: { id: parseInt(purchase_order_id) },
    });

    if (!paymentCheck) {
      return res.status(404).json({ message: "Payment not found" });
    }

    await prisma.payment.update({
      where: { id: parseInt(paymentCheck.id) },
      data: {
        status: "COMPLETED",
        id: txnId,
        paymentMethod: "Khalti",
        amount: parseInt(amount / 100),
      },
    });

    await prisma.booking.update({
      where: { id: parseInt(paymentCheck.bookingId) },
      data: { status: "CONFIRMED" },
    });

    const booking = await prisma.booking.findUnique({
      where: { id: parseInt(paymentCheck.bookingId) },
    });

    const user = await prisma.user.findUnique({
      where: { id: parseInt(paymentCheck.userId) },
    });

    if (user?.fcmToken) {
      // Send FCM display notification
      await admin.messaging().send({
        token: user.fcmToken,
        notification: {
          title: "Payment Success",
          body: `Your payment for booking #${booking.id} has been confirmed.`,
        },
      });

      // Log to notifications table
      await prisma.notification.create({
        data: {
          userId: user.id,
          title: "Payment Success",
          body: `Your payment for booking #${booking.id} has been confirmed.`,
        },
      });
    }

    return res.status(200).json({
      message: "Payment made successfully",
      paymentInfo: paymentInfo,
    });
  } catch (error) {
    console.error("Error making payment:", error);
    res.status(500).json({ message: error.message || "Server error" });
  }
};

module.exports = { initialzeKhalti, makePayment };
