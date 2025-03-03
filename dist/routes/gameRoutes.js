const express = require('express');
const { getGames } = require('../controllers/gameController');

const router = express.Router();

// Permitir filtros a través de query params
router.get('/', getGames);

module.exports = router;
