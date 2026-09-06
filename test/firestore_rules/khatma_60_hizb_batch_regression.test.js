/**
 * FORENSIC INVESTIGATION: Firestore Rules Budget
 * 
 * Isolate and prove root cause of alleged 1000-expression limit exhaustion.
 * Each test runs from CLEAN emulator state with fresh context.
 * 
 * Run: cd test/firestore_rules && firebase emulators:exec --only firestore,auth 'node forensic_rules_budget_investigation.test.js'
 */

const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'anis-forensic-rules-budget';
const rulesPath = path.resolve(__dirname, '../../firestore.rules');
const CANONICAL = 'quran_foundation_hafs_v1';

// ─── Helpers ─────────────────────────────────────────────────────────

function canonicalHizb(n) {
  const startSurah = Math.min(1 + Math.floor((n - 1) / 5), 114);
  const endSurah = Math.min(1 + Math.floor(n / 5), 114);
  const startAyah = 1 + ((n - 1) % 10);
  const endAyah = 1 + (n % 10);
  const startPage = Math.min(1 + (n - 1) * 10, 594);
  const endPage = Math.min(10 + (n - 1) * 10, 604);

  return {
    hizbNumber: n,
    status: 'available',
    hizbDefinitionId: CANONICAL,
    startVerseKey: `${startSurah}:${startAyah}`,
    endVerseKey: `${endSurah}:${endAyah}`,
    startPageHafs: startPage,
    endPageHafs: endPage,
  };
}

function parentDoc(email, state = 'initializing') {
  return {
    title: 'Forensic Test',
    createdBy: email,
    createdAt: new Date().toISOString(),
    isGroup: true,
    isPublic: false,
    reservationMode: true,
    reservationSchemaVersion: 2,
    hizbDefinitionId: CANONICAL,
    participantIds: [email],
    members: [],
    guestParticipants: {},
    completedHizbCount: 0,
    creationState: state,
  };
}

// ─── Test Infrastructure ─────────────────────────────────────────────

let testEnv;
const results = {
  isolation: {},
  sizes: {},
  operations: {},
  singleChild: {},
  sequential: {},
  rootCause: null,
};

async function setupClean() {
  if (testEnv) {
    await testEnv.cleanup();
  }
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: fs.readFileSync(rulesPath, 'utf8') },
  });
  await testEnv.clearFirestore();
}

function authedDb(uid, email) {
  return testEnv.authenticatedContext(uid, email ? { email } : {}).firestore();
}

async function runTest(name, fn) {
  process.stdout.write(`  ${name} ... `);
  try {
    const result = await fn();
    console.log('✓ PASS');
    return { success: true, error: null, result };
  } catch (e) {
    console.log('✗ FAIL');
    return { success: false, error: e, result: null };
  }
}

// ─── SECTION 1: TEST ISOLATION VERIFICATION ─────────────────────────

async function section1_testIsolation() {
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('SECTION 1: Test Isolation Verification');
  console.log('═══════════════════════════════════════════════════════\n');

  const sizes = [5, 10, 15, 20, 30];
  const iterations = 3;

  for (const size of sizes) {
    console.log(`\nTesting batch size ${size} (${iterations} iterations from clean state):`);
    
    const iterationResults = [];
    
    for (let i = 1; i <= iterations; i++) {
      await setupClean();
      
      const result = await runTest(`  Iteration ${i}`, async () => {
        const email = `creator-${size}-${i}@test.com`;
        const uid = `uid-${size}-${i}`;
        const db = authedDb(uid, email);
        
        // Create parent
        const parentRef = await db.collection('khatmat').add(parentDoc(email));
        const khatmaId = parentRef.id;
        
        // Create batch
        const batch = db.batch();
        const hizbCol = db.collection('khatmat').doc(khatmaId).collection('hizb_reservations');
        
        for (let n = 1; n <= size; n++) {
          batch.set(hizbCol.doc(String(n)), canonicalHizb(n));
        }
        
        await batch.commit();
        
        // Verify
        const snapshot = await hizbCol.get();
        if (snapshot.size !== size) {
          throw new Error(`Expected ${size} docs, got ${snapshot.size}`);
        }
        
        return { docsCreated: snapshot.size };
      });
      
      iterationResults.push(result);
    }
    
    const allPassed = iterationResults.every(r => r.success);
    const allFailed = iterationResults.every(r => !r.success);
    const inconsistent = !allPassed && !allFailed;
    
    results.isolation[`size_${size}`] = {
      iterations: iterationResults,
      deterministic: !inconsistent,
      allPassed,
      allFailed,
    };
    
    console.log(`  Result: ${allPassed ? '✓ ALL PASS' : allFailed ? '✗ ALL FAIL' : '⚠ INCONSISTENT'}`);
    
    if (!allPassed && iterationResults[0].error) {
      const errorMsg = iterationResults[0].error.message || '';
      const has1000Limit = errorMsg.includes('maximum 1000 expressions');
      console.log(`  Error type: ${has1000Limit ? '1000-EXPRESSION LIMIT' : 'OTHER'}`);
    }
  }
}

