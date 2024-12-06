const express = require("express");
const routes = require("./route/routes");
require("dotenv").config();
const app = express();

app.use(express.json());

// Use the routes
app.use("/api", routes);

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
