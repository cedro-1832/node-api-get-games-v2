const { dynamoDB, TABLE_NAME } = require('../config/db');
const { ScanCommand } = require('@aws-sdk/lib-dynamodb');

exports.getGames = async (req, res) => {
  try {
    if (!TABLE_NAME) {
      return res.status(500).json({ message: "Error interno: Nombre de la tabla no definido en configuración." });
    }

    let params = { TableName: TABLE_NAME };
    const data = await dynamoDB.send(new ScanCommand(params));

    if (!data.Items || data.Items.length === 0) {
      return res.status(404).json({ message: "No hay juegos disponibles" });
    }

    let games = data.Items;

    // **Aplicar filtros basados en query params**
    const { Tipo, PrecioMin, PrecioMax, Nombre, DescuentoMin, DescuentoMax } = req.query;

    if (Tipo) {
      games = games.filter(game => game.Tipo === Tipo);
    }

    if (PrecioMin || PrecioMax) {
      const minPrice = PrecioMin ? parseFloat(PrecioMin) : Number.MIN_VALUE;
      const maxPrice = PrecioMax ? parseFloat(PrecioMax) : Number.MAX_VALUE;
      games = games.filter(game => parseFloat(game.PrecioOferta.replace('$', '')) >= minPrice &&
                                    parseFloat(game.PrecioOferta.replace('$', '')) <= maxPrice);
    }

    if (Nombre) {
      games = games.filter(game => game.Nombre.toLowerCase().includes(Nombre.toLowerCase()));
    }

    if (DescuentoMin || DescuentoMax) {
      const minDiscount = DescuentoMin ? parseInt(DescuentoMin.replace('%', '')) : Number.MIN_VALUE;
      const maxDiscount = DescuentoMax ? parseInt(DescuentoMax.replace('%', '')) : Number.MAX_VALUE;
      games = games.filter(game => {
        const discountValue = parseInt(game.Descuento.replace('%', ''));
        return discountValue >= minDiscount && discountValue <= maxDiscount;
      });
    }

    res.json(games);
  } catch (error) {
    console.error("Error al obtener juegos:", error);
    res.status(500).json({ message: "Error al obtener juegos", error: error.message });
  }
};
