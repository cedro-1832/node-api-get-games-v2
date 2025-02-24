const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  const tokenHeader = req.header('Authorization');

  if (!tokenHeader || !tokenHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: "Acceso denegado: Token no proporcionado o incorrecto" });
  }

  const token = tokenHeader.split(' ')[1]; // Extraer solo el token sin "Bearer"

  try {
    const verified = jwt.verify(token, process.env.JWT_SECRET);
    req.user = verified;
    next();
  } catch (error) {
    return res.status(401).json({ message: "Token inválido o expirado" });
  }
};

module.exports = authMiddleware;
