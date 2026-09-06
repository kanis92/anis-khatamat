/**
 * Isolated business DENY proof.
 * One emulator, clearFirestore + rules-disabled seed, then one forbidden write.
 */
const fs = require('fs');
const path = require('path');

const _rpcChunks = [];
const _origErr = process.stderr.write.bind(process.stderr);
const _origOut = process.stdout.write.bind(process.stdout);
process.stderr.write = (chunk, ...rest) => {
  _rpcChunks.push(String(chunk));
  return _origErr(chunk, ...rest);
};
process.stdout.write = (chunk, ...rest) => {
  _rpcChunks.push(String(chunk));
  return _origOut(chunk, ...rest);
};

const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');

const DEBUG_LOG = path.join(__dirname, 'firestore-debug.log');

const RULES = fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8');
const CANONICAL = 'quran_foundation_hafs_v1';

function snap(n) {
  return {
    hizbNumber: n,
    hizbDefinitionId: CANONICAL,
    startVerseKey: '1:1',
    endVerseKey: '2:74',
    startPageHafs: 1,
    endPageHafs: 11,
  };
}

function parentReady() {
  return {
    title: 'DenyProof',
    createdBy: 'creator@test.com',
    createdAt: new Date().toISOString(),
    isGroup: true,
    isPublic: false,
    reservationMode: true,
    reservationSchemaVersion: 2,
    hizbDefinitionId: CANONICAL,
    participantIds: ['creator@test.com', 'member@test.com'],
    members: ['member@test.com'],
    guestParticipants: {},
    completedHizbCount: 0,
    creationState: 'ready',
  };
}

function debugSince(offset) {
  try {
    const raw = fs.readFileSync(DEBUG_LOG, 'utf8');
    return raw.slice(offset);
  } catch (_) {
    return '';
  }
}

function debugSize() {
  try {
    return fs.statSync(DEBUG_LOG).size;
  } catch (_) {
    return 0;
  }
}

function denyText(result) {
  return `${result.message || ''}\n${result.log || ''}`;
}

function has1000(result) {
  return denyText(result).includes('maximum 1000 expressions');
}

function isCleanBusinessDeny(result) {
  const text = denyText(result);
  if (!result.denied) return false;
  if (text.includes('maximum 1000 expressions')) return false;
  if (text.includes('evaluation error')) return false;
  return true;
}

function db(testEnv, uid, email) {
  return testEnv.authenticatedContext(uid, { email }).firestore();
}

async function seed(testEnv, khatmaId, hizbNumber, hizbDoc) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const admin = ctx.firestore();
    await admin.collection('khatmat').doc(khatmaId).set(parentReady());
    await admin
      .collection('khatmat')
      .doc(khatmaId)
      .collection('hizb_reservations')
      .doc(String(hizbNumber))
      .set(hizbDoc);
  });
}

function installLogCapture() {
  const chunks = [];
  const origErr = process.stderr.write.bind(process.stderr);
  const origOut = process.stdout.write.bind(process.stdout);
  process.stderr.write = (chunk, ...rest) => {
    chunks.push(String(chunk));
    return origErr(chunk, ...rest);
  };
  process.stdout.write = (chunk, ...rest) => {
    chunks.push(String(chunk));
    return origOut(chunk, ...rest);
  };
  const wrap = (fn) =>
    (...args) => {
      chunks.push(args.map((a) => String(a)).join(' '));
      fn.apply(console, args);
    };
  const originals = {
    warn: console.warn,
    error: console.error,
    info: console.info,
    debug: console.debug,
  };
  console.warn = wrap(console.warn);
  console.error = wrap(console.error);
  console.info = wrap(console.info);
  console.debug = wrap(console.debug);
  return {
    text: () => chunks.join('\n'),
    restore: () => {
      process.stderr.write = origErr;
      process.stdout.write = origOut;
      console.warn = originals.warn;
      console.error = originals.error;
      console.info = originals.info;
      console.debug = originals.debug;
    },
  };
}

