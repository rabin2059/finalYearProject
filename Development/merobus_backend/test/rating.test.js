const request = require("supertest");
const app = require("../index.js");
const prisma = require("../utils/prisma");

describe("POST /rating", () => {
  beforeAll(async () => {
    const loginResponse = await request(app).post("/api/v1/login").send({
      email: "pass@gmail.com",
      password: "Rar0696@",
    });
    token = loginResponse.body.token;
  });

  it("should successfully create a review", async () => {
    const response = await request(app)
      .post("/api/v1/rating")
      .set("Authorization", `Bearer ${token}`)
      .send({
        driverId: 1,
        rating: 5,
        review:
          "I had an excellent experience with this driver. From the very beginning, the communication was clear and professional. He arrived exactly on time, the vehicle was exceptionally clean and well-maintained, and the entire journey was incredibly comfortable. The driver demonstrated great knowledge of the routes, avoiding traffic-heavy areas and ensuring that we reached our destination promptly. ",
      });

    console.log("Successful Review Response:", response.body);

    expect(response.statusCode).toBe(201);
    expect(response.body.message).toBe("Review added successfully");
    expect(response.body.result).toHaveProperty("id");
  });

  it("should fail when driverId or rating is missing", async () => {
    const response = await request(app)
      .post("/api/v1/rating")
      .set("Authorization", `Bearer ${token}`)
      .send({});

    console.log("Missing Fields Response:", response.body);

    expect(response.statusCode).toBe(400);
    expect(response.body.message).toBe("Driver ID and rating are required.");
  });

  it("should fail when review is missing", async () => {
    const response = await request(app)
      .post("/api/v1/rating")
      .set("Authorization", `Bearer ${token}`)
      .send({
        driverId: 1,
        rating: 4,
        review: "",
      });

    console.log("Missing Fields Response:", response.body);

    expect(response.statusCode).toBe(400);
    expect(response.body.message).toBe("Review is Required");
  });

  it("should fail when rating is invalid", async () => {
    const response = await request(app)
      .post("/api/v1/rating")
      .set("Authorization", `Bearer ${token}`)
      .send({
        driverId: 1,
        rating: 10,
        review: "This should fail because rating > 5",
      });

    console.log("Invalid Rating Response:", response.body);

    expect(response.statusCode).toBe(400);
    expect(response.body.message).toBe("Rating must be between 1 and 5.");
  });
});