// ─── SECTION 2: SIZE MATRIX (CLEAN STATE PER TEST) ──────────────────

async function section2_sizeMatrix() {
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('SECTION 2: Deterministic Size Matrix');
  console.log('═══════════════════════════════════════════════════════\n');

  const sizes = [1, 5, 10, 15, 20, 30, 60];
  
  for (const size of sizes) {
    await setupClean();
    
    const result = await runTest(`Batch size ${size}`, async () => {
      const email = 'creator@test.com';
      const uid = 'creator-uid';
      const db = authedDb(uid, email);
      
      const parentRef = await db.collection('khatmat').add(parentDoc(email));
      const khatmaId = parentRef.id;
      
      const batch = db.batch();
      const hizbCol = db.collection('khatmat').doc(khatmaId).collection('hizb_reservations');
      
      for (let n = 1; n <= size; n++) {
        batch.set(hizbCol.doc(String(n)), canonicalHizb(n));
      }
      
      await batch.commit();
      
      const snapshot = await hizbCol.get();
      return { docsCreated: snapshot.size };
    });
    
    results.sizes[`size_${size}`] = {
      success: result.success,
      docsCreated: result.result?.docsCreated || 0,
      error: result.error ? {
        code: result.error.code,
        message: result.error.message?.substring(0, 200),
        has1000Limit: (result.error.message || '').includes('maximum 1000 expressions'),
      } : null,
    };
  }
}

// ─── SECTION 3: PARENT READ OPERATIONS ──────────────────────────────

async function section3_parentReadOperations() {
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('SECTION 3: Parent Read Operations Analysis');
  console.log('═══════════════════════════════════════════════════════\n');

  await setupClean();
  
  const email = 'creator@test.com';
  const uid = 'creator-uid';
  const db = authedDb(uid, email);
  
  // Create parent
  const parentRef = await db.collection('khatmat').add(parentDoc(email));
  const khatmaId = parentRef.id;
  
  // Create 60 children in small batches to avoid batch failure
  console.log('  Creating 60 children in batches of 5...');
  const hizbCol = db.collection('khatmat').doc(khatmaId).collection('hizb_reservations');
  
  for (let start = 1; start <= 60; start += 5) {
    const batch = db.batch();
    const end = Math.min(start + 4, 60);
    
    for (let n = start; n <= end; n++) {
      batch.set(hizbCol.doc(String(n)), canonicalHizb(n));
    }
    
    try {
      await batch.commit();
      process.stdout.write('.');
    } catch (e) {
      console.log(`\n  ✗ Batch ${start}-${end} failed: ${e.message.substring(0, 100)}`);
      results.operations.childCreationFailed = {
        atBatch: `${start}-${end}`,
        error: e.message.substring(0, 200),
      };
      break;
    }
  }
  console.log('\n');
  
  const childSnapshot = await hizbCol.get();
  const childCount = childSnapshot.size;
  console.log(`  Children created: ${childCount}\n`);
  
  // Test A: Get single parent document
  const testA = await runTest('A. get(khatmat/{id})', async () => {
    await db.collection('khatmat').doc(khatmaId).get();
  });
  results.operations.parentGet = testA;
  
  // Test B: Query/list khatmat collection
  const testB = await runTest('B. query khatmat collection', async () => {
    await db.collection('khatmat').where('createdBy', '==', email).get();
  });
  results.operations.khatmatQuery = testB;
  
  // Test C: Query hizb_reservations subcollection
  const testC = await runTest('C. query hizb_reservations', async () => {
    await hizbCol.get();
  });
  results.operations.hizbQuery = testC;
  
  // Test D: Get one hizb reservation
  const testD = await runTest('D. get one hizb reservation', async () => {
    await hizbCol.doc('1').get();
  });
  results.operations.hizbGetOne = testD;
  
  // Test E: Read all children individually
  const testE = await runTest('E. read all children individually', async () => {
    for (let n = 1; n <= childCount; n++) {
      await hizbCol.doc(String(n)).get();
    }
  });
  results.operations.hizbGetAll = testE;
}

