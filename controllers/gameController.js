const { dynamoDB, TABLE_NAME } = require('../config/db');
const { ScanCommand } = require('@aws-sdk/lib-dynamodb');

exports.getGames = async (req, res) => {
  try {
    if (!TABLE_NAME) {
      return res.status(500).json({ message: "Error interno: Nombre de la tabla no definido en configuración." });
    }

    const params = { TableName: TABLE_NAME };
    const data = await dynamoDB.send(new ScanCommand(params));

    if (!data.Items || data.Items.length === 0) {
      return res.status(404).json({ message: "No hay juegos disponibles" });
    }

    res.json(data.Items);
  } catch (error) {
    if (error.name === 'UnrecognizedClientException') {
      return res.status(401).json({ message: "Error de autenticación en AWS", error: error.message });
    }
    console.error("Error al obtener juegos:", error);
    res.status(500).json({ message: "Error al obtener juegos", error: error.message });
  }
};
