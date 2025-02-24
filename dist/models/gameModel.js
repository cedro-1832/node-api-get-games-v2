const Joi = require('joi');

const gameSchema = Joi.object({
  game_id: Joi.string().required(),
  Nombre: Joi.string().required(),
  Tipo: Joi.string().required(),
  PrecioOferta: Joi.number().required(),
  PrecioOriginal: Joi.number(),
  LinkCompra: Joi.string().uri().required()
});

module.exports = gameSchema;
