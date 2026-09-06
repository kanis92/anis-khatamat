/**
 * Prove default-deny after removing explicit match /{document=**}.
 */
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
} = require('@firebase/rules-unit-testing');

const RULES = fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8');

function has1000(err) {
  return String(err && err.message ? err.message : err).includes(
    'maximum 1000 expressions',
  );
}

async function main() {
  const testEnv = await initializeTestEnvironment({
    projectId: 'anis-default-deny',
    firestore: { rules: RULES },
  });

  let failed = 0;
  const test = async (name, fn) => {
    process.stdout.write(`  ${name} ... `);
    try {
      await fn();
      console.log('PASS');
    } catch (e) {
      failed++;
      console.log('FAIL');
      console.error(e.message);
    }
  };

  const user = testEnv.authenticatedContext('u', { email: 'user@test.com' }).firestore();

  await test('unknown top-level collection write denied', async () => {
    try {
      await user.collection('not_a_real_collection').doc('x').set({ a: 1 });
      throw new Error('WRITE_SUCCEEDED');
    } catch (e) {
      if (String(e.message).includes('WRITE_SUCCEEDED')) throw e;
      if (has1000(e)) throw new Error('DENIED_WITH_1000');
    }
  });

  await test('unknown nested write under khatmat denied', async () => {
    try {
      await user.collection('khatmat').doc('k1').collection('secrets').doc('x').set({ a: 1 });
      throw new Error('WRITE_SUCCEEDED');
    } catch (e) {
      if (String(e.message).includes('WRITE_SUCCEEDED')) throw e;
      if (has1000(e)) throw new Error('DENIED_WITH_1000');
    }
  });

  await test('unknown nested write under users denied', async () => {
    try {
      await user.collection('users').doc('u').collection('vault').doc('x').set({ a: 1 });
      throw new Error('WRITE_SUCCEEDED');
    } catch (e) {
      if (String(e.message).includes('WRITE_SUCCEEDED')) throw e;
      if (has1000(e)) throw new Error('DENIED_WITH_1000');
    }
  });

  await test('unauthenticated unknown path write denied', async () => {
    const anon = testEnv.unauthenticatedContext().firestore();
    await assertFails(anon.collection('ghost').doc('x').set({ a: 1 }));
  });

  await testEnv.cleanup();
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
