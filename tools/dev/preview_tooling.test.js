'use strict';

// Run with: node --test tools/dev/

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  PREVIEW_EMAIL,
  PreviewBootstrapError,
  resolveAuthEmulatorHost,
  ensurePreviewUser,
} = require('./ensure_preview_user');

const {
  EXPECTED_COURSES,
  EXPECTED_MODULES,
  DatasetVerificationError,
  resolveFirestoreEmulatorHost,
  assertCanonicalDataset,
} = require('./verify_preview_dataset');

// ─── Fail-closed emulator targeting ─────────────────────────────────────────

test('preview user bootstrap refuses to run without the Auth emulator', () => {
  assert.throws(
    () => resolveAuthEmulatorHost({}),
    (error) =>
      error instanceof PreviewBootstrapError &&
      /FIREBASE_AUTH_EMULATOR_HOST is not set/.test(error.message)
  );
});

test('preview user bootstrap refuses a non-loopback Auth host', () => {
  assert.throws(
    () =>
      resolveAuthEmulatorHost({
        FIREBASE_AUTH_EMULATOR_HOST: 'identitytoolkit.googleapis.com:443',
      }),
    (error) =>
      error instanceof PreviewBootstrapError &&
      /non-loopback/.test(error.message)
  );
});

test('preview user bootstrap accepts the local Auth emulator', () => {
  assert.equal(
    resolveAuthEmulatorHost({ FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099' }),
    '127.0.0.1:9099'
  );
});

test('dataset verification refuses a non-loopback Firestore host', () => {
  assert.throws(
    () =>
      resolveFirestoreEmulatorHost({
        FIRESTORE_EMULATOR_HOST: 'firestore.googleapis.com:443',
      }),
    (error) => error instanceof DatasetVerificationError
  );
});

// ─── Idempotent preview user creation ───────────────────────────────────────

/** Minimal in-memory stand-in for the Auth emulator REST surface. */
function installFakeAuthEmulator() {
  const accounts = new Map();
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (url, init) => {
    const body = JSON.parse(init.body);
    const json = (payload, ok = true) => ({
      ok,
      json: async () => payload,
    });

    if (url.includes('accounts:signUp')) {
      if (accounts.has(body.email)) {
        return json({ error: { message: 'EMAIL_EXISTS' } }, false);
      }
      accounts.set(body.email, {
        localId: `uid-${accounts.size + 1}`,
        password: body.password,
      });
      return json({ localId: accounts.get(body.email).localId });
    }

    if (url.includes('accounts:lookup')) {
      const email = body.email[0];
      const account = accounts.get(email);
      return account ? json({ users: [account] }) : json({ users: [] });
    }

    if (url.includes('accounts:update')) {
      for (const account of accounts.values()) {
        if (account.localId === body.localId) account.password = body.password;
      }
      return json({ localId: body.localId });
    }

    if (url.includes('accounts:signInWithPassword')) {
      const account = accounts.get(body.email);
      if (!account || account.password !== body.password) {
        return json({ error: { message: 'INVALID_LOGIN_CREDENTIALS' } }, false);
      }
      return json({ localId: account.localId, idToken: 'redacted' });
    }

    throw new Error(`Unexpected emulator call: ${url}`);
  };

  return {
    accounts,
    restore: () => {
      globalThis.fetch = originalFetch;
    },
  };
}

test('preview user creation is idempotent', async (t) => {
  const emulator = installFakeAuthEmulator();
  t.after(emulator.restore);

  const first = await ensurePreviewUser('127.0.0.1:9099');
  assert.equal(first.created, true);

  const second = await ensurePreviewUser('127.0.0.1:9099');
  assert.equal(second.created, false);
  assert.equal(second.uid, first.uid);
  assert.equal(emulator.accounts.size, 1);
});

test('a preview account with a drifted password is repaired, not duplicated',
  async (t) => {
    const emulator = installFakeAuthEmulator();
    t.after(emulator.restore);

    const first = await ensurePreviewUser('127.0.0.1:9099');
    emulator.accounts.get(PREVIEW_EMAIL).password = 'drifted';

    const repaired = await ensurePreviewUser('127.0.0.1:9099');
    assert.equal(repaired.uid, first.uid);
    assert.equal(emulator.accounts.size, 1);
  });

// ─── Canonical dataset assertion ────────────────────────────────────────────

function summary(overrides = {}) {
  return {
    courses: EXPECTED_COURSES,
    modules: EXPECTED_MODULES,
    byCourse: {
      'course-foundations_practice': 5,
      'course-quran_reading': 5,
      'course-prophet_seerah_sunnah': 5,
      'course-daily_life_france': 6,
      'course-character_ethics': 6,
      'course-spirituality_heart': 6,
    },
    ...overrides,
  };
}

test('canonical dataset of 6 courses / 33 modules is accepted', () => {
  assert.doesNotThrow(() => assertCanonicalDataset(summary()));
});

test('a partially seeded emulator is rejected', () => {
  assert.throws(
    () => assertCanonicalDataset(summary({ courses: 5, modules: 28 })),
    (error) => error instanceof DatasetVerificationError
  );
});

test('a course seeded without modules is rejected', () => {
  const broken = summary({ modules: EXPECTED_MODULES - 5 });
  broken.byCourse['course-foundations_practice'] = 0;

  assert.throws(
    () => assertCanonicalDataset(broken),
    (error) =>
      error instanceof DatasetVerificationError &&
      /course-foundations_practice/.test(error.message)
  );
});
