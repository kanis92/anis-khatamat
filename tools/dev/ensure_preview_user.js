#!/usr/bin/env node
'use strict';

// ═══════════════════════════════════════════════════════════════════════════
// ANIS — Idempotent preview user bootstrap (AUTH EMULATOR ONLY)
// ═══════════════════════════════════════════════════════════════════════════
//
// Guarantees that `preview@anis.local` can sign in against the local Auth
// emulator, whatever the emulator did with its user store since last run.
//
// SAFETY
// - Refuses to run unless FIREBASE_AUTH_EMULATOR_HOST points at a loopback host.
// - Uses only the emulator's local identitytoolkit endpoints.
// - Never prints ID tokens or refresh tokens.
// - Impossible to reach production Firebase Auth: no service account, no
//   googleapis.com endpoint, no real API key.
//
// Usage:
//   FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 node tools/dev/ensure_preview_user.js
// ═══════════════════════════════════════════════════════════════════════════

const PREVIEW_EMAIL = process.env.ANIS_PREVIEW_EMAIL || 'preview@anis.local';
const PREVIEW_PASSWORD =
  process.env.ANIS_PREVIEW_PASSWORD || 'preview-anis-local';
const PREVIEW_DISPLAY_NAME = 'ANIS Preview';
const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'anis-437c3';

// The Auth emulator accepts any API key; this value never reaches Google.
const EMULATOR_API_KEY = 'anis-emulator-key';

const LOOPBACK_HOSTS = new Set(['127.0.0.1', 'localhost', '::1', '[::1]']);

class PreviewBootstrapError extends Error {}

/** Fail-closed validation of the emulator target. */
function resolveAuthEmulatorHost(env = process.env) {
  const host = env.FIREBASE_AUTH_EMULATOR_HOST;
  if (!host) {
    throw new PreviewBootstrapError(
      'FIREBASE_AUTH_EMULATOR_HOST is not set. This script is emulator-only ' +
        'and refuses to run against production Firebase Auth.'
    );
  }

  const separator = host.lastIndexOf(':');
  if (separator <= 0) {
    throw new PreviewBootstrapError(
      `FIREBASE_AUTH_EMULATOR_HOST must be "host:port" (received "${host}").`
    );
  }

  const hostname = host.slice(0, separator);
  const port = Number.parseInt(host.slice(separator + 1), 10);

  if (!LOOPBACK_HOSTS.has(hostname)) {
    throw new PreviewBootstrapError(
      `Refusing to bootstrap the preview user against non-loopback host ` +
        `"${hostname}". Only the local Auth emulator is allowed.`
    );
  }
  if (!Number.isInteger(port) || port <= 0) {
    throw new PreviewBootstrapError(
      `Invalid Auth emulator port in "${host}".`
    );
  }

  return `${hostname}:${port}`;
}

async function callEmulator(host, path, body, { asOwner = false } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (asOwner) headers.Authorization = 'Bearer owner';

  const response = await fetch(`http://${host}${path}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });

  const payload = await response.json().catch(() => ({}));
  return { ok: response.ok, status: response.status, payload };
}

function emulatorErrorCode(payload) {
  return payload && payload.error && payload.error.message
    ? payload.error.message
    : 'UNKNOWN_ERROR';
}

async function createUser(host) {
  return callEmulator(
    host,
    `/identitytoolkit.googleapis.com/v1/accounts:signUp?key=${EMULATOR_API_KEY}`,
    {
      email: PREVIEW_EMAIL,
      password: PREVIEW_PASSWORD,
      displayName: PREVIEW_DISPLAY_NAME,
      returnSecureToken: true,
    }
  );
}

async function lookupUser(host) {
  return callEmulator(
    host,
    `/identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts:lookup`,
    { email: [PREVIEW_EMAIL] },
    { asOwner: true }
  );
}

async function resetPassword(host, localId) {
  return callEmulator(
    host,
    `/identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts:update`,
    {
      localId,
      password: PREVIEW_PASSWORD,
      displayName: PREVIEW_DISPLAY_NAME,
      emailVerified: true,
    },
    { asOwner: true }
  );
}

async function verifySignIn(host) {
  return callEmulator(
    host,
    '/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword' +
      `?key=${EMULATOR_API_KEY}`,
    {
      email: PREVIEW_EMAIL,
      password: PREVIEW_PASSWORD,
      returnSecureToken: true,
    }
  );
}

/**
 * Ensures the preview account exists and can authenticate.
 * Returns `{ uid, created }`; never returns credentials.
 */
async function ensurePreviewUser(host) {
  const created = await createUser(host);
  let wasCreated = created.ok;

  if (!created.ok && emulatorErrorCode(created.payload) !== 'EMAIL_EXISTS') {
    throw new PreviewBootstrapError(
      `Auth emulator rejected preview user creation: ` +
        `${emulatorErrorCode(created.payload)}`
    );
  }

  if (!wasCreated) {
    // The account survived a previous run: normalise its password so that a
    // stale or manually-created account can still sign in deterministically.
    const lookup = await lookupUser(host);
    const existing =
      lookup.ok && Array.isArray(lookup.payload.users)
        ? lookup.payload.users[0]
        : null;

    if (!existing) {
      throw new PreviewBootstrapError(
        'Auth emulator reported EMAIL_EXISTS but the account could not be ' +
          'looked up. The emulator state is inconsistent.'
      );
    }

    const updated = await resetPassword(host, existing.localId);
    if (!updated.ok) {
      throw new PreviewBootstrapError(
        `Could not normalise the existing preview account: ` +
          `${emulatorErrorCode(updated.payload)}`
      );
    }
  }

  const signIn = await verifySignIn(host);
  if (!signIn.ok) {
    throw new PreviewBootstrapError(
      `Preview user cannot sign in after bootstrap: ` +
        `${emulatorErrorCode(signIn.payload)}`
    );
  }

  return { uid: signIn.payload.localId, created: wasCreated };
}

async function main() {
  const host = resolveAuthEmulatorHost();
  console.log(`🔒 Auth emulator: ${host} (project ${PROJECT_ID})`);

  const { uid, created } = await ensurePreviewUser(host);

  console.log(
    `✅ Preview user ${created ? 'created' : 'already present'}: ` +
      `${PREVIEW_EMAIL} (uid ${uid})`
  );
}

module.exports = {
  PREVIEW_EMAIL,
  PreviewBootstrapError,
  resolveAuthEmulatorHost,
  ensurePreviewUser,
};

if (require.main === module) {
  main().catch((error) => {
    console.error(`❌ ${error.message}`);
    process.exit(1);
  });
}
