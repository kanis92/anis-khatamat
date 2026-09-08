#!/usr/bin/env node

/**
 * ANIS Formations Preview Seed Tool
 * 
 * DEVELOPMENT ONLY - Seeds Firebase emulator with demo Formation data
 * for reproducible local preview.
 * 
 * SAFETY:
 * - Refuses to run unless FIRESTORE_EMULATOR_HOST is set
 * - Never writes to production
 * - Idempotent (can run multiple times)
 * 
 * USAGE:
 *   node tools/dev/seed_formations_preview.js
 */

const admin = require('firebase-admin');

// ═══════════════════════════════════════════════════════════════════════════
// SAFETY CHECK: Emulator MUST be configured
// ═══════════════════════════════════════════════════════════════════════════

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error('❌ SAFETY CHECK FAILED');
  console.error('');
  console.error('FIRESTORE_EMULATOR_HOST is not set.');
  console.error('This seed tool ONLY runs against Firebase emulators.');
  console.error('');
  console.error('To run this tool:');
  console.error('  export FIRESTORE_EMULATOR_HOST="localhost:8080"');
  console.error('  export FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"');
  console.error('  node tools/dev/seed_formations_preview.js');
  console.error('');
  process.exit(1);
}

console.log('═══════════════════════════════════════════════════════════════');
console.log('  ANIS Formations Preview Seed Tool');
console.log('═══════════════════════════════════════════════════════════════');
console.log('');
console.log('🔒 Safety: FIRESTORE_EMULATOR_HOST =', process.env.FIRESTORE_EMULATOR_HOST);
console.log('🔒 Safety: FIREBASE_AUTH_EMULATOR_HOST =', process.env.FIREBASE_AUTH_EMULATOR_HOST || 'not set');
console.log('');

// Initialize Firebase Admin with emulator
admin.initializeApp({ projectId: 'demo-test' });
const db = admin.firestore();

// ═══════════════════════════════════════════════════════════════════════════
// SEED DATA
// ═══════════════════════════════════════════════════════════════════════════

