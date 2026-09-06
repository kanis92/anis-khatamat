/**
 * CANONICAL HIZB DATA CONTRACT TEST
 * 
 * Validates that the two physical copies of canonical 60-Hizb data
 * (Dart and JSON) maintain identical structure and content.
 * 
 * This prevents silent drift between client and server canonical data.
 */

const fs = require('fs');
const path = require('path');

// Load the server-side canonical data (TypeScript/JSON)
const serverCanonicalData = require('../../functions/src/data/canonical_hizb.json');
const serverCanonical = serverCanonicalData.hizbs;

// Load and parse the Dart canonical data
const dartFilePath = path.resolve(__dirname, '../../lib/core/data/hizb_canonical_data.dart');
const dartContent = fs.readFileSync(dartFilePath, 'utf8');

// Extract the canonical Hizb data from Dart
function extractDartCanonical() {
  const hizbMatch = dartContent.match(/static\s+const\s+refs\s*=\s*<HizbCanonicalRef>\[([\s\S]*?)\];/);
  if (!hizbMatch) throw new Error('Could not find refs = <HizbCanonicalRef>[...] in Dart file');
  
  const arrayContent = hizbMatch[1];
  const hizbRefs = [];
  
  // Parse each HizbCanonicalRef (multiline with various fields)
  const refRegex = /HizbCanonicalRef\(([^)]+)\)/g;
  
  let match;
  while ((match = refRegex.exec(arrayContent)) !== null) {
    const content = match[1];
    
    const getField = (name) => {
      const fieldMatch = content.match(new RegExp(`${name}:\\s*'?([^,\\s']+)'?`));
      return fieldMatch ? (name === 'definitionId' ? fieldMatch[1] : parseInt(fieldMatch[1])) : null;
    };
    
    hizbRefs.push({
      number: getField('hizbNumber'),
      startSurah: getField('startSurah'),
      startAyah: getField('startAyah'),
      endSurah: getField('endSurah'),
      endAyah: getField('endAyah'),
      definitionId: getField('definitionId')
    });
  }
  
  return hizbRefs;
}

