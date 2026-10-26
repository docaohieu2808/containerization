// Tiny Express service shared by the Node container examples.
//   GET /        JSON greeting (hostname, pid)
//   GET /health  {"status":"ok"}
const express = require('express');
const os = require('node:os');

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ message: 'Hello from Node.js container!', hostname: os.hostname(), pid: process.pid });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`listening on ${PORT}`);
});
