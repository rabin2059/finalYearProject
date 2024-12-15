const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  secure: true,
  port: 465,
  host: "smtp.gmail.com",
  service: "gmail",
  auth: {
    user: "rai2059rabin@gmail.com",
    pass: "bryiyihdgowsjvlt",
  },
});

module.exports = transporter;