async function seedFormationsPreview() {
  console.log('🌱 Seeding Formation preview data...');
  console.log('');

  const courseId = 'demo-formation-basics';

  // ─────────────────────────────────────────────────────────────────────────
  // 1. COURSE (Learning Path)
  // ─────────────────────────────────────────────────────────────────────────

  await db.collection('courses').doc(courseId).set({
    title: 'Formation Basics Demo',
    description: 'Technical demonstration of the Formation V1 system',
    level: 'beginner',
    category: 'other', // Legacy field (kept for backward compatibility)
    pillarId: 'foundations_practice', // V1 pedagogical pillar
    deliveryMode: 'selfPaced',
    instructor: 'Demo Instructor',
    totalLessons: 3,
    totalDurationMinutes: 30,
    tags: ['demo', 'test', 'preview'],
    linkedFeatures: [],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isPublished: true,
  });
  console.log('✅ Course:', courseId);
  console.log('   Pillar: foundations_practice (Bases & pratique)');

  // ─────────────────────────────────────────────────────────────────────────
  // 2. MODULES
  // ─────────────────────────────────────────────────────────────────────────

  await db.collection('courses').doc(courseId)
    .collection('modules').doc('module-1-intro').set({
      courseId,
      title: 'Introduction Module',
      description: 'Getting started with the basics',
      order: 1,
      lessonIds: ['lesson-1', 'lesson-2'],
    });
  console.log('✅ Module: module-1-intro (2 lessons)');

  await db.collection('courses').doc(courseId)
    .collection('modules').doc('module-2-practice').set({
      courseId,
      title: 'Practice Module',
      description: 'Hands-on exercises',
      order: 2,
      lessonIds: ['lesson-3'],
    });
  console.log('✅ Module: module-2-practice (1 lesson)');

  // ─────────────────────────────────────────────────────────────────────────
  // 3. LESSONS
  // ─────────────────────────────────────────────────────────────────────────

  await db.collection('courses').doc(courseId)
    .collection('lessons').doc('lesson-1').set({
      courseId,
      moduleId: 'module-1-intro',
      title: 'Welcome to Formations',
      description: 'Introduction to the learning system',
      type: 'text',
      contentText: `# Welcome to Formations

This is a technical demonstration of the Formation V1 system.

## What You'll Learn

- How to navigate through learning paths
- How to complete lessons
- How to track your progress
- How the resume feature works

## System Architecture

The Formation system uses:
- **Pedagogical Pillars**: Stable taxonomy for organizing content
- **Server-Authoritative Progress**: All progress mutations via REST API
- **Real-Time Updates**: Firestore streams for instant UI updates

## Getting Started

Simply follow the lessons in order and mark them complete as you go.`,
      order: 1,
      durationMinutes: 5,
      summary: [
        'Navigate through learning paths using the pillar filter',
        'Complete lessons sequentially to track your progress',
        'Use the resume feature to continue where you left off',
      ],
      actionToApply: 'Explore the Formation landing page and review the pedagogical pillar filters',
      quiz: [],
    });
  console.log('✅ Lesson: lesson-1 (Welcome)');

  await db.collection('courses').doc(courseId)
    .collection('lessons').doc('lesson-2').set({
      courseId,
      moduleId: 'module-1-intro',
      title: 'Understanding Progress Tracking',
      description: 'How progress is managed',
      type: 'text',
      contentText: `# Understanding Progress Tracking

Your progress is tracked server-side for security and consistency.

## Key Concepts

### Completion
Mark lessons complete when you finish them. This action:
- Updates your progress percentage
- Unlocks the next lesson
- Triggers the resume card if you leave

### Resume
The system remembers your last active lesson. When you return:
- You'll see a "Continue Learning" card
- One tap takes you back to your current lesson
- Progress bars show your completion status

### Technical Architecture

All progress mutations go through the REST API to ensure:
- **Data Integrity**: Server validates all updates
- **Consistency**: No race conditions or conflicts
- **Security**: Users can only update their own progress`,
      order: 2,
      durationMinutes: 10,
      summary: [
        'Progress is server-authoritative for data integrity',
        'Resume functionality tracks your place automatically',
        'Completion is idempotent and safe to retry',
      ],
      actionToApply: 'Mark this lesson complete to see the progress indicator update',
      quiz: [],
    });
  console.log('✅ Lesson: lesson-2 (Progress Tracking)');

  await db.collection('courses').doc(courseId)
    .collection('lessons').doc('lesson-3').set({
      courseId,
      moduleId: 'module-2-practice',
      title: 'Practical Exercise',
      description: 'Put your knowledge into practice',
      type: 'text',
      contentText: `# Practical Exercise

Now it's time to practice what you've learned.

## Exercise Steps

1. **Navigate back** to the course detail screen
2. **Review** your progress indicators (checkmarks, progress bar)
3. **Complete this lesson** by tapping the button below
4. **Return to the landing page** using the back button
5. **Observe the resume card** that appears

## What to Notice

### Visual Indicators
- ✓ Checkmarks next to completed lessons
- Progress bar filling up
- Percentage displayed (33% → 66% → 100%)

### Resume Card
The resume card shows:
- Course title
- Your current progress
- A "Continue" button
- Last lesson you were working on

### Performance
Notice how updates are instant - this is thanks to:
- Real-time Firestore streams
- Optimistic UI updates
- Efficient state management

## Completion

This demonstrates the full Formation V1 user flow from start to finish.`,
      order: 3,
      durationMinutes: 15,
      summary: [
        'Practice the full navigation flow end-to-end',
        'Verify that progress indicators update correctly',
        'Test the resume functionality by leaving and returning',
      ],
      actionToApply: 'Complete the full course flow and verify all UI states work correctly on your device',
      quiz: [],
    });
  console.log('✅ Lesson: lesson-3 (Practice)');

  console.log('');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('✅ Seed Complete');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('');
  console.log('📊 Summary:');
  console.log('   - 1 published course (pillarId: foundations_practice)');
  console.log('   - 2 modules');
  console.log('   - 3 lessons');
  console.log('   - Neutral technical content only');
  console.log('');
  console.log('🚀 Next Steps:');
  console.log('   1. Start local ANIS API (see tools/dev/README.md)');
  console.log('   2. Launch Flutter in development mode');
  console.log('   3. Tap "Formations" tab');
  console.log('   4. Tap "Bases & pratique" pillar chip');
  console.log('   5. Course card should appear');
  console.log('');
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════

seedFormationsPreview()
  .then(() => {
    console.log('✅ Done');
    process.exit(0);
  })
  .catch((error) => {
    console.error('');
    console.error('❌ Seed failed:', error.message);
    console.error('');
    if (error.stack) {
      console.error(error.stack);
    }
    process.exit(1);
  });
