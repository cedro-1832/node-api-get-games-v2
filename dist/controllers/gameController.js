const { dynamoDB, TABLE_NAME } = require('../config/db');
const { ScanCommand } = require('@aws-sdk/lib-dynamodb');

exports.getGames = async (req, res) => {
  try {
    if (!TABLE_NAME) {
      return res.status(500).json({ message: "Error interno: Nombre de la tabla no definido en configuración." });
    }

    // Obtener filtros desde los parámetros de la consulta
    const { Tipo, PrecioMin, PrecioMax, Nombre, DescuentoMin, DescuentoMax } = req.query;
    
    let filterExpression = [];
    let expressionAttributeValues = {};

    // Filtro por Tipo (exacto)
    if (Tipo) {
      filterExpression.push("Tipo = :tipo");
      expressionAttributeValues[":tipo"] = Tipo;
    }

    // Filtro por PrecioOferta (rango)
    if (PrecioMin && PrecioMax) {
      filterExpression.push("PrecioOferta BETWEEN :precioMin AND :precioMax");
      expressionAttributeValues[":precioMin"] = parseFloat(PrecioMin);
      expressionAttributeValues[":precioMax"] = parseFloat(PrecioMax);
    } else if (PrecioMin) {
      filterExpression.push("PrecioOferta >= :precioMin");
      expressionAttributeValues[":precioMin"] = parseFloat(PrecioMin);
    } else if (PrecioMax) {
      filterExpression.push("PrecioOferta <= :precioMax");
      expressionAttributeValues[":precioMax"] = parseFloat(PrecioMax);
    }

    // Filtro por Nombre (búsqueda parcial)
    if (Nombre) {
      filterExpression.push("contains(Nombre, :nombre)");
      expressionAttributeValues[":nombre"] = Nombre;
    }

    // Filtro por Descuento (rango)
    if (DescuentoMin && DescuentoMax) {
      filterExpression.push("Descuento BETWEEN :descuentoMin AND :descuentoMax");
      expressionAttributeValues[":descuentoMin"] = parseFloat(DescuentoMin);
      expressionAttributeValues[":descuentoMax"] = parseFloat(DescuentoMax);
    } else if (DescuentoMin) {
      filterExpression.push("Descuento >= :descuentoMin");
      expressionAttributeValues[":descuentoMin"] = parseFloat(DescuentoMin);
    } else if (DescuentoMax) {
      filterExpression.push("Descuento <= :descuentoMax");
      expressionAttributeValues[":descuentoMax"] = parseFloat(DescuentoMax);
    }

    const params = {
      TableName: TABLE_NAME,
    };

    if (filterExpression.length > 0) {
      params.FilterExpression = filterExpression.join(" AND ");
      params.ExpressionAttributeValues = expressionAttributeValues;
    }

    const data = await dynamoDB.send(new ScanCommand(params));

    if (!data.Items || data.Items.length === 0) {
      return res.status(404).json({ message: "No hay juegos disponibles con los filtros aplicados" });
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
