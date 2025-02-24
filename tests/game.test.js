const request = require('supertest');
const app = require('../server');

describe('POST /api/auth/login', () => {
  it('Debería retornar un token si las credenciales son correctas', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: "admin@playstation.com", password: "123456" });

    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('token');
  });

  it('Debería fallar si las credenciales son incorrectas', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: "wrong@user.com", password: "wrongpassword" });

    expect(res.statusCode).toBe(400);
  });
});
