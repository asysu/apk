import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { after, before, test } from 'node:test';

let serverProcess;
let baseUrl;

before(async () => {
  const probe = createServer();
  await new Promise((resolve) => probe.listen(0, '127.0.0.1', resolve));
  const port = probe.address().port;
  await new Promise((resolve) => probe.close(resolve));

  serverProcess = spawn(process.execPath, ['server.mjs'], {
    cwd: new URL('..', import.meta.url),
    env: {
      ...process.env,
      PORT: String(port),
    },
    stdio: 'ignore',
  });
  baseUrl = `http://127.0.0.1:${port}`;

  for (let attempt = 0; attempt < 40; attempt++) {
    try {
      await fetch(`${baseUrl}/not-found`);
      return;
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
  }
  throw new Error('Coach server did not start.');
});

after(() => {
  serverProcess?.kill('SIGTERM');
});

test('rejects tutor requests with an unsupported subject', async () => {
  const response = await fetch(`${baseUrl}/ask`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ subject: 'other', question: 'Explain this' }),
  });
  assert.equal(response.status, 400);
});

test('returns service unavailable without exposing API keys when AI is unconfigured', async () => {
  const response = await fetch(`${baseUrl}/ask`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      subject: 'mathematics',
      question: 'How do I solve a quadratic equation?',
    }),
  });
  assert.equal(response.status, 503);
  assert.deepEqual(await response.json(), {
    error: 'AI assistant is temporarily unavailable.',
  });
});

test('rejects an empty teaching topic', async () => {
  const response = await fetch(`${baseUrl}/teach`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ subject: 'english', topic: ' ' }),
  });
  assert.equal(response.status, 400);
});
