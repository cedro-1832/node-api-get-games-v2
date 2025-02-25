const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient } = require('@aws-sdk/lib-dynamodb');
require('dotenv').config();

if (!process.env.AWS_REGION) {
  throw new Error("❌ Error: La variable de entorno AWS_REGION no está configurada.");
}

const client = new DynamoDBClient({
  region: process.env.AWS_REGION,
  credentials: process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY
    ? {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
      }
    : undefined, // Si está en AWS Lambda, usa las credenciales del IAM Role
});

const dynamoDB = DynamoDBDocumentClient.from(client);
const TABLE_NAME = "PlayStationGames";

module.exports = { dynamoDB, TABLE_NAME };
