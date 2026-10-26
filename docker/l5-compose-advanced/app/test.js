// Run with `node --test` (the compose `test` profile does this in a container).
const test = require('node:test');
const assert = require('node:assert/strict');
const net = require('node:net');
const { createApp } = require('./server.js');

function start() {
  return new Promise((resolve) => {
    const server = createApp().listen(0, '127.0.0.1', () => resolve(server));
  });
}

test('GET /health returns ok', async () => {
  const server = await start();
  try {
    const res = await fetch(`http://127.0.0.1:${server.address().port}/health`);
    assert.equal(res.status, 200);
    assert.deepEqual(await res.json(), { status: 'ok' });
  } finally {
    server.close();
  }
});

test('GET /config is 404 when no config is mounted', async () => {
  process.env.CONFIG_PATH = '/nonexistent/config.json';
  const server = await start();
  try {
    const res = await fetch(`http://127.0.0.1:${server.address().port}/config`);
    assert.equal(res.status, 404);
  } finally {
    server.close();
  }
});

// Only meaningful inside compose, where DB_HOST points at the database service.
test('database accepts TCP connections', { skip: !process.env.DB_HOST }, async () => {
  await new Promise((resolve, reject) => {
    const socket = net.connect(5432, process.env.DB_HOST, () => {
      socket.end();
      resolve();
    });
    socket.on('error', reject);
  });
});
