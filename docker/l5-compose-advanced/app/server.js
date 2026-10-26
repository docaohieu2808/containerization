// Express service for the compose example.
//   GET /              greeting
//   GET /health        {"status":"ok"}
//   GET /config        the JSON file injected by the compose `configs:` entry
//   GET /secret-check  whether the compose `secrets:` file is mounted (never its value)
const express = require('express');
const fs = require('node:fs');
const os = require('node:os');

const CONFIG_PATH = process.env.CONFIG_PATH || '/app/config.json';
const SECRET_PATH = process.env.DB_PASSWORD_FILE || '/run/secrets/db_password';

function createApp() {
  const app = express();

  app.get('/', (req, res) => {
    res.json({ message: 'Hello from the compose example!', hostname: os.hostname(), pid: process.pid });
  });

  app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
  });

  app.get('/config', (req, res) => {
    if (!fs.existsSync(CONFIG_PATH)) {
      return res.status(404).json({ error: 'config not mounted' });
    }
    res.json(JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8')));
  });

  app.get('/secret-check', (req, res) => {
    if (!fs.existsSync(SECRET_PATH)) {
      return res.status(404).json({ mounted: false });
    }
    // Report only that the secret is readable and non-empty, never the value.
    res.json({ mounted: true, nonEmpty: fs.readFileSync(SECRET_PATH, 'utf8').trim().length > 0 });
  });

  return app;
}

module.exports = { createApp };

if (require.main === module) {
  const port = process.env.PORT || 3000;
  createApp().listen(port, '0.0.0.0', () => console.log(`listening on ${port}`));
}
