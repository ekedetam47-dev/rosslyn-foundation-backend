const { Pool } = require("pg");
require("dotenv").config();

const pool = new Pool({
connectionString: process.env.DATABASE_URL,
ssl: {
rejectUnauthorized: true
},
connectionTimeoutMillis: 10000,
idleTimeoutMillis: 30000,
max: 10
});

pool.on("error", (err) => {
console.error("Unexpected PostgreSQL pool error:", err.message);
});

module.exports = pool;
