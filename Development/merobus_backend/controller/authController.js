// // Import required dependencies
// const prisma = require("../utils/prisma.js");
// const bcrypt = require("bcrypt");
// const validator = require("validator");
// const jwt = require("jsonwebtoken");

// // Handle user signup
// const signUp = async (req, res) => {
//   try {
//     // Extract user details from request body
//     const { username, email, password, confirmPassword } = req.body;

//     // Validate required fields
//     if (!username || !email || !password || !confirmPassword) {
//       return res.status(400).json({ message: "All fields are required" });
//     }

//     if (!validator.isEmail(email)) {
//       return res.status(400).json({ message: "Invalid email address" });
//     }

//     if (!validator.isStrongPassword(password)) {
//       return res.status(400).json({ message: "Password is not strong" });
//     }

//     // Check if passwords match
//     if (password !== confirmPassword) {
//       return res.status(400).json({ message: "Password didn't match !" });
//     }

//     // Check if user already exists
//     const existingUser = await prisma.user.findFirst({
//       where: {
//         email: email,
//       },
//     });

//     if (existingUser) {
//       return res.status(400).json({ message: "User already exists" });
//     }

//     // Hash password before storing
//     const hashPassword = await bcrypt.hash(password, 10);
//     console.log(hashPassword);

//     // Create new user in database
//     const user = await prisma.user.create({
//       data: {
//         username: username,
//         email: email,
//         password: hashPassword,
//       },
//     });

//     // Generate JWT token
//     const token = jwt.sign(
//       { userId: user.id, email: user.email },
//       process.env.JWT_SECRET,
//       { expiresIn: "20s" }
//     );

//     // Send success response
//     res.status(201).json({
//       message: "User created successfully",
//       user,
//       token,
//     });
//   } catch (error) {
//     console.log(error);
//     res
//       .status(500)
//       .json({ message: "Internal server error", error: error.message });
//   }
// };

// // Handle user login
// const login = async (req, res) => {
//   try {
//     // Extract login credentials
//     const { email, password } = req.body;
//     if (!email || !password) {
//       return res.status(400).json({ message: "All fields are required" });
//     }

//     // Find user by email
//     const user = await prisma.user.findFirst({
//       where: {
//         email: email,
//       },
//     });
//     if (!user) {
//       return res.status(400).json({ message: "User not found" });
//     }

//     // Verify password
//     const isPasswordValid = await bcrypt.compare(password, user.password);
//     if (!isPasswordValid) {
//       return res.status(400).json({ message: "Invalid password" });
//     }

//     // Generate JWT token
//     const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
//       expiresIn: "20s",
//     });
//     const userRole = user.role;

//     // Send success response
//     res.status(200).json({
//       message: "Login successful",
//       token,
//       userRole,
//     });
//   } catch (error) {
//     console.log(error);
//     res
//       .status(500)
//       .json({ message: "Internal server error", error: error.message });
//   }
// };

// // Check if JWT token is valid and not expired
// const checkTokenExpiration = async (req, res) => {
//   try {
//     // Extract token from authorization header
//     const token = req.headers.authorization?.split(" ")[1]; // Get token from Bearer header

//     if (!token) {
//       return res.status(401).json({ message: "No token provided" });
//     }

//     try {
//       // Verify and decode the token
      // const decoded = jwt.verify(token, process.env.JWT_SECRET);
//       console.log(decoded);

//       // Token is valid - send success response
//       return res.status(200).json({
//         valid: true,
//         message: "Token is valid",
//         expiresIn: new Date(decoded.exp * 1000),
//       });
//     } catch (err) {
//       // Handle expired or invalid tokens
//       if (err.name === "TokenExpiredError") {
//         return res.status(401).json({
//           valid: false,
//           message: "Token has expired",
//         });
//       }
//       return res.status(401).json({
//         valid: false,
//         message: "Invalid token",
//       });
//     }
//   } catch (error) {
//     console.log(error);
//     res
//       .status(500)
//       .json({ message: "Internal server error", error: error.message });
//   }
// };

// // Handle user logout
// const logout = async (req, res) => {
//   res.clearCookie("token");
//   res.status(200).json({ message: "Logout successful" });
// };

// // Root endpoint handler
// const root = async (req, res) => {
//   return res.status(200).json({ message: "Welcome to the API" });
// };

// // Export controller functions
// module.exports = {
//   root,
//   signUp,
//   login,
//   checkTokenExpiration,
//   logout,
// };



const validator = require("validator");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const prisma = require("../utils/prisma.js");
const { logger } = require("../utils/logger");

const signUp = async (req, res, next) => {
  try {
    const { username, email, password, confirmPassword } = req.body;

    // Validate required fields
    if (!username || !email || !password || !confirmPassword) {
      return res.status(400).json({ message: "All fields are required" });
    }

    if (!validator.isEmail(email)) {
      return res.status(400).json({ message: "Invalid email address" });
    }

    if (!validator.isStrongPassword(password)) {
      return res.status(400).json({ message: "Password is not strong" });
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: "Email already in use" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { username, email, password: hashedPassword },
    });

    res.status(201).json({ message: "User created successfully" });
  } catch (error) {
    logger.error(error.message);
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required" });
    }

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: "15m" });
    const refreshToken = jwt.sign({ userId: user.id }, process.env.JWT_REFRESH_SECRET, { expiresIn: "7d" });

    res.status(200).json({ message: "Login successful", token, refreshToken });
  } catch (error) {
    logger.error(error.message);
    next(error);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ message: "Refresh token is required" });
    }

    jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET, (err, decoded) => {
      if (err) {
        return res.status(401).json({ message: "Invalid refresh token" });
      }

      const token = jwt.sign({ userId: decoded.userId }, process.env.JWT_SECRET, { expiresIn: "15m" });
      res.status(200).json({ token });
    });
  } catch (error) {
    logger.error(error.message);
    next(error);
  }
};

module.exports = { signUp, login, refreshToken };