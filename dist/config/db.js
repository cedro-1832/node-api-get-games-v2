const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient } = require('@aws-sdk/lib-dynamodb');
require('dotenv').config();

if (!process.env.AWS_REGION || !process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY) {
  throw new Error("❌ Error: Variables de entorno AWS_REGION, AWS_ACCESS_KEY_ID o AWS_SECRET_ACCESS_KEY no están configuradas.");
}

const client = new DynamoDBClient({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  }
});

const dynamoDB = DynamoDBDocumentClient.from(client);
const TABLE_NAME = "PlayStationGames";

module.exports = { dynamoDB, TABLE_NAME };
