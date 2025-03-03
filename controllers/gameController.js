const { dynamoDB, TABLE_NAME } = require('../config/db');
const { ScanCommand } = require('@aws-sdk/lib-dynamodb');

exports.getGames = async (req, res) => {
  try {
    if (!TABLE_NAME) {
      return res.status(500).json({ message: "Error interno: Nombre de la tabla no definido en configuración." });
    }

    const { search } = req.query; // Obtener el parámetro de búsqueda desde la URL
    const params = { TableName: TABLE_NAME };
    const data = await dynamoDB.send(new ScanCommand(params));

    if (!data.Items || data.Items.length === 0) {
      return res.status(404).json({ message: "No hay juegos disponibles" });
    }

    // Aplicar filtro de búsqueda si se proporciona un término
    let filteredGames = data.Items;
    if (search) {
      const searchLower = search.toLowerCase();
      filteredGames = data.Items.filter(game =>
        game.Nombre.toLowerCase().includes(searchLower)
      );
    }

    if (filteredGames.length === 0) {
      return res.status(404).json({ message: "No se encontraron juegos con ese nombre" });
    }

    res.json(filteredGames);
  } catch (error) {
    console.error("Error al obtener juegos:", error);
    res.status(500).json({ message: "Error al obtener juegos", error: error.message });
  }
};
