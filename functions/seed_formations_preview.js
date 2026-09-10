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
 *   node functions/seed_formations_preview.js
 */

const admin = require('firebase-admin');
const { cleanStalePreviewCourses } = require('./clean_stale_preview');

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
  console.error('  node functions/seed_formations_preview.js');
  console.error('');
  process.exit(1);
}

console.log('═══════════════════════════════════════════════════════════════');
console.log('  ANIS Formations Preview Seed Tool');
console.log('═══════════════════════════════════════════════════════════════');
console.log('');
const PROJECT_ID = 'anis-437c3'; // MUST match Flutter Firebase projectId

console.log('🔒 Safety: FIRESTORE_EMULATOR_HOST =', process.env.FIRESTORE_EMULATOR_HOST);
console.log('🔒 Safety: FIREBASE_AUTH_EMULATOR_HOST =', process.env.FIREBASE_AUTH_EMULATOR_HOST || 'not set');
console.log('🔒 Safety: PROJECT_ID =', PROJECT_ID);
console.log('');

// Initialize Firebase Admin with emulator
admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

// ═══════════════════════════════════════════════════════════════════════════
// PEDAGOGICAL PILLARS & EDITORIAL MODULE TAXONOMY
// ═══════════════════════════════════════════════════════════════════════════

const PILLARS_MODULES = {
  foundations_practice: {
    pillarName: "Bases & pratique",
    modules: [
      { id: 'getting-started', fr: "Bien démarrer", en: "Getting Started", ar: "البداية" },
      { id: 'fundamentals', fr: "Comprendre les fondamentaux", en: "Understanding the Fundamentals", ar: "فهم الأساسيات" },
      { id: 'daily-prayer', fr: "La prière au quotidien", en: "Daily Prayer", ar: "الصلاة اليومية" },
      { id: 'ablutions', fr: "Les ablutions et la préparation", en: "Ablutions and Preparation", ar: "الوضوء والتحضير" },
      { id: 'consistency', fr: "Organiser sa pratique avec constance", en: "Organizing Practice with Consistency", ar: "تنظيم الممارسة بانتظام" },
    ],
  },
  quran_reading: {
    pillarName: "Qur'an & lecture",
    modules: [
      { id: 'start-reading', fr: "Commencer à lire régulièrement", en: "Start Reading Regularly", ar: "ابدأ القراءة بانتظام" },
      { id: 'improve-reading', fr: "Améliorer sa lecture", en: "Improve Your Reading", ar: "حسّن قراءتك" },
      { id: 'quran-structure', fr: "Comprendre la structure du Qur'an", en: "Understanding Qur'an Structure", ar: "فهم بنية القرآن" },
      { id: 'attentive-reading', fr: "Lire avec attention et constance", en: "Reading with Attention and Consistency", ar: "القراءة بانتباه واستمرارية" },
      { id: 'reading-routine', fr: "Construire une routine de lecture", en: "Building a Reading Routine", ar: "بناء روتين للقراءة" },
    ],
  },
  prophet_seerah_sunnah: {
    pillarName: "Prophète ﷺ",
    modules: [
      { id: 'discover-sira', fr: "Découvrir la Sîra", en: "Discover the Sira", ar: "اكتشف السيرة" },
      { id: 'life-stages', fr: "Les grandes étapes de sa vie", en: "Major Life Stages", ar: "المراحل الكبرى من حياته" },
      { id: 'daily-behavior', fr: "Son comportement au quotidien", en: "His Daily Behavior", ar: "سلوكه اليومي" },
      { id: 'family-teachings', fr: "Ses enseignements dans la vie familiale et sociale", en: "His Teachings in Family and Social Life", ar: "تعاليمه في الحياة الأسرية والاجتماعية" },
      { id: 'apply-today', fr: "Ce que l'on peut appliquer aujourd'hui", en: "What We Can Apply Today", ar: "ما يمكننا تطبيقه اليوم" },
    ],
  },
  daily_life_france: {
    pillarName: "Vie quotidienne",
    modules: [
      { id: 'faith-at-work', fr: "Vivre sa foi au travail", en: "Living Faith at Work", ar: "عيش الإيمان في العمل" },
      { id: 'studies-work', fr: "Études, école et environnement professionnel", en: "Studies, School and Professional Environment", ar: "الدراسة والمدرسة والبيئة المهنية" },
      { id: 'family-responsibilities', fr: "Famille et responsabilités", en: "Family and Responsibilities", ar: "الأسرة والمسؤوليات" },
      { id: 'relationships', fr: "Relations avec son entourage", en: "Relationships with Others", ar: "العلاقات مع الآخرين" },
      { id: 'france-questions', fr: "Questions du quotidien en France", en: "Daily Questions in France", ar: "أسئلة يومية في فرنسا" },
      { id: 'modern-balance', fr: "Trouver un équilibre dans une société moderne", en: "Finding Balance in Modern Society", ar: "إيجاد التوازن في مجتمع حديث" },
    ],
  },
  character_ethics: {
    pillarName: "Comportement & éthique",
    modules: [
      { id: 'good-behavior', fr: "Le bon comportement", en: "Good Behavior", ar: "السلوك الحسن" },
      { id: 'respect-speech', fr: "Respect, parole et relations", en: "Respect, Speech and Relationships", ar: "الاحترام والكلام والعلاقات" },
      { id: 'manage-conflicts', fr: "Gérer les conflits", en: "Managing Conflicts", ar: "إدارة النزاعات" },
      { id: 'responsibility-trust', fr: "Responsabilité et confiance", en: "Responsibility and Trust", ar: "المسؤولية والثقة" },
      { id: 'digital-ethics', fr: "Éthique dans la vie numérique", en: "Ethics in Digital Life", ar: "الأخلاق في الحياة الرقمية" },
      { id: 'wise-behavior', fr: "Se comporter avec sagesse au quotidien", en: "Behaving Wisely Daily", ar: "التصرف بحكمة يوميًا" },
    ],
  },
  spirituality_heart: {
    pillarName: "Spiritualité & cœur",
    modules: [
      { id: 'strengthen-relationship', fr: "Renforcer sa relation avec Allah", en: "Strengthening Relationship with Allah", ar: "تقوية العلاقة مع الله" },
      { id: 'intention', fr: "Comprendre l'intention", en: "Understanding Intention", ar: "فهم النية" },
      { id: 'gratitude', fr: "Cultiver la gratitude", en: "Cultivating Gratitude", ar: "تنمية الامتنان" },
      { id: 'patience', fr: "Patience et constance", en: "Patience and Consistency", ar: "الصبر والثبات" },
      { id: 'difficult-times', fr: "Se recentrer dans les périodes difficiles", en: "Refocusing in Difficult Times", ar: "إعادة التركيز في الأوقات الصعبة" },
      { id: 'sustainable-practice', fr: "Construire une pratique durable", en: "Building Sustainable Practice", ar: "بناء ممارسة مستدامة" },
    ],
  },
};

