const request = require("supertest");

const app = require("../server");

describe("Application API", () => {
  test("GET / should return welcome message", async () => {
    const response = await request(app).get("/");

    expect(response.statusCode).toBe(200);
    expect(response.body).toEqual({
      message: "Welcome to bezkoder application."
    });
  });
});
