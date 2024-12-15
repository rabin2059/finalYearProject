const prisma = require("../utils/prisma.js");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const signUp = async (req, res) => {
  try {
    const { username, email, password, confirmPassword } = req.body;
    console.log(req.body);
    if (!username || !email || !password || !confirmPassword) {
      return res.status(400).json({ message: "All fields are required" });
    }

    if (password !== confirmPassword) {
      return res.status(400).json({ message: "Password didn't match !" });
    }

    const existingUser = await prisma.user.findFirst({
      where: {
        email: email,
      },
    });

    if (existingUser) {
      return res.status(400).json({ message: "User already exists" });
    }

    const hashPassword = await bcrypt.hash(password, 10);
    console.log(hashPassword);
    
    const user = await prisma.user.create({
      data: {
        username: username,
        email: email,
        password: hashPassword,
        role: 1,
      },
    });
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "20s" }
    );

    res.status(201).json({
      message: "User created successfully",
      user,
      token,
    });
  } catch (error) {
    console.log(error);
    res
      .status(500)
      .json({ message: "Internal server error", error: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: "All fields are required" });
    }
    const user = await prisma.user.findFirst({
      where: {
        email: email,
      },
    });
    if (!user) {
      return res.status(400).json({ message: "User not found" });
    }
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(400).json({ message: "Invalid password" });
    }
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "20s" }
    );
    res.status(200).json({
      message: "Login successful",
      user,
      token,
    });
  } catch (error) {
    console.log(error);
    res
      .status(500)
      .json({ message: "Internal server error", error: error.message });
  }
};

const checkTokenExpiration = async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1]; // Get token from Bearer header

    if (!token) {
      return res.status(401).json({ message: "No token provided" });
    }

    try {
      // Verify and decode the token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Token is valid
      return res.status(200).json({
        valid: true,
        message: "Token is valid",
        expiresIn: new Date(decoded.exp * 1000),
      });
    } catch (err) {
      if (err.name === "TokenExpiredError") {
        return res.status(401).json({
          valid: false,
          message: "Token has expired",
        });
      }
      return res.status(401).json({
        valid: false,
        message: "Invalid token",
      });
    }
  } catch (error) {
    console.log(error);
    res
      .status(500)
      .json({ message: "Internal server error", error: error.message });
  }
};

const logout = async (req, res) => {
  res.clearCookie("token");
  res.status(200).json({ message: "Logout successful" });
};

const root = async (req, res) => {
  return res.status(200).json({ message: "Welcome to the API" });
};

module.exports = {
  root,
  signUp,
  login,
  checkTokenExpiration,
  logout,
};
