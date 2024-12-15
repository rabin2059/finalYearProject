const transporter = require("../configs/mailconfigs");
const prisma = require("../utils/prisma.js");
const bcrypt = require("bcrypt");

const reqOTP = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await prisma.user.findUnique({
      where: {
        email: email,
      },
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const otp = Math.floor(1000 + Math.random() * 9000).toString();
    const hashedOTP = await bcrypt.hash(otp, 10);

    // Update the OTP in the database
    await prisma.user.update({
      where: { id: user.id },
      data: { otp: hashedOTP },
    });

    // Send response before initiating the email to avoid delays
    res.status(200).json({ message: "OTP sent to email" });
    console.log(otp);

    // Configure and send the email
    const mailOptions = {
      from: "rai2059rabin@gmail.com",
      to: email,
      subject: "OTP for password reset",
      text: `Your OTP is ${otp}`,
    };
    console.log(mailOptions);
    await transporter.sendMail(mailOptions);

    // Clear the OTP after 6 minutes
    setTimeout(async () => {
      try {
        await prisma.user.update({
          where: { id: user.id },
          data: { otp: null },
        });
      } catch (error) {
        console.error("Error clearing OTP:", error.message); // Log the error but don't send a response
      }
    }, 360000);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

const verifyOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;

    const user = await prisma.user.findUnique({
      where: {
        email: email,
      },
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const isOTPValid = await bcrypt.compare(otp, user.otp);

    if (!isOTPValid) {
      return res.status(401).json({ message: "Invalid OTP" });
    }

    // Clear OTP after successful verification
    await prisma.user.update({
      where: { id: user.id },
      data: { otp: null },
    });

    res.status(200).json({ message: "OTP verified" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

const resetPassword = async (req, res) => {
  try {
    const { email, password, confirmPassword } = req.body;

    const user = await prisma.user.findUnique({
      where: {
        email: email,
      },
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (password !== confirmPassword) {
      return res.status(400).json({ message: "Passwords do not match" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    // Update the password and clear OTP in a single operation
    await prisma.user.update({
      where: { email: email },
      data: { password: hashedPassword, otp: null },
    });

    res.status(200).json({ message: "Password reset successful" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = { reqOTP, verifyOTP, resetPassword };
