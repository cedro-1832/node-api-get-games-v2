const express = require('express');
const { getGames } = require('../controllers/gameController');

const router = express.Router();

// Endpoint modificado para permitir búsqueda con query params
router.get('/', getGames);

module.exports = router;
