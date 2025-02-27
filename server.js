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

app.use("/api/games", gameRoutes);
app.use("/api/auth", authRoutes);

app.use((err, req, res, next) => {
  console.error("❌ Error en el servidor:", err);
  res.status(500).json({ message: "Error interno en el servidor" });
});

module.exports.handler = serverless(app);