// ─── SECTION 4: SINGLE CHILD VALIDATION ─────────────────────────────

async function section4_singleChildValidation() {
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('SECTION 4: Single Child Business Validation');
  console.log('═══════════════════════════════════════════════════════\n');

  await setupClean();
  
  const email = 'creator@test.com';
  const uid = 'creator-uid';
  const db = authedDb(uid, email);
  
  const parentRef = await db.collection('khatmat').add(parentDoc(email));
  const khatmaId = parentRef.id;
  const hizbCol = db.collection('khatmat').doc(khatmaId).collection('hizb_reservations');
  
  // Test: ONE valid child
  const testValid = await runTest('ONE valid child create', async () => {
    await assertSucceeds(hizbCol.doc('1').set(canonicalHizb(1)));
  });
  results.singleChild.validCreate = testValid;
  
  if (!testValid.success && testValid.error) {
    const has1000 = (testValid.error.message || '').includes('maximum 1000 expressions');
    console.log(`    Error: ${has1000 ? '1000-EXPRESSION LIMIT ⚠️' : 'OTHER'}`);
  }
  
  // Test: ONE invalid child (hizbNumber mismatch)
  const testInvalid1 = await runTest('ONE invalid child (hizbNumber mismatch)', async () => {
    const invalidHizb = { ...canonicalHizb(2), hizbNumber: 999 };
    await assertFails(hizbCol.doc('2').set(invalidHizb));
  });
  results.singleChild.invalidHizbNumber = testInvalid1;
  
  if (!testInvalid1.success && testInvalid1.error) {
    const has1000 = (testInvalid1.error.message || '').includes('maximum 1000 expressions');
    console.log(`    Error: ${has1000 ? '1000-EXPRESSION LIMIT ⚠️' : 'BUSINESS DENIAL ✓'}`);
  }
  
  // Test: ONE invalid child (missing canonical snapshot)
  const testInvalid2 = await runTest('ONE invalid child (missing canonical fields)', async () => {
    const invalidHizb = {
      hizbNumber: 3,
      status: 'available',
      // Missing hizbDefinitionId, startVerseKey, etc.
    };
    await assertFails(hizbCol.doc('3').set(invalidHizb));
  });
  results.singleChild.invalidSnapshot = testInvalid2;
  
  // Test: ONE invalid child (wrong status)
  const testInvalid3 = await runTest('ONE invalid child (forbidden status)', async () => {
    const invalidHizb = { ...canonicalHizb(4), status: 'completed' };
    await assertFails(hizbCol.doc('4').set(invalidHizb));
  });
  results.singleChild.invalidStatus = testInvalid3;
}

// ─── SECTION 5: SEQUENTIAL BATCH REQUESTS ───────────────────────────

async function section5_sequentialBatches() {
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('SECTION 5: Sequential Independent Batch Requests');
  console.log('═══════════════════════════════════════════════════════\n');

  await setupClean();
  
  const email = 'creator@test.com';
  const uid = 'creator-uid';
  const db = authedDb(uid, email);
  
  const parentRef = await db.collection('khatmat').add(parentDoc(email));
  const khatmaId = parentRef.id;
  const hizbCol = db.collection('khatmat').doc(khatmaId).collection('hizb_reservations');
  
  const chunkSize = 5;
  const chunks = [];
  
  for (let start = 1; start <= 60; start += chunkSize) {
    const end = Math.min(start + chunkSize - 1, 60);
    
    const result = await runTest(`  Chunk ${start}-${end}`, async () => {
      const batch = db.batch();
      
      for (let n = start; n <= end; n++) {
        batch.set(hizbCol.doc(String(n)), canonicalHizb(n));
      }
      
      await batch.commit();
      
      const snapshot = await hizbCol.get();
      return { totalDocs: snapshot.size };
    });
    
    chunks.push({
      range: `${start}-${end}`,
      success: result.success,
      totalDocsAfter: result.result?.totalDocs || 0,
      error: result.error ? {
        message: result.error.message?.substring(0, 150),
        has1000Limit: (result.error.message || '').includes('maximum 1000 expressions'),
      } : null,
    });
    
    if (!result.success) {
      console.log(`    ⚠️ Failed at chunk ${start}-${end}`);
      console.log(`    Total docs before failure: ${start - 1}`);
      break;
    }
  }
  
  results.sequential.chunks = chunks;
  results.sequential.failedAt = chunks.find(c => !c.success)?.range || null;
}