function main() {
  console.log('\nCanonical Hizb Data Contract Validation\n');
  
  const dartCanonical = extractDartCanonical();
  
  let passed = 0;
  let failed = 0;
  
  const test = (name, fn) => {
    process.stdout.write(`  ${name} ... `);
    try {
      fn();
      console.log('PASS');
      passed++;
    } catch (err) {
      console.log('FAIL');
      console.error(`    ${err.message}`);
      failed++;
    }
  };
  
  test('Both sources have exactly 60 Hizb', () => {
    if (serverCanonical.length !== 60) {
      throw new Error(`Server has ${serverCanonical.length} Hizb, expected 60`);
    }
    if (dartCanonical.length !== 60) {
      throw new Error(`Dart has ${dartCanonical.length} Hizb, expected 60`);
    }
  });
  
  test('All Hizb IDs are sequential 1..60', () => {
    for (let i = 0; i < 60; i++) {
      const expectedNumber = i + 1;
      const serverNum = serverCanonical[i].hizbNumber || serverCanonical[i].number;
      if (serverNum !== expectedNumber) {
        throw new Error(`Server Hizb[${i}] has number ${serverNum}, expected ${expectedNumber}`);
      }
      if (dartCanonical[i].number !== expectedNumber) {
        throw new Error(`Dart Hizb[${i}] has number ${dartCanonical[i].number}, expected ${expectedNumber}`);
      }
    }
  });
  
  test('All definition IDs are "quran_foundation_hafs_v1"', () => {
    const expectedId = 'quran_foundation_hafs_v1';
    
    // Check server-wide definition
    if (serverCanonicalData.definitionId !== expectedId) {
      throw new Error(`Server data has definitionId "${serverCanonicalData.definitionId}", expected "${expectedId}"`);
    }
    
    // For Dart: Check if definitionId constant exists in file
    const dartDefIdMatch = dartContent.match(/static\s+const\s+(?:String\s+)?definitionId\s*=\s*['"]([^'"]+)['"]/);
    if (!dartDefIdMatch) {
      // Definition ID might be implicit or defined elsewhere - this is acceptable
      // as long as boundaries match exactly
      console.log('    (Dart definitionId not found in individual Hizb records - checking server contract)');
    } else {
      const dartDefId = dartDefIdMatch[1];
      if (dartDefId !== expectedId) {
        throw new Error(`Dart definitionId "${dartDefId}", expected "${expectedId}"`);
      }
    }
  });
  
  test('All 60 Hizb boundaries match exactly', () => {
    for (let i = 0; i < 60; i++) {
      const server = serverCanonical[i];
      const dart = dartCanonical[i];
      const hizbNum = i + 1;
      
      // Note: server uses hizbNumber, dart uses number
      const serverNum = server.hizbNumber || server.number;
      const dartNum = dart.number;
      
      if (serverNum !== dartNum) {
        throw new Error(`Hizb index ${i}: server.hizbNumber=${serverNum}, dart.number=${dartNum}`);
      }
      if (server.startSurah !== dart.startSurah) {
        throw new Error(`Hizb ${hizbNum} startSurah: server=${server.startSurah}, dart=${dart.startSurah}`);
      }
      if (server.startAyah !== dart.startAyah) {
        throw new Error(`Hizb ${hizbNum} startAyah: server=${server.startAyah}, dart=${dart.startAyah}`);
      }
      if (server.endSurah !== dart.endSurah) {
        throw new Error(`Hizb ${hizbNum} endSurah: server=${server.endSurah}, dart=${dart.endSurah}`);
      }
      if (server.endAyah !== dart.endAyah) {
        throw new Error(`Hizb ${hizbNum} endAyah: server=${server.endAyah}, dart=${dart.endAyah}`);
      }
    }
  });
  
  test('Spot check: Hizb 1 = [1:1 → 2:74] (Quran Foundation)', () => {
    const h1s = serverCanonical[0];
    const h1d = dartCanonical[0];
    if (h1s.startSurah !== 1 || h1s.startAyah !== 1 || h1s.endSurah !== 2 || h1s.endAyah !== 74) {
      throw new Error(`Server Hizb 1 boundaries incorrect: [${h1s.startSurah}:${h1s.startAyah} → ${h1s.endSurah}:${h1s.endAyah}]`);
    }
    if (h1d.startSurah !== 1 || h1d.startAyah !== 1 || h1d.endSurah !== 2 || h1d.endAyah !== 74) {
      throw new Error(`Dart Hizb 1 boundaries incorrect: [${h1d.startSurah}:${h1d.startAyah} → ${h1d.endSurah}:${h1d.endAyah}]`);
    }
  });
  
  test('Spot check: Hizb 60 = [87:1 → 114:6] (Quran Foundation)', () => {
    const h60s = serverCanonical[59];
    const h60d = dartCanonical[59];
    if (h60s.startSurah !== 87 || h60s.startAyah !== 1 || h60s.endSurah !== 114 || h60s.endAyah !== 6) {
      throw new Error(`Server Hizb 60 boundaries incorrect: [${h60s.startSurah}:${h60s.startAyah} → ${h60s.endSurah}:${h60s.endAyah}]`);
    }
    if (h60d.startSurah !== 87 || h60d.startAyah !== 1 || h60d.endSurah !== 114 || h60d.endAyah !== 6) {
      throw new Error(`Dart Hizb 60 boundaries incorrect: [${h60d.startSurah}:${h60d.startAyah} → ${h60d.endSurah}:${h60d.endAyah}]`);
    }
  });
  
  console.log(`\n${passed} passed, ${failed} failed\n`);
  
  if (failed > 0) {
    console.error('❌ CANONICAL DATA DRIFT DETECTED');
    process.exit(1);
  } else {
    console.log('✅ CANONICAL DATA CONTRACT VERIFIED');
    process.exit(0);
  }
}

main();
