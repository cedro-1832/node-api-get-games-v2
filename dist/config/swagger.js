const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: "3.0.0",
    info: { title: "PlayStation Games API", version: "1.0.0" },
  },
  apis: ["./routes/*.js"]
};

module.exports = swaggerJsdoc(options);