const FOUNDATIONS_START_LESSONS = [
  {
    fr: 'Bienvenue dans les formations',
    en: 'Welcome to the courses',
    ar: 'مرحبًا بكم في الدورات',
  },
  {
    fr: 'Suivre sa progression',
    en: 'Track your progress',
    ar: 'متابعة تقدّمك',
  },
];

function lessonTitlesForModule(module, moduleIndex) {
  if (module.id === 'getting-started') {
    return FOUNDATIONS_START_LESSONS;
  }

  return [
    {
      fr: `${module.fr} — partie 1`,
      en: `${module.en} — part 1`,
      ar: `${module.ar} — الجزء 1`,
    },
    {
      fr: `${module.fr} — partie 2`,
      en: `${module.en} — part 2`,
      ar: `${module.ar} — الجزء 2`,
    },
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// SEED FUNCTION
// ═══════════════════════════════════════════════════════════════════════════

async function seedFormationsPreview() {
  console.log('🧹 Cleaning explicit legacy preview courses...');
  const deleted = await cleanStalePreviewCourses(db);
  if (deleted.length > 0) {
    console.log(`   Removed: ${deleted.join(', ')}`);
  } else {
    console.log('   No legacy preview courses found');
  }
  console.log('');

  console.log('🌱 Seeding Formation preview data...');
  console.log('');
  console.log('📋 TARGET: 6 pillars with editorial module taxonomy');
  console.log('');

  let totalCourses = 0;
  let totalModules = 0;
  let totalLessons = 0;

  for (const [pillarId, pillarData] of Object.entries(PILLARS_MODULES)) {
    const courseId = `course-${pillarId}`;
    let courseLessonCount = 0;

    // ─────────────────────────────────────────────────────────────────────────
    // COURSE
    // ─────────────────────────────────────────────────────────────────────────

    await db.collection('courses').doc(courseId).set({
      title: `${pillarData.pillarName} - Learning Path`,
      description: `Explore core topics in ${pillarData.pillarName}`,
      level: 'beginner',
      category: 'other',
      pillarId: pillarId,
      deliveryMode: 'selfPaced',
      instructor: 'ANIS Team',
      totalLessons: pillarData.modules.length * 2,
      totalDurationMinutes: pillarData.modules.length * 30,
      tags: [pillarId],
      linkedFeatures: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isPublished: true,
      translations: {
        fr: {
          title: `${pillarData.pillarName}`,
          description: `Parcours structuré pour ${pillarData.pillarName}`,
        },
        en: {
          title: `${pillarData.pillarName}`,
          description: `Structured learning path for ${pillarData.pillarName}`,
        },
        ar: {
          title: `${pillarData.pillarName}`,
          description: `مسار تعليمي منظم لـ ${pillarData.pillarName}`,
        },
      },
    });

    console.log(`✅ Course: ${courseId} (${pillarData.pillarName})`);
    totalCourses++;

    // ─────────────────────────────────────────────────────────────────────────
    // MODULES
    // ─────────────────────────────────────────────────────────────────────────

    for (let i = 0; i < pillarData.modules.length; i++) {
      const module = pillarData.modules[i];
      const moduleId = `${courseId}-module-${i + 1}`;
      const lessonTitles = lessonTitlesForModule(module, i);
      const lessonIds = [];

      for (let j = 0; j < lessonTitles.length; j++) {
        const lessonId = `${moduleId}-lesson-${j + 1}`;
        const lesson = lessonTitles[j];
        lessonIds.push(lessonId);

        await db.collection('courses').doc(courseId)
          .collection('lessons').doc(lessonId).set({
            courseId,
            moduleId,
            title: lesson.en,
            description: `Preview lesson for ${lesson.en}`,
            type: 'text',
            contentText: `Preview content for ${lesson.en}.`,
            summary: [`Summary for ${lesson.en}`],
            actionToApply: `Apply: ${lesson.en}`,
            order: j + 1,
            translations: {
              fr: {
                title: lesson.fr,
                description: `Leçon de prévisualisation : ${lesson.fr}`,
                contentText: `Contenu de prévisualisation pour ${lesson.fr}.`,
                summary: [`Résumé pour ${lesson.fr}`],
                actionToApply: `À appliquer : ${lesson.fr}`,
              },
              en: {
                title: lesson.en,
                description: `Preview lesson for ${lesson.en}`,
                contentText: `Preview content for ${lesson.en}.`,
                summary: [`Summary for ${lesson.en}`],
                actionToApply: `Apply: ${lesson.en}`,
              },
              ar: {
                title: lesson.ar,
                description: `درس معاينة: ${lesson.ar}`,
                contentText: `محتوى معاينة لـ ${lesson.ar}.`,
                summary: [`ملخص لـ ${lesson.ar}`],
                actionToApply: `تطبيق: ${lesson.ar}`,
              },
            },
          });

        totalLessons++;
        courseLessonCount++;
      }

      await db.collection('courses').doc(courseId)
        .collection('modules').doc(moduleId).set({
          courseId: courseId,
          title: module.en,
          description: `Learn about ${module.en}`,
          order: i + 1,
          lessonIds,
          translations: {
            fr: {
              title: module.fr,
              description: `Découvrez ${module.fr}`,
            },
            en: {
              title: module.en,
              description: `Learn about ${module.en}`,
            },
            ar: {
              title: module.ar,
              description: `تعرف على ${module.ar}`,
            },
          },
        });

      totalModules++;
    }

    await db.collection('courses').doc(courseId).update({
      totalLessons: courseLessonCount,
    });

    console.log(`   ├─ ${pillarData.modules.length} modules, ${courseLessonCount} lessons`);
  }

  console.log('');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('✅ Seed Complete');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('');
  console.log('📊 Summary:');
  console.log(`   - ${totalCourses} published courses (1 per pillar)`);
  console.log(`   - ${totalModules} editorial modules`);
  console.log(`   - ${totalLessons} preview lessons (2 per module)`);
  console.log('   - Canonical course IDs: course-{pillarId}');
  console.log('   - Multilingual (FR/EN/AR)');
  console.log('');
  console.log('🚀 Next Steps:');
  console.log('   1. Start local ANIS API (see tools/dev/README.md)');
  console.log('   2. Launch Flutter in development mode');
  console.log('   3. Tap "Formations" tab');
  console.log('   4. Select any pillar chip');
  console.log('   5. Course cards show module previews');
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