// ─── SECTION 6: FRESH PARENT WITH PRE-EXISTING CHILDREN ─────────────

async function section6_freshParentComparison() {
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('SECTION 6: Fresh Parent vs Sequential Creation');
  console.log('═══════════════════════════════════════════════════════\n');

  // Test A: Sequential (0 → 5 → 10 → 15 → 20)
  await setupClean();
  const emailA = 'creator-a@test.com';
  const dbA = authedDb('uid-a', emailA);
  const parentRefA = await dbA.collection('khatmat').add(parentDoc(emailA));
  const khatmaIdA = parentRefA.id;
  const hizbColA = dbA.collection('khatmat').doc(khatmaIdA).collection('hizb_reservations');
  
  console.log('Test A: Sequential creation (5 + 5 + 5 + 5)');
  let sequentialSuccess = true;
  
  for (let start = 1; start <= 20; start += 5) {
    const batch = dbA.batch();
    for (let n = start; n <= start + 4; n++) {
      batch.set(hizbColA.doc(String(n)), canonicalHizb(n));
    }
    
    try {
      await batch.commit();
      process.stdout.write(` ✓${start}-${start+4}`);
    } catch (e) {
      process.stdout.write(` ✗${start}-${start+4}`);
      sequentialSuccess = false;
      break;
    }
  }
  console.log();
  
  // Test B: Fresh parent with 20 children at once
  await setupClean();
  const emailB = 'creator-b@test.com';
  const dbB = authedDb('uid-b', emailB);
  const parentRefB = await dbB.collection('khatmat').add(parentDoc(emailB));
  const khatmaIdB = parentRefB.id;
  const hizbColB = dbB.collection('khatmat').doc(khatmaIdB).collection('hizb_reservations');
  
  const testFresh = await runTest('Test B: Fresh parent, 20 children batch', async () => {
    const batch = dbB.batch();
    for (let n = 1; n <= 20; n++) {
      batch.set(hizbColB.doc(String(n)), canonicalHizb(n));
    }
    await batch.commit();
  });
  
  results.sequential.sequentialVsFresh = {
    sequential: sequentialSuccess,
    freshBatch: testFresh.success,
    different: sequentialSuccess !== testFresh.success,
  };
}

// ─── MAIN ────────────────────────────────────────────────────────────

