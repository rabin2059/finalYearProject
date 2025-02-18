const multer = require("multer");
const path = require("path");

// Define storage for multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Define the upload folder for images
    cb(null, "uploads/");
  },
  filename: (req, file, cb) => {
    // Use current timestamp as filename to avoid duplicates
    cb(null, Date.now() + path.extname(file.originalname));
  },
});

// Configure multer for image uploads
const upload = multer({ storage: storage });

module.exports = upload;
