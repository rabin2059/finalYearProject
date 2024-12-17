const express = require("express");
const router = express.Router();
const authController = require("../controller/authController.js");
const resetPasswordController = require("../controller/resetPassword.js");
const updateUserController = require("../controller/update_user.js");
// Authentication routes
router.get("/root", authController.root);
router.post("/signUp", authController.signUp);
router.post("/login", authController.login);
router.post("/checkTokenExpiration", authController.checkTokenExpiration);
router.post("/logout", authController.logout);

// Reset password routes
router.post("/reqOTP", resetPasswordController.reqOTP);
router.post("/verifyOTP", resetPasswordController.verifyOTP);
router.post("/resetPassword", resetPasswordController.resetPassword);

// Change role routes
router.post("/changeRole", updateUserController.changeRole);
router.post("/updateUser", updateUserController.updateUser);
module.exports = router;
