const express = require("express");
const routes = require("./route/routes");
require("dotenv").config();
const app = express();
const cors = require("cors");
app.use(cors());

app.use(express.json());

app.use("./uploads", express.static("uploads"));

// Use the routes
app.use("/api", routes);

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
