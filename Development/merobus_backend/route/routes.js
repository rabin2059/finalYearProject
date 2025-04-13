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
const categoryController = require("../controller/categoryController.js");
const chatController = require("../controller/chatController.js");
const protectRoute = require("../middleware/authMiddleware.js");
const notificationController = require("../controller/notificationController.js");
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
router.get("/getMyRoute", driverController.getMyRoute);

// bookings
router.post("/booking", bookController.booking);
router.get("/getBookings", bookController.getBookings);
router.get("/getSingleBooking", bookController.getSingleBooking);
router.get("/getBookingsByVehicle", bookController.getBookingsByVehicle);
router.get("/getBookingByDate", bookController.getBookingByDate);

// vehicle related
router.get("/getVehiclesRoute", vehicleController.getRoute);
router.get("/getActiveBuses", vehicleController.getActiveBuses);
router.get("/getMyPolylines", vehicleController.getMyPolylines);

// payment related
router.post("/initialize", paymentController.initialzeKhalti);
router.get("/makePayment", paymentController.makePayment);

// Chat related
router.get(
  "/groups/user/:userId",
  protectRoute,
  chatController.getUserChatGroups
);

// Get messages for a specific chat group
router.get(
  "/groups/:groupId/messages",
  protectRoute,
  chatController.getChatGroupMessages
);

// Create a new chat group
router.post("/groups", protectRoute, chatController.createChatGroup);

// Add a user to a chat group
router.post(
  "/groups/:groupId/users",
  protectRoute,
  chatController.addUserToChatGroup
);

// Remove a user from a chat group
router.delete(
  "/groups/:groupId/users/:userId",
  protectRoute,
  chatController.removeUserFromChatGroup
);

// Get unread message count for a user
router.get(
  "/messages/unread/:userId",
  protectRoute,
  chatController.getUnreadMessageCount
);

// Mark messages as read
router.put(
  "/messages/read/:userId/:groupId",
  protectRoute,
  chatController.markMessagesAsRead
);

// Get chat group of a vehicle
router.get(
  "/vehicles/:vehicleId/chatGroup",
  protectRoute,
  chatController.chatGroupOfVehicle
);

// category related
router.post("/startTrip", categoryController.startTrip);
router.post("/endTrip", categoryController.endTrip);

router.post("/sendNotification", notificationController.sendNotification);
router.post("/logNotification", notificationController.logNotification);
router.get(
  "/getUserNotifications",
  notificationController.getUserNotifications
);
