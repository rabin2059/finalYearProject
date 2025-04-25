const request = require("supertest");
const app = require("../index.js");
const prisma = require("../utils/prisma");

describe("POST /signUp", () => {
  it("should return 201 and success message for successful registration", async () => {
    const response = await request(app).post("/api/v1/signUp").send({
      username: "Sujan Mahara",
      email: "sujan@gmail.com",
      password: "Sujan@123",
      confirmPassword: "Sujan@123",
    });
    console.log(response.body);
    expect(response.statusCode).toBe(201);
    expect(response.body).toHaveProperty(
      "message",
      "User created successfully"
    );
  });

  it("should return 400 if required fields are missing", async () => {
    const response = await request(app).post("/api/v1/signUp").send({});
    console.log(response.body);
    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty("message", "All fields are required");
  });

  it("should return 400 for invalid email", async () => {
    const response = await request(app).post("/api/v1/signUp").send({
      username: "Test User",
      email: "invalidemail",
      password: "ValidPass@123",
      confirmPassword: "ValidPass@123",
    });
    console.log(response.body);
    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty("message", "Invalid email address");
  });

  it("should return 400 for weak password", async () => {
    const response = await request(app).post("/api/v1/signUp").send({
      username: "Test User",
      email: "test12@gmail.com",
      password: "123",
      confirmPassword: "123",
    });
    console.log(response.body);
    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty("message", "Password is not strong");
  });

  it("should return 400 for mismatched passwords", async () => {
    const response = await request(app).post("/api/v1/signUp").send({
      username: "Mismatch User",
      email: "test13@gmail.com",
      password: "Test@123",
      confirmPassword: "Test@456",
    });
    console.log(response.body);
    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty("message", "Passwords do not match");
  });

  it("should return 400 for duplicate email", async () => {
    await prisma.user.create({
      data: {
        username: "Test15",
        email: "test15@gmail.com",
        password: "Test15@123",
      },
    });

    const response = await request(app).post("/api/v1/signUp").send({
      username: "Test 16 User",
      email: "test15@gmail.com",
      password: "Test1@123",
      confirmPassword: "Test1@123",
    });
    console.log(response.body);
    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty("message", "Email already in use");
  });
});
