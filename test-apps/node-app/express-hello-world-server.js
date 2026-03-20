// Simple Express HTTP server — used as test app across all containerization examples
// Exposes GET / (hello JSON) and GET /health (healthcheck endpoint)
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Node.js container!',
    hostname: require('os').hostname(),
    pid: process.pid,
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server listening on port ${PORT}`);
});
