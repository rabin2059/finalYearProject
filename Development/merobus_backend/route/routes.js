const express = require("express");
const router = express.Router();
const authController = require("../controller/authController.js");
const resetPasswordController = require("../controller/resetPassword.js");
const userRelatedController = require("../controller/user_related.js");
const adminController = require("../controller/adminController.js");
const driverController = require("../controller/driverController.js");
const bookController = require("../controller/bookController.js");
const vehicleController = require("../controller/vehicleController.js");
const paymentController = require("../controller/paymentController.js");
const chatController = require("../controller/chatController.js");
const upload = require("../configs/storage.js");

// Authentication routes
router.post("/signUp", authController.signUp);
router.post("/login", authController.login);
router.post("/refreshToken", authController.refreshToken);

// Reset password routes
router.post("/reqOTP", resetPasswordController.reqOTP);
router.post("/verifyOTP", resetPasswordController.verifyOTP);
router.put("/resetPassword", resetPasswordController.resetPassword);

// Change role routes
router.put(
  "/updateUser",
  upload.single("images"),
  userRelatedController.updateUser
);
router.get("/getUser", userRelatedController.getUser);

//
router.put(
  "/requestRole",
  upload.single("images"),
  adminController.requestRole
);
router.put("/validDriverRole", adminController.validDriverRole);
router.get("/getAllUser", adminController.getAllUser);
module.exports = router;

//vehicles
router.post("/addVehicle", driverController.addVehicle);
router.post("/createRoute", driverController.createRoute);
router.get("/getVehicles", driverController.getVehicles);
router.get("/getSingleVehicle", driverController.getSingleVehicle);

// bookings
router.post("/booking", bookController.booking);
router.get("/getBookings", bookController.getBookings);
router.get("/getSingleBooking", bookController.getSingleBooking);
router.get("/getBookingsByVehicle", bookController.getBookingsByVehicle);

// vehicle related
router.get("/getVehiclesRoute", vehicleController.getRoute);

// payment related
router.post("/initialize", paymentController.initialzeKhalti);
router.get("/makePayment", paymentController.makePayment);

// Chat related
router.post("/sendMessage", chatController.sendMessage);
router.get("/getMessage/:roomId", chatController.getMessages);
