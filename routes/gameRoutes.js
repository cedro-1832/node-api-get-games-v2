const express = require('express');
const { getGames } = require('../controllers/gameController');

const router = express.Router();

// No se requiere autenticación para obtener juegos
router.get('/', getGames);

module.exports = router;
