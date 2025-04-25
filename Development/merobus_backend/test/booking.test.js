const request = require("supertest");
const app = require("../index.js");
const prisma = require("../utils/prisma");

describe("POST /booking", () => {
  it("should create a booking and return 201", async () => {
    const response = await request(app)
      .post("/api/v1/booking")
      .send({
        userId: 5,
        vehicleId: 1,
        bookingDate: new Date().toISOString(),
        pickUpPoint: "Kalanki",
        dropOffPoint: "Pokhara Bus Park",
        totalFare: 1000,
        seatNo: [19, 20],
      });

    expect(response.statusCode).toBe(201);
    expect(response.body).toHaveProperty("success", true);
    expect(response.body.result).toHaveProperty("newBooking");
    expect(response.body.result).toHaveProperty("bookedSeats");
  });

  it("should not create a booking for booked seats and return 500", async () => {
    const response = await request(app)
      .post("/api/v1/booking")
      .send({
        userId: 2,
        vehicleId: 1,
        bookingDate: new Date().toISOString(),
        pickUpPoint: "Kalanki",
        dropOffPoint: "Pokhara Bus Park",
        totalFare: 1000,
        seatNo: [1, 2],
      });

    expect(response.statusCode).toBe(500);
    expect(response.body).toHaveProperty("success", false);
    expect(response.body).toHaveProperty("message", "Seats already booked");
  });

  it("should not complete the request and throw 400 status code", async () => {
    const response = await request(app).post("/api/v1/booking").send({
      userId: 2,
      vehicleId: 1,
      bookingDate: new Date().toISOString(),
      pickUpPoint: "Kalanki",
      dropOffPoint: "Pokhara Bus Park",
      totalFare: 1000,
      seatNo: [],
    });

    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty("success", false);
    expect(response.body).toHaveProperty(
      "message",
      "At least one seat must be selected"
    );
  });
});
