import { spawn } from 'node:child_process';
import { access } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const root = process.cwd();
const appDir = path.join(root, 'apps', 'web');
const distDir = path.join(appDir, '.next');
const requiredArtifacts = [
  'BUILD_ID',
  'build-manifest.json',
  'routes-manifest.json',
  'prerender-manifest.json',
  'required-server-files.json',
  'server/app-paths-manifest.json',
];
const timeoutMs = Number(process.env.NEXT_BUILD_TIMEOUT_MS ?? 600_000);
const completionGraceMs = Number(process.env.NEXT_BUILD_COMPLETION_GRACE_MS ?? 2_000);

let completedOutput = false;
let settled = false;
let completionTimer;

const child = spawn(
  process.execPath,
  [path.join(root, 'node_modules', 'next', 'dist', 'bin', 'next'), 'build', 'apps/web'],
  {
    cwd: root,
    env: { ...process.env, NEXT_TELEMETRY_DISABLED: '1' },
    stdio: ['inherit', 'pipe', 'pipe'],
    detached: process.platform !== 'win32',
  },
);

function forward(stream, target) {
  let buffered = '';
  stream.on('data', (chunk) => {
    target.write(chunk);
    buffered += chunk.toString();
    if (buffered.length > 16_384) buffered = buffered.slice(-16_384);
    if (/server-rendered on demand/.test(buffered)) {
      completedOutput = true;
      scheduleArtifactVerification();
    }
  });
}

forward(child.stdout, process.stdout);
forward(child.stderr, process.stderr);

function terminateProcessGroup(signal) {
  try {
    if (process.platform === 'win32') child.kill(signal);
    else process.kill(-child.pid, signal);
  } catch {
    // The process may already have exited normally.
  }
}

async function artifactsAreComplete() {
  await Promise.all(requiredArtifacts.map((file) => access(path.join(distDir, file))));
}

function scheduleArtifactVerification() {
  clearTimeout(completionTimer);
  completionTimer = setTimeout(async () => {
    if (settled || !completedOutput) return;
    try {
      await artifactsAreComplete();
      settled = true;
      terminateProcessGroup('SIGTERM');
      setTimeout(() => terminateProcessGroup('SIGKILL'), 3_000).unref();
      console.log('\nProduction build completed and required Next.js artifacts were verified.');
      process.exitCode = 0;
    } catch (error) {
      console.error('\nNext.js printed a completion report, but required artifacts are missing:', error);
      settled = true;
      terminateProcessGroup('SIGKILL');
      process.exitCode = 1;
    }
  }, completionGraceMs);
}

const hardTimeout = setTimeout(() => {
  if (settled) return;
  settled = true;
  console.error(`\nNext.js build exceeded ${timeoutMs}ms before verified completion.`);
  terminateProcessGroup('SIGKILL');
  process.exitCode = 1;
}, timeoutMs);
hardTimeout.unref();

child.on('error', (error) => {
  if (settled) return;
  settled = true;
  clearTimeout(completionTimer);
  console.error('Unable to start Next.js build:', error);
  process.exitCode = 1;
});

child.on('exit', async (code, signal) => {
  if (settled) return;
  clearTimeout(completionTimer);
  if (code === 0) {
    try {
      await artifactsAreComplete();
      settled = true;
      console.log('\nProduction build completed normally and required artifacts were verified.');
      process.exitCode = 0;
      return;
    } catch (error) {
      console.error('Next.js exited successfully, but required artifacts are missing:', error);
    }
  }
  settled = true;
  console.error(`Next.js build failed (code=${code ?? 'null'}, signal=${signal ?? 'none'}).`);
  process.exitCode = code || 1;
});