async function captureDeny(promise) {
  const logs = installLogCapture();
  try {
    await promise;
    logs.restore();
    return { denied: false, message: 'WRITE_SUCCEEDED', log: logs.text() };
  } catch (e) {
    const raw = [
      e && e.message,
      e && e.code,
      e && e.details,
      e && e.customData && JSON.stringify(e.customData),
      String(e),
      logs.text(),
    ]
      .filter(Boolean)
      .join(' | ');
    logs.restore();
    return { denied: true, message: raw, log: logs.text() };
  }
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: 'anis-deny-isolated',
    firestore: { rules: RULES },
  });

  const cases = [
    {
      name: 'offline forged UID',
      run: async () => {
        const member = db(testEnv, 'm', 'member@test.com');
        return captureDeny(
          member.collection('khatmat').doc('k-off').collection('hizb_reservations').doc('3').set({
            status: 'reserved',
            reservedBy: 'member@test.com',
            assigneeKind: 'offline',
            assigneeUserId: 'fake-uid-123',
            assigneeDisplayName: 'Fatima',
            ...snap(3),
          }),
        );
      },
      seed: async () => seed(testEnv, 'k-off', 3, { status: 'available', ...snap(3) }),
    },
    {
      name: 'member assigns another participant',
      run: async () => {
        const member = db(testEnv, 'm', 'member@test.com');
        return captureDeny(
          member.collection('khatmat').doc('k-part').collection('hizb_reservations').doc('1').set({
            status: 'reserved',
            reservedBy: 'victim@test.com',
            assigneeKind: 'participant',
            assigneeUserId: 'victim@test.com',
            assignedByUserId: 'member@test.com',
            ...snap(1),
          }),
        );
      },
      seed: async () => seed(testEnv, 'k-part', 1, { status: 'available', ...snap(1) }),
    },
    {
      name: 'forged assignedByUserId',
      run: async () => {
        const member = db(testEnv, 'm', 'member@test.com');
        return captureDeny(
          member.collection('khatmat').doc('k-aby').collection('hizb_reservations').doc('2').set({
            status: 'reserved',
            reservedBy: 'member@test.com',
            assigneeKind: 'self',
            assigneeUserId: 'member@test.com',
            assignedByUserId: 'creator@test.com',
            ...snap(2),
          }),
        );
      },
      seed: async () => seed(testEnv, 'k-aby', 2, { status: 'available', ...snap(2) }),
    },
    {
      name: 'mutate another user reservation',
      run: async () => {
        const member = db(testEnv, 'm', 'member@test.com');
        return captureDeny(
          member.collection('khatmat').doc('k-mut').collection('hizb_reservations').doc('10').update({
            status: 'inProgress',
          }),
        );
      },
      seed: async () =>
        seed(testEnv, 'k-mut', 10, {
          status: 'reserved',
          reservedBy: 'creator@test.com',
          assigneeKind: 'self',
          assigneeUserId: 'creator@test.com',
          ...snap(10),
        }),
    },
    {
      name: 'mutate canonical snapshot',
      run: async () => {
        const member = db(testEnv, 'm', 'member@test.com');
        return captureDeny(
          member.collection('khatmat').doc('k-snap').collection('hizb_reservations').doc('5').update({
            startVerseKey: '99:1',
          }),
        );
      },
      seed: async () => seed(testEnv, 'k-snap', 5, { status: 'available', ...snap(5) }),
    },
    {
      name: 'delete canonical reservation',
      run: async () => {
        const member = db(testEnv, 'm', 'member@test.com');
        return captureDeny(
          member.collection('khatmat').doc('k-del').collection('hizb_reservations').doc('6').delete(),
        );
      },
      seed: async () => seed(testEnv, 'k-del', 6, { status: 'available', ...snap(6) }),
    },
    {
      name: 'unknown collection write',
      run: async () => {
        const member = db(testEnv, 'm', 'member@test.com');
        return captureDeny(member.collection('unknown_root').doc('x').set({ a: 1 }));
      },
      seed: async () => {},
    },
    {
      name: 'unknown nested write',
      run: async () => {
        const member = db(testEnv, 'm', 'member@test.com');
        return captureDeny(
          member.collection('khatmat').doc('k-off').collection('not_reservations').doc('x').set({ a: 1 }),
        );
      },
      seed: async () => seed(testEnv, 'k-off', 3, { status: 'available', ...snap(3) }),
    },
  ];

  const results = [];
  for (const c of cases) {
    await testEnv.clearFirestore();
    await c.seed();
    _rpcChunks.length = 0;
    const logOffset = debugSize();
    const result = await c.run();
    result.log = `${result.log || ''}\n${_rpcChunks.join('')}\n${debugSince(logOffset)}`;
    result.message = `${result.message || ''}\n${_rpcChunks.join('')}\n${debugSince(logOffset)}`;
    const overflow = has1000(result);
    const clean = isCleanBusinessDeny(result) && !overflow;
    const status = clean
      ? 'PASS-BUSINESS'
      : overflow
        ? 'DENY-WITH-1000'
        : result.denied
          ? 'DENY-UNCLEAN'
          : 'ALLOW-UNEXPECTED';
    console.log(`  ${c.name} ... ${status}`);
    if (!clean) {
      console.log(`    message: ${result.message.split('\n').join(' | ')}`);
    }
    results.push({ name: c.name, ...result, clean, has1000: has1000(result) });
  }

  await testEnv.cleanup();
  const dirty = results.filter((r) => !r.clean);
  console.log('');
  console.log(`isolated DENY: ${results.length - dirty.length}/${results.length} clean business`);
  process.exit(dirty.length === 0 ? 0 : 2);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
