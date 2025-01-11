const express = require("express");
const router = express.Router();
const authController = require("../controller/authController.js");
const resetPasswordController = require("../controller/resetPassword.js");
const userRelatedController = require("../controller/user_related.js");
const adminController = require("../controller/adminController.js");
const driverController = require("../controller/driverController.js");

// Authentication routes
router.get("/root", authController.root);
router.post("/signUp", authController.signUp);
router.post("/login", authController.login);
router.post("/checkTokenExpiration", authController.checkTokenExpiration);
router.post("/logout", authController.logout);

// Reset password routes
router.post("/reqOTP", resetPasswordController.reqOTP);
router.post("/verifyOTP", resetPasswordController.verifyOTP);
router.put("/resetPassword", resetPasswordController.resetPassword);

// Change role routes
router.put("/updateUser", userRelatedController.updateUser);
router.get("/getUser", userRelatedController.getUser);

//
router.put("/requestRole", adminController.requestRole);
router.put("/validDriverRole", adminController.validDriverRole);
router.get("/getAllUser", adminController.getAllUser);
module.exports = router;


//vehicles
router.get("/getVehicles", driverController.getVehicles);