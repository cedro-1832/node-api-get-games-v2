const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient } = require('@aws-sdk/lib-dynamodb');
require('dotenv').config();

// Validar variables de entorno
if (!process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY || !process.env.AWS_REGION) {
  throw new Error("❌ Error: Credenciales de AWS no configuradas correctamente en .env");
}

// Configurar el cliente de DynamoDB con AWS SDK v3
const client = new DynamoDBClient({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  }
});

// Usar DocumentClient para facilitar las operaciones
const dynamoDB = DynamoDBDocumentClient.from(client);
const TABLE_NAME = "PlayStationGames";

module.exports = { dynamoDB, TABLE_NAME };
