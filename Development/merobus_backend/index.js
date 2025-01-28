// const express = require("express");
// const routes = require("./route/routes");
// require("dotenv").config();
// const app = express();
// const cors = require("cors");
// app.use(cors());

// app.use(express.json());

// app.use("./uploads", express.static("uploads"));

// // Use the routes
// app.use("/api", routes);

// const port = process.env.PORT || 3000;
// app.listen(port, () => {
//   console.log(`Server is running on http://localhost:${port}`);
// });


// Entry Point: index.js
const express = require("express");
const routes = require("./route/routes");
require("dotenv").config();
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const { logger } = require("./utils/logger");
const errorHandler = require("./middleware/errorHandler");

const app = express();

// Middleware
app.use(cors());
app.use(helmet());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static("uploads"));

// Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: "Too many requests, please try again later."
});
app.use(limiter);

// Routes
app.use("/api/v1", routes);

// Error Handling Middleware
app.use(errorHandler);

const port = process.env.PORT || 3000;
app.listen(port, () => {
  logger.info(`Server running on http://localhost:${port}`);
});