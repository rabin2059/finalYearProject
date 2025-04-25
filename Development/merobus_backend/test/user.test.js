const request = require("supertest");
const app = require("../index.js");
const prisma = require("../utils/prisma");

describe("POST /login", () => {
  // Test with correct credentials
  it("should return 200 and token data for valid credentials", async () => {
    const response = await request(app).post("/api/v1/login").send({
      email: "test@gmail.com",
      password: "Test@123",
    });
    console.log(response.data);
    expect(response.statusCode).toBe(200);
    expect(response.body).toHaveProperty("token");
  });

  // Incorrect password
  it("should return 400 for incorrect password", async () => {
    const response = await request(app).post("/api/v1/login").send({
      email: "test1@gmail.com",
      password: "Abcd@3333",
    });

    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty("message", "Incorrect Password");
  });

  // Non-registered email
  it("should return 400 for non-registered email", async () => {
    const response = await request(app).post("/api/v1/login").send({
      email: "user12@gmail.com",
      password: "User@1234",
    });

    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty("message", "Email is not registered");
  });

  // Missing data
  it("should return 400 when email and password are missing", async () => {
    const response = await request(app).post("/api/v1/login").send({});
    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty(
      "message",
      "Email and password are required"
    );
  });
});
