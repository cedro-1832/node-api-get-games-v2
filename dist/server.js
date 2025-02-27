const express = require('express');
const serverless = require('serverless-http');
const helmet = require('helmet');
const cors = require('cors');

const gameRoutes = require('./routes/gameRoutes');
const authRoutes = require('./routes/authRoutes');

const app = express();

app.use(express.json());
app.use(helmet());
app.use(cors({ origin: "*" }));

// Base Path compatible con API Gateway
const BASE_PATH = process.env.BASE_PATH || "/dev";

app.use(`${BASE_PATH}/api/games`, gameRoutes);
app.use(`${BASE_PATH}/api/auth`, authRoutes);

// Middleware de error
app.use((err, req, res, next) => {
  console.error("❌ Error en el servidor:", err);
  res.status(500).json({ message: "Error interno en el servidor" });
});

module.exports.handler = serverless(app);
