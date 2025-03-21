// index.js
const express = require("express");
const routes = require("./route/routes");
require("dotenv").config();
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const { logger } = require("./utils/logger");
const errorHandler = require("./middleware/errorHandler");
const http = require("http");
const { app, server } = require("./controller/socketController");

// Middleware
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
    credentials: true,
  })
);

// Configure helmet with WebSocket friendly options
app.use(
  helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: false,
  })
);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static("uploads"));

// ✅ Enable trust proxy
app.set("trust proxy", 1);

// Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: "Too many requests, please try again later.",
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Routes
app.use("/api/v1", routes);

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", message: "Server is running" });
});

// Error Handling Middleware
app.use(errorHandler);

const port = process.env.PORT || 3000;
server.listen(port, () => {
  logger.info(`Server running on http://localhost:${port}`);
});

// Handle uncaught exceptions
process.on("uncaughtException", (error) => {
  logger.error(`Uncaught Exception: ${error.message}`);
  logger.error(error.stack);
});

// Handle unhandled promise rejections
process.on("unhandledRejection", (reason, promise) => {
  logger.error("Unhandled Rejection at:", promise);
  logger.error("Reason:", reason);
});
