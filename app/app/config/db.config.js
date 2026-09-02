module.exports = {
  HOST: process.env.DB_HOST,
  USER: process.env.DB_USER || "postgres",
  PASSWORD: process.env.DB_PASSWORD,
  DB: process.env.DB_NAME || "testdb",
  dialect: "postgres",
  dialectOptions: {
    ssl: {
      require: true,
      rejectUnauthorized: false
    }
  },
  pool: {
    max: 5,
    min: 0,
    acquire: 30000,
    idle: 10000
  }
};