const express = require("express");
const router = express.Router();
const authController = require("../controller/authController.js");

// Authentication routes
router.get("/root", authController.root);
router.post("/signUp", authController.signUp);
router.post("/login", authController.login);
router.post("/checkTokenExpiration", authController.checkTokenExpiration);
router.post("/logout", authController.logout);

module.exports = router;