async function main() {
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('FORENSIC INVESTIGATION: Firestore Rules Budget');
  console.log('═══════════════════════════════════════════════════════');
  
  await section1_testIsolation();
  await section2_sizeMatrix();
  await section3_parentReadOperations();
  await section4_singleChildValidation();
  await section5_sequentialBatches();
  await section6_freshParentComparison();
  
  // ─── FINAL REPORT ──────────────────────────────────────────────────
  
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('FORENSIC REPORT — Root Cause Analysis');
  console.log('═══════════════════════════════════════════════════════\n');
  
  console.log('─── 1. Test Isolation ───');
  const isolationKeys = Object.keys(results.isolation);
  const allDeterministic = isolationKeys.every(k => results.isolation[k].deterministic);
  console.log(`  All sizes deterministic: ${allDeterministic ? '✓ YES' : '✗ NO'}`);
  
  if (!allDeterministic) {
    console.log('  ⚠️ INCONSISTENT RESULTS DETECTED');
    isolationKeys.forEach(k => {
      const r = results.isolation[k];
      if (!r.deterministic) {
        console.log(`    ${k}: Some iterations passed, some failed`);
      }
    });
  }
  console.log();
  
  console.log('─── 2. Size Matrix ───');
  [1, 5, 10, 15, 20, 30, 60].forEach(size => {
    const r = results.sizes[`size_${size}`];
    if (r) {
      const status = r.success ? '✓ PASS' : '✗ FAIL';
      const limit = r.error?.has1000Limit ? ' (1000-expr limit)' : '';
      console.log(`  Size ${String(size).padStart(2)}: ${status}${limit}`);
    }
  });
  console.log();
  
  console.log('─── 3. Parent Read Operations ───');
  if (results.operations.childCreationFailed) {
    console.log(`  Child creation failed at: ${results.operations.childCreationFailed.atBatch}`);
  }
  console.log(`  A. Parent get():          ${results.operations.parentGet?.success ? '✓ PASS' : '✗ FAIL'}`);
  console.log(`  B. Khatmat query:         ${results.operations.khatmatQuery?.success ? '✓ PASS' : '✗ FAIL'}`);
  console.log(`  C. Hizb query:            ${results.operations.hizbQuery?.success ? '✓ PASS' : '✗ FAIL'}`);
  console.log(`  D. One hizb get():        ${results.operations.hizbGetOne?.success ? '✓ PASS' : '✗ FAIL'}`);
  console.log(`  E. All hizb get() loop:   ${results.operations.hizbGetAll?.success ? '✓ PASS' : '✗ FAIL'}`);
  console.log();
  
  console.log('─── 4. Single Child Validation ───');
  const validSingle = results.singleChild.validCreate?.success;
  const invalidDenied = !results.singleChild.invalidHizbNumber?.success;
  
  console.log(`  ONE valid create:         ${validSingle ? '✓ PASS' : '✗ FAIL'}`);
  console.log(`  ONE invalid denied:       ${invalidDenied ? '✓ PASS (denied)' : '✗ FAIL'}`);
  
  if (!validSingle && results.singleChild.validCreate?.error) {
    const has1000 = (results.singleChild.validCreate.error.message || '').includes('maximum 1000 expressions');
    console.log(`  Error type: ${has1000 ? '⚠️ 1000-EXPRESSION LIMIT (CRITICAL!)' : 'OTHER'}`);
  }
  console.log();
  
  console.log('─── 5. Sequential Batches ───');
  if (results.sequential.failedAt) {
    console.log(`  Failed at chunk: ${results.sequential.failedAt}`);
  } else {
    console.log('  All chunks succeeded');
  }
  console.log();
  
  console.log('─── 6. Sequential vs Fresh ───');
  if (results.sequential.sequentialVsFresh) {
    const svf = results.sequential.sequentialVsFresh;
    console.log(`  Sequential (4×5): ${svf.sequential ? '✓ PASS' : '✗ FAIL'}`);
    console.log(`  Fresh batch 20:   ${svf.freshBatch ? '✓ PASS' : '✗ FAIL'}`);
    console.log(`  Results differ:   ${svf.different ? '✓ YES (order-dependent)' : '✗ NO (consistent)'}`);
  }
  console.log();
  
  console.log('═══════════════════════════════════════════════════════');
  console.log('ROOT CAUSE DETERMINATION');
  console.log('═══════════════════════════════════════════════════════\n');
  
  // Determine root cause
  if (!results.singleChild.validCreate?.success) {
    const has1000 = (results.singleChild.validCreate.error?.message || '').includes('maximum 1000 expressions');
    if (has1000) {
      console.log('🚨 CRITICAL: Even ONE child create exhausts 1000-expression limit');
      console.log('   Root cause: Rules architecture is fundamentally too expensive');
      console.log('   Action: Rules must be optimized before ANY batch size works');
      results.rootCause = 'SINGLE_CHILD_EXHAUSTS_BUDGET';
    } else {
      console.log('⚠️  ONE child create fails for non-budget reason');
      console.log('   Root cause: Unknown validation issue');
      results.rootCause = 'SINGLE_CHILD_OTHER_ERROR';
    }
  } else if (allDeterministic) {
    const maxPassSize = [60, 30, 20, 15, 10, 5, 1].find(s => results.sizes[`size_${s}`]?.success);
    console.log(`✓ Results are deterministic`);
    console.log(`  Maximum safe batch size: ${maxPassSize || 'NONE'}`);
    
    if (maxPassSize && maxPassSize < 60) {
      console.log(`  Root cause: Rules budget exceeded at batch size > ${maxPassSize}`);
      results.rootCause = `MAX_BATCH_SIZE_${maxPassSize}`;
    } else if (maxPassSize === 60) {
      console.log(`  Root cause: No budget issue — batch of 60 works!`);
      results.rootCause = 'NO_BUDGET_ISSUE';
    } else {
      console.log(`  Root cause: All tested sizes fail`);
      results.rootCause = 'ALL_SIZES_FAIL';
    }
  } else {
    console.log('⚠️  Results are NON-DETERMINISTIC (test contamination)');
    console.log('   Root cause: Test harness issue, not rules budget');
    results.rootCause = 'NON_DETERMINISTIC_TEST_CONTAMINATION';
  }
  
  console.log();
  console.log('═══════════════════════════════════════════════════════\n');
  
  // Save detailed results
  await testEnv.cleanup();
  process.exit(0);
}

main().catch((e) => {
  console.error('Fatal error:', e);
  process.exit(1);
});
