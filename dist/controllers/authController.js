const jwt = require('jsonwebtoken');

const USER_DEFAULT = {
  email: "admin@playstation.com",
  password: "123456"
};

const login = async (req, res) => {
  const { email, password } = req.body;

  try {
    if (email !== USER_DEFAULT.email || password !== USER_DEFAULT.password) {
      return res.status(400).json({ message: "Usuario o contraseña incorrectos" });
    }

    if (!process.env.JWT_SECRET) {
      console.error("❌ Error: JWT_SECRET no está definido en el archivo .env");
      return res.status(500).json({ message: "Error interno en el servidor: Configuración faltante" });
    }

    const token = jwt.sign({ email: USER_DEFAULT.email }, process.env.JWT_SECRET, { expiresIn: "1h" });

    res.json({ token });
  } catch (error) {
    console.error("Error en login:", error);
    res.status(500).json({ message: "Error en el servidor", error: error.message });
  }
};

module.exports = { login };
