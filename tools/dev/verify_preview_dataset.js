#!/usr/bin/env node
'use strict';

// ═══════════════════════════════════════════════════════════════════════════
// ANIS — Canonical Formation preview dataset verification (EMULATOR ONLY)
// ═══════════════════════════════════════════════════════════════════════════
//
// Asserts that the Firestore emulator holds exactly the canonical preview
// dataset before the app is launched. A half-seeded emulator is the main cause
// of "Modules à venir" appearing for content that should exist.
//
// SAFETY
// - Refuses to run unless FIRESTORE_EMULATOR_HOST points at a loopback host.
// - Read-only: uses the emulator REST API, never writes.
//
// Usage:
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node tools/dev/verify_preview_dataset.js
// ═══════════════════════════════════════════════════════════════════════════

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'anis-437c3';
const EXPECTED_COURSES = 6;
const EXPECTED_MODULES = 33;

const LOOPBACK_HOSTS = new Set(['127.0.0.1', 'localhost', '::1', '[::1]']);

class DatasetVerificationError extends Error {}

function resolveFirestoreEmulatorHost(env = process.env) {
  const host = env.FIRESTORE_EMULATOR_HOST;
  if (!host) {
    throw new DatasetVerificationError(
      'FIRESTORE_EMULATOR_HOST is not set. This verification is emulator-only.'
    );
  }

  const separator = host.lastIndexOf(':');
  const hostname = separator > 0 ? host.slice(0, separator) : host;
  if (!LOOPBACK_HOSTS.has(hostname)) {
    throw new DatasetVerificationError(
      `Refusing to verify a non-loopback Firestore host "${hostname}".`
    );
  }
  return host;
}

function documentsUrl(host, path) {
  return (
    `http://${host}/v1/projects/${PROJECT_ID}/databases/(default)/documents` +
    `/${path}?pageSize=300`
  );
}

async function listDocuments(host, path) {
  // "Bearer owner" is the emulator's local admin credential: it bypasses the
  // rules so that this check reports on the seeded data, not on rule coverage.
  const response = await fetch(documentsUrl(host, path), {
    headers: { Authorization: 'Bearer owner' },
  });
  if (!response.ok) {
    throw new DatasetVerificationError(
      `Firestore emulator returned ${response.status} for "${path}".`
    );
  }
  const payload = await response.json();
  return Array.isArray(payload.documents) ? payload.documents : [];
}

function documentId(doc) {
  return doc.name.slice(doc.name.lastIndexOf('/') + 1);
}

function isPublished(doc) {
  const field = doc.fields && doc.fields.isPublished;
  return Boolean(field && field.booleanValue);
}

/**
 * Returns `{ courses, modules, byCourse }` for the published preview dataset.
 */
async function inspectDataset(host) {
  const courseDocs = (await listDocuments(host, 'courses')).filter(isPublished);
  const byCourse = {};
  let modules = 0;

  for (const course of courseDocs) {
    const id = documentId(course);
    const moduleDocs = await listDocuments(host, `courses/${id}/modules`);
    byCourse[id] = moduleDocs.length;
    modules += moduleDocs.length;
  }

  return { courses: courseDocs.length, modules, byCourse };
}

function assertCanonicalDataset(summary) {
  const problems = [];
  if (summary.courses !== EXPECTED_COURSES) {
    problems.push(
      `expected ${EXPECTED_COURSES} published courses, found ${summary.courses}`
    );
  }
  if (summary.modules !== EXPECTED_MODULES) {
    problems.push(
      `expected ${EXPECTED_MODULES} modules, found ${summary.modules}`
    );
  }
  const emptyCourses = Object.entries(summary.byCourse)
    .filter(([, count]) => count === 0)
    .map(([id]) => id);
  if (emptyCourses.length > 0) {
    problems.push(`courses without modules: ${emptyCourses.join(', ')}`);
  }
  const foundations = summary.byCourse['course-foundations_practice'];
  if (foundations !== 5) {
    problems.push(
      `course-foundations_practice must have 5 modules, found ${foundations ?? 0}`
    );
  }

  if (problems.length > 0) {
    throw new DatasetVerificationError(
      `Canonical preview dataset mismatch — ${problems.join('; ')}.`
    );
  }
}

async function main() {
  const host = resolveFirestoreEmulatorHost();
  console.log(`🔒 Firestore emulator: ${host} (project ${PROJECT_ID})`);

  const summary = await inspectDataset(host);
  assertCanonicalDataset(summary);

  for (const [courseId, count] of Object.entries(summary.byCourse)) {
    console.log(`   • ${courseId}: ${count} modules`);
  }
  console.log(
    `✅ Canonical dataset verified: ${summary.courses} courses, ` +
      `${summary.modules} modules`
  );
}

module.exports = {
  EXPECTED_COURSES,
  EXPECTED_MODULES,
  DatasetVerificationError,
  resolveFirestoreEmulatorHost,
  inspectDataset,
  assertCanonicalDataset,
};

if (require.main === module) {
  main().catch((error) => {
    console.error(`❌ ${error.message}`);
    process.exit(1);
  });
}
