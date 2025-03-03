const { dynamoDB, TABLE_NAME } = require('../config/db');
const { ScanCommand } = require('@aws-sdk/lib-dynamodb');

exports.getGames = async (req, res) => {
  try {
    if (!TABLE_NAME) {
      return res.status(500).json({ message: "Error interno: Nombre de la tabla no definido en configuración." });
    }

    const { search, sort } = req.query; // Obtener parámetros de búsqueda y ordenamiento
    const params = { TableName: TABLE_NAME };
    const data = await dynamoDB.send(new ScanCommand(params));

    if (!data.Items || data.Items.length === 0) {
      return res.status(404).json({ message: "No hay juegos disponibles" });
    }

    // 🔍 Filtro de búsqueda si se proporciona un término
    let filteredGames = data.Items;
    if (search) {
      const searchLower = search.toLowerCase();
      filteredGames = data.Items.filter(game =>
        game.Nombre.toLowerCase().includes(searchLower)
      );
    }

    // 🔄 Aplicar ordenamiento según el parámetro `sort`
    if (sort) {
      switch (sort) {
        case "name":
          filteredGames.sort((a, b) => a.Nombre.localeCompare(b.Nombre));
          break;
        case "price_asc":
          filteredGames.sort((a, b) => a.PrecioOferta - b.PrecioOferta);
          break;
        case "price_desc":
          filteredGames.sort((a, b) => b.PrecioOferta - a.PrecioOferta);
          break;
        case "discount":
          filteredGames.sort((a, b) => {
            const discountA = ((a.PrecioOriginal - a.PrecioOferta) / a.PrecioOriginal) * 100;
            const discountB = ((b.PrecioOriginal - b.PrecioOferta) / b.PrecioOriginal) * 100;
            return discountB - discountA; // Mayor descuento primero
          });
          break;
        default:
          return res.status(400).json({ message: "Parámetro de orden inválido" });
      }
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
