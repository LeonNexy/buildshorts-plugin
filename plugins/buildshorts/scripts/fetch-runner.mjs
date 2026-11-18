#!/usr/bin/env node
// First install of the runner (later updates: `buildshorts update`, same checks). Downloads the manifest and the bundle
// from buildshorts.com with the user's token, verifies the Ed25519 signature (public key below) and the SHA-256, unpacks
// into ~/BuildShorts/versions/<v> and points ~/BuildShorts/current at it. The token is read from BUILDSHORTS_TOKEN, the
// macOS Keychain / keys file, or the BuildShorts connector in ~/.claude.json; it only goes to buildshorts.com.
import { createHash, createPublicKey, verify } from 'node:crypto';
import { createWriteStream, existsSync, readFileSync } from 'node:fs';
import { mkdir, rename, rm, symlink, unlink } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import os from 'node:os';
import path from 'node:path';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';

const PUBLIC_KEY = `-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEA97C3mzg/yJEYj0Znj9oRnnYMsWG6HBn4/MLCQnuSaME=
-----END PUBLIC KEY-----
`;
const SIGNED_FIELDS = ['name', 'version', 'file', 'sha256', 'size', 'hyperframes', 'minNode', 'blocks', 'publishedAt'];
const BS = process.env.BUILDSHORTS_HOME || path.join(os.homedir(), 'BuildShorts');
const SERVER = (process.env.BUILDSHORTS_SERVER || 'https://buildshorts.com').replace(/\/+$/, '');

function token() {
  if (process.env.BUILDSHORTS_TOKEN) return process.env.BUILDSHORTS_TOKEN;
  if (process.platform === 'darwin') {
    try { const t = execFileSync('security', ['find-generic-password', '-s', 'buildshorts', '-a', 'token', '-w'], { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim(); if (t) return t; } catch { /* none */ }
  }
  try { const m = readFileSync(path.join(os.homedir(), '.config/buildshorts/keys.env'), 'utf8').match(/^token=(.+)$/m); if (m) return m[1].trim(); } catch { /* none */ }
  try { const m = readFileSync(path.join(os.homedir(), '.claude.json'), 'utf8').match(/\/api\/mcp\/c\/(bs_[\w-]{20,})|Bearer (bs_[\w-]{20,})/); if (m) return m[1] ?? m[2]; } catch { /* none */ }
  return null;
}

const t = token();
if (!t) { console.error('No BuildShorts token found. Add the connector first (claude mcp add … /api/mcp/c/<token>).'); process.exit(1); }
const auth = { authorization: `Bearer ${t}` };

const mr = await fetch(`${SERVER}/api/kit/manifest`, { headers: auth });
if (!mr.ok) { console.error(`Kit manifest: HTTP ${mr.status}${mr.status === 401 ? ' (token not accepted)' : ''}`); process.exit(1); }
const m = await mr.json();
const key = createPublicKey(process.env.BUILDSHORTS_RELEASE_PUBKEY_FILE ? readFileSync(process.env.BUILDSHORTS_RELEASE_PUBKEY_FILE, 'utf8') : PUBLIC_KEY);
const msg = Buffer.from(JSON.stringify(SIGNED_FIELDS.map((k) => [k, m[k] ?? null])));
if (m.name !== 'buildshorts-runner' || !m.signature || !verify(null, msg, key, Buffer.from(m.signature, 'base64'))) { console.error('Kit manifest signature is NOT valid: install refused.'); process.exit(1); }

const dr = await fetch(`${SERVER}/api/kit/download?v=${encodeURIComponent(m.version)}`, { headers: auth, redirect: 'manual' });
const loc = dr.headers.get('location');
const res = loc ? await fetch(new URL(loc, SERVER)) : dr; // the storage link gets no token
if (!res.ok || !res.body) { console.error(`Kit download: HTTP ${res.status}`); process.exit(1); }
await mkdir(path.join(BS, 'downloads'), { recursive: true });
const tgz = path.join(BS, 'downloads', path.basename(m.file));
await pipeline(Readable.fromWeb(res.body), createWriteStream(tgz));
const sum = createHash('sha256').update(readFileSync(tgz)).digest('hex');
if (sum !== m.sha256) { await rm(tgz, { force: true }); console.error('Kit bundle checksum mismatch: install refused.'); process.exit(1); }

const dest = path.join(BS, 'versions', m.version);
await rm(`${dest}.tmp`, { recursive: true, force: true });
await mkdir(`${dest}.tmp`, { recursive: true });
execFileSync('tar', ['-xzf', tgz, '-C', `${dest}.tmp`]);
await rm(dest, { recursive: true, force: true });
await rename(`${dest}.tmp`, dest);
await rm(tgz, { force: true });
const cur = path.join(BS, 'current');
await unlink(`${cur}.new`).catch(() => {});
await symlink(dest, `${cur}.new`, 'dir');
await rename(`${cur}.new`, cur);
console.log(`✓ runner ${m.version} verified and installed (${existsSync(path.join(dest, 'buildshorts.mjs')) ? 'ok' : 'missing entry!'})`);
