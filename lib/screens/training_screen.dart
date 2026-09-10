import 'dart:math' show cos, sin;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/l10n_extensions.dart';
import '../core/theme/app_theme.dart';
import '../features/formations/models/course.dart';
import '../features/formations/models/course_module.dart';
import '../features/formations/models/lesson.dart';
import '../features/formations/models/pedagogical_pillar.dart';
import '../features/formations/models/saved_formation_item.dart';
import '../features/formations/presentation/course_presentation.dart';
import '../features/formations/presentation/course_content_resolver.dart';
import '../features/formations/presentation/formation_resume_resolver.dart';
import '../features/formations/providers/formation_learning_providers.dart';
import '../features/formations/presentation/formations_state_views.dart';
import '../features/formations/providers/formations_providers.dart';
import '../features/formations/providers/saved_formations_providers.dart';
import '../features/formations/providers/formation_search_providers.dart';
import '../features/formations/models/formation_search_result.dart';
import '../l10n/gen_l10n/app_localizations.dart';

/// ANIS Formations V1 — Premium learning hub
///
/// Architecture V1 preserved:
/// - Server-authoritative progress via API
/// - Multilingual resolvers
/// - PedagogicalPillar taxonomy
/// - Bottom navigation (managed by router)
///
/// Visual redesign: premium editorial learning platform
class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _tabsSectionKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  PedagogicalPillar? _previousPillar;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(filteredCoursesProvider);
    final selectedPillar = ref.watch(selectedPillarProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = searchQuery.trim().isNotEmpty
        ? ref.watch(formationSearchResultsProvider)
        : <FormationSearchResult>[];

    // Detect pillar change and scroll to tabs
    if (_previousPillar != selectedPillar && selectedPillar != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && _tabsSectionKey.currentContext != null) {
          final context = _tabsSectionKey.currentContext!;
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.1, // Position tabs near top with breathing room
          );
        }
      });
    }
    _previousPillar = selectedPillar;

    return Scaffold(
      backgroundColor: AppTheme.creamLight,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ═══ 1. PREMIUM HERO HEADER ═══
              _PremiumHero(),
              const SizedBox(height: 24),

              // ═══ 2. SEARCH BAR ═══
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                  onClear: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                    _searchFocusNode.unfocus();
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ═══ 3. SEARCH RESULTS OR NORMAL CONTENT ═══
              if (searchQuery.trim().isNotEmpty)
                _SearchResults(
                  query: searchQuery,
                  results: searchResults,
                  onResultTap: () {
                    _searchFocusNode.unfocus();
                  },
                )
              else ...[
                // ═══ MON APPRENTISSAGE (Tous tab only) ═══
                if (selectedPillar == null) ...[
                  _MyLearningSection(tabsSectionKey: _tabsSectionKey),
                  const SizedBox(height: 32),
                  const _SavedForLaterSection(),
                ],

                // ═══ 4. EXPLORER PAR THÈME ═══
                Container(
                  key: _tabsSectionKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionTitle(
                        title: context.l10n.exploreByTheme,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: SizedBox(
                          height: 42,
                          child: _PillarFilter(
                            selectedPillar: selectedPillar,
                            onPillarSelected: (pillar) {
                              ref.read(selectedPillarProvider.notifier).state = pillar;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ═══ 5. DYNAMIC CONTENT BASED ON SELECTED TAB ═══
                if (selectedPillar == null)
                  // "Tous" overview
                  _TousOverview(coursesAsync: coursesAsync)
                else
                  // Specific pillar modules
                  _PillarModulesView(
                    pillar: selectedPillar,
                    coursesAsync: coursesAsync,
                  ),
              ],

              const SizedBox(height: 100), // Bottom nav clearance
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SEARCH BAR
// ═════════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: l10n.searchFormations,
            hintStyle: TextStyle(
              color: Colors.black.withOpacity(0.4),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.black.withOpacity(0.4),
              size: 22,
            ),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.black.withOpacity(0.6),
                      size: 20,
                    ),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SEARCH RESULTS
// ═════════════════════════════════════════════════════════════════════════════

class _SearchResults extends ConsumerWidget {
  final String query;
  final List<FormationSearchResult> results;
  final VoidCallback onResultTap;

  const _SearchResults({
    required this.query,
    required this.results,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (results.isEmpty) {
      // No results
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.black.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.searchNoResults(query),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.6),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: results.map((result) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SearchResultCard(
              result: result,
              onTap: () {
                onResultTap();
                _navigateToResult(context, ref, result);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _navigateToResult(
    BuildContext context,
    WidgetRef ref,
    FormationSearchResult result,
  ) {
    switch (result.type) {
      case FormationSearchResultType.course:
        context.go('/training/course/${result.targetId}');
        break;
      case FormationSearchResultType.lesson:
        if (result.courseId != null) {
          context.go(
            '/training/course/${result.courseId}/lesson/${result.targetId}',
          );
        }
        break;
      case FormationSearchResultType.module:
        // Navigate to course and let user explore the module
        if (result.courseId != null) {
          context.go('/training/course/${result.courseId}');
        }
        break;
    }
  }
}

class _SearchResultCard extends StatelessWidget {
  final FormationSearchResult result;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    String resultTypeLabel;
    switch (result.type) {
      case FormationSearchResultType.course:
        resultTypeLabel = l10n.searchResultTypeCourse;
        break;
      case FormationSearchResultType.module:
        resultTypeLabel = l10n.searchResultTypeModule;
        break;
      case FormationSearchResultType.lesson:
        resultTypeLabel = l10n.searchResultTypeLesson;
        break;
    }

    // Build context line (e.g., "Bases & pratique · Se préparer à la prière")
    final contextParts = <String>[];
    if (result.courseTitle != null) {
      contextParts.add(result.courseTitle!);
    }
    if (result.moduleTitle != null) {
      contextParts.add(result.moduleTitle!);
    }
    final contextLine = contextParts.join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result type badge
            Text(
              resultTypeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 6),

            // Title
            Text(
              result.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.4,
              ),
            ),

            // Context
            if (contextLine.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                contextLine,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECTION TITLE
// ═════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGreen,
              letterSpacing: -0.3,
            ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. PREMIUM HERO HEADER
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    const posterRadius = BorderRadius.only(
      bottomLeft: Radius.circular(32),
      bottomRight: Radius.circular(64),
    );

    return ClipRRect(
      key: const ValueKey('formations-hero'),
      borderRadius: posterRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
            colors: [
              AppTheme.primaryGreen,
              const Color(0xFF0E4D3A),
              const Color(0xFF0A3A2B),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: _HeroMotifLayer(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.formations.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.8,
                      height: 1.0,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Apprendre.\nComprendre.\nMettre en pratique.',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      height: 1.22,
                      letterSpacing: 0.2,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Des parcours conçus pour avancer avec clarté et constance.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFE8D5A3),
                      height: 1.35,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMotifLayer extends StatelessWidget {
  const _HeroMotifLayer();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: const Alignment(1.15, -0.85),
          child: Opacity(
            opacity: 0.10,
            child: CustomPaint(
              size: const Size(168, 168),
              painter: _IslamicArchMotifPainter(),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(-1.2, 1.15),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFF9F2).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ISLAMIC ARCH MOTIF PAINTER (Subtle geometric background)
// ═════════════════════════════════════════════════════════════════════════════

class _IslamicArchMotifPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius1 = size.width * 0.25;
    final radius2 = size.width * 0.35;
    final radius3 = size.width * 0.45;

    // Concentric arcs
    canvas.drawCircle(center, radius1, paint);
    canvas.drawCircle(center, radius2, paint);
    canvas.drawCircle(center, radius3, paint);

    // Radial lines
    for (var i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final x = center.dx + radius3 * cos(angle);
      final y = center.dy + radius3 * sin(angle);
      canvas.drawLine(center, Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// "TOUS" OVERVIEW (when no specific pillar selected)
// ═════════════════════════════════════════════════════════════════════════════

class _TousOverview extends ConsumerWidget {
  const _TousOverview({required this.coursesAsync});

  final AsyncValue<List<Course>> coursesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured courses
        coursesAsync.when(
          loading: () => const _LoadingState(),
          error: (error, _) => FormationsFailureView(
            error: error,
            onRetry: () => ref.invalidate(publishedCoursesProvider),
          ),
          data: (courses) {
            if (courses.isEmpty) {
              return const _EmptyState();
            }

            final featured = courses.take(3).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: l10n.featuredPaths),
                const SizedBox(height: 12),
                ...featured.map((course) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 16,
                    ),
                    child: _FeaturedCourseCard(course: course),
                  );
                }),
              ],
            );
          },
        ),

        const SizedBox(height: 32),

        // Live section
        _SectionTitle(title: l10n.liveSection),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _LiveCard(),
        ),

        const SizedBox(height: 32),

        // Questions section
        _SectionTitle(title: l10n.questionsSection),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _QuestionsCard(),
        ),

        const SizedBox(height: 32),

        // All formations
        coursesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FormationsFailureView(
              error: error,
              onRetry: () => ref.invalidate(publishedCoursesProvider),
            ),
          ),
          data: (courses) {
            if (courses.isEmpty) return const SizedBox.shrink();

            final remaining = courses.skip(3).toList();
            if (remaining.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: l10n.allFormations),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: remaining.map((course) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CompactCourseCard(course: course),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PILLAR MODULES VIEW (when specific pillar selected)
// ═════════════════════════════════════════════════════════════════════════════

class _PillarModulesView extends ConsumerWidget {
  const _PillarModulesView({
    required this.pillar,
    required this.coursesAsync,
  });

  final PedagogicalPillar pillar;
  final AsyncValue<List<Course>> coursesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pillarName = _getPillarName(pillar, l10n);

    return coursesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => FormationsFailureView(
        error: error,
        onRetry: () {
          ref.invalidate(coursesByPillarProvider(pillar.id));
          ref.invalidate(publishedCoursesProvider);
        },
      ),
      data: (courses) {
        final pillarCourses = courses
            .where((course) => course.pillarId == pillar.id)
            .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pillar title
              Text(
                pillarName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Pillar description
              Text(
                _getPillarDescription(pillar, l10n),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 26),

              _PillarModulesHeader(courses: pillarCourses),
              const SizedBox(height: 16),

              if (pillarCourses.isEmpty)
                _PillarEmptyState(pillarName: pillarName)
              else
                ...pillarCourses.map((course) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PillarCourseModules(
                      course: course,
                      showCourseTitle: pillarCourses.length > 1,
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  String _getPillarName(PedagogicalPillar pillar, AppLocalizations l10n) {
    switch (pillar) {
      case PedagogicalPillar.foundationsPractice:
        return l10n.pillarFoundationsPractice;
      case PedagogicalPillar.quranReading:
        return l10n.pillarQuranReading;
      case PedagogicalPillar.prophetSeerahSunnah:
        return l10n.pillarProphetSeerahSunnah;
      case PedagogicalPillar.dailyLifeFrance:
        return l10n.pillarDailyLifeFrance;
      case PedagogicalPillar.characterEthics:
        return l10n.pillarCharacterEthics;
      case PedagogicalPillar.spiritualityHeart:
        return l10n.pillarSpiritualityHeart;
    }
  }

  String _getPillarDescription(PedagogicalPillar pillar, AppLocalizations l10n) {
    switch (pillar) {
      case PedagogicalPillar.foundationsPractice:
        return 'Parcours structuré pour comprendre et pratiquer les fondamentaux de l\'Islam au quotidien.';
      case PedagogicalPillar.quranReading:
        return 'Apprenez à lire, comprendre et établir une relation durable avec le Qur\'an.';
      case PedagogicalPillar.prophetSeerahSunnah:
        return 'Découvrez la vie du Prophète ﷺ et comment appliquer ses enseignements aujourd\'hui.';
      case PedagogicalPillar.dailyLifeFrance:
        return 'Vivre sa foi au quotidien : travail, études, famille et société.';
      case PedagogicalPillar.characterEthics:
        return 'Développer un bon comportement et une éthique dans toutes les dimensions de la vie.';
      case PedagogicalPillar.spiritualityHeart:
        return 'Renforcer sa spiritualité et sa relation avec Allah dans la durée.';
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PILLAR MODULES HEADER (real module count)
// ═════════════════════════════════════════════════════════════════════════════

class _PillarModulesHeader extends ConsumerWidget {
  const _PillarModulesHeader({required this.courses});

  final List<Course> courses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    var totalCount = 0;
    var allLoaded = courses.isNotEmpty;

    for (final course in courses) {
      final modulesAsync = ref.watch(courseModulesProvider(course.id));
      modulesAsync.when(
        data: (modules) => totalCount += modules.length,
        loading: () => allLoaded = false,
        error: (_, __) => allLoaded = false,
      );
    }

    final label = allLoaded && courses.isNotEmpty
        ? 'Modules   $totalCount'
        : 'Modules';

    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppTheme.primaryGreen,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PILLAR COURSE MODULES (expandable, real lessons)
// ═════════════════════════════════════════════════════════════════════════════

class _PillarCourseModules extends ConsumerStatefulWidget {
  const _PillarCourseModules({
    required this.course,
    this.showCourseTitle = false,
  });

  final Course course;
  final bool showCourseTitle;

  @override
  ConsumerState<_PillarCourseModules> createState() =>
      _PillarCourseModulesState();
}

class _PillarCourseModulesState extends ConsumerState<_PillarCourseModules> {
  String? _expandedModuleId;

  void _toggleModule(String moduleId, {required bool hasLessons}) {
    if (!hasLessons) return;
    setState(() {
      _expandedModuleId = _expandedModuleId == moduleId ? null : moduleId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final l10n = context.l10n;
    final modulesAsync = ref.watch(courseModulesProvider(widget.course.id));
    final lessonsAsync = ref.watch(courseLessonsProvider(widget.course.id));

    return modulesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, _) => FormationsFailureView(
        error: error,
        onRetry: () {
          ref.invalidate(courseModulesProvider(widget.course.id));
          ref.invalidate(courseLessonsProvider(widget.course.id));
        },
      ),
      data: (modules) {
        if (modules.isEmpty) {
          return _FormationModulesEmptyState(
            courseTitle: widget.course.localizedTitle(context),
          );
        }

        final lessonsLoaded = lessonsAsync.hasValue;
        final lessons = lessonsAsync.valueOrNull ?? const <Lesson>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showCourseTitle) ...[
              Text(
                widget.course.localizedTitle(context),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 10),
            ],
            ...modules.asMap().entries.map((entry) {
              final index = entry.key;
              final module = entry.value;
              final resolvedContent =
                  ModuleContentResolver.resolve(module, locale);
              final moduleLessons = lessonsLoaded
                  ? _lessonsForModule(lessons, module)
                  : const <Lesson>[];
              final hasLessons = lessonsLoaded
                  ? moduleLessons.isNotEmpty
                  : module.lessonIds.isNotEmpty;
              final lessonCount = lessonsLoaded
                  ? moduleLessons.length
                  : module.lessonIds.length;
              final isExpanded = _expandedModuleId == module.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => _toggleModule(
                          module.id,
                          hasLessons: hasLessons,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isExpanded
                                  ? AppTheme.primaryGreen.withValues(alpha: 0.25)
                                  : Colors.grey[200]!,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resolvedContent.title,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[900],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lessonCount > 0
                                          ? '$lessonCount leçon${lessonCount > 1 ? 's' : ''}'
                                          : l10n.moduleContentComingSoon,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasLessons)
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 180),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 22,
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: isExpanded
                          ? (lessonsLoaded
                              ? _ExpandedModuleLessons(
                                  course: widget.course,
                                  moduleLessons: moduleLessons,
                                  locale: locale,
                                )
                              : const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ))
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  List<Lesson> _lessonsForModule(List<Lesson> lessons, CourseModule module) {
    final byModuleId =
        lessons.where((lesson) => lesson.moduleId == module.id).toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    if (byModuleId.isNotEmpty) {
      return byModuleId;
    }

    if (module.lessonIds.isEmpty) {
      return const [];
    }

    final byIds = <Lesson>[];
    for (final lessonId in module.lessonIds) {
      for (final lesson in lessons) {
        if (lesson.id == lessonId) {
          byIds.add(lesson);
          break;
        }
      }
    }
    byIds.sort((a, b) => a.order.compareTo(b.order));
    return byIds;
  }
}

class _ExpandedModuleLessons extends StatelessWidget {
  const _ExpandedModuleLessons({
    required this.course,
    required this.moduleLessons,
    required this.locale,
  });

  final Course course;
  final List<Lesson> moduleLessons;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 8, right: 4, bottom: 4),
      child: Column(
        children: moduleLessons.map((lesson) {
          final lessonContent = LessonContentResolver.resolve(lesson, locale);

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: AppTheme.creamLight,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  context.push(
                    '/formations/${course.id}/lessons/${lesson.id}',
                    extra: {'course': course},
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lessonContent.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppTheme.primaryGreen.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FORMATION FAILURE / EMPTY STATES
// ═════════════════════════════════════════════════════════════════════════════

class _FormationModulesEmptyState extends StatelessWidget {
  const _FormationModulesEmptyState({required this.courseTitle});

  final String courseTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        context.l10n.formationsCourseModulesEmpty(courseTitle),
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
          height: 1.4,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PILLAR EMPTY STATE
// ═════════════════════════════════════════════════════════════════════════════

class _PillarEmptyState extends StatelessWidget {
  const _PillarEmptyState({required this.pillarName});

  final String pillarName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Modules à venir',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les modules pour "$pillarName" seront bientôt disponibles.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. MON APPRENTISSAGE
// ═════════════════════════════════════════════════════════════════════════════

class _MyLearningSection extends ConsumerWidget {
  const _MyLearningSection({required this.tabsSectionKey});

  final GlobalKey tabsSectionKey;

  void _scrollToCatalogue(BuildContext context) {
    final target = tabsSectionKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final learningAsync = ref.watch(myLearningStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.myLearning),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: learningAsync.when(
            loading: () => const _MyLearningSkeleton(),
            error: (error, _) => FormationsFailureView(
              error: error,
              onRetry: () => ref.invalidate(myLearningStateProvider),
            ),
            data: (state) {
              switch (state.display) {
                case MyLearningDisplayState.empty:
                  return _MyLearningEmptyCard(
                    onDiscover: () => _scrollToCatalogue(context),
                  );
                case MyLearningDisplayState.allCompleted:
                  return _MyLearningCompletedCard(
                    onDiscover: () => _scrollToCatalogue(context),
                  );
                case MyLearningDisplayState.active:
                  final active = state.active;
                  if (active == null) {
                    return _MyLearningEmptyCard(
                      onDiscover: () => _scrollToCatalogue(context),
                    );
                  }
                  return _MyLearningActiveCard(active: active);
              }
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _MyLearningSkeleton extends StatelessWidget {
  const _MyLearningSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

class _MyLearningEmptyCard extends StatelessWidget {
  const _MyLearningEmptyCard({required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return _MyLearningSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.myLearningEmptyTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryGreen,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.myLearningEmptyBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onDiscover,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      l10n.discoverFormations,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyLearningCompletedCard extends StatelessWidget {
  const _MyLearningCompletedCard({required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return _MyLearningSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.myLearningAllCompletedTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryGreen,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.myLearningAllCompletedBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onDiscover,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      l10n.discoverFormations,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyLearningActiveCard extends StatelessWidget {
  const _MyLearningActiveCard({required this.active});

  final ResolvedActiveLearning active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final course = active.course;
    final moduleContent =
        ModuleContentResolver.resolve(active.module, locale);
    final lessonContent =
        LessonContentResolver.resolve(active.currentLesson, locale);

    return _MyLearningSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.myLearningResumeSubtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            course.localizedPillarOrCategory(context),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.accentGold,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            course.localizedTitle(context),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGreen,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            moduleContent.title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            lessonContent.title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: active.progressFraction,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              context.push(
                '/formations/${course.id}/lessons/${active.resumeLessonId}',
                extra: {'course': course},
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.resume,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyLearningSurface extends StatelessWidget {
  const _MyLearningSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppTheme.creamLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.06),
            offset: const Offset(0, 3),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SAVED FOR LATER SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _SavedForLaterSection extends ConsumerWidget {
  const _SavedForLaterSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedItemsAsync = ref.watch(savedFormationsProvider);

    return savedItemsAsync.when(
      loading: () => const _SavedForLaterSkeleton(),
      error: (error, _) => FormationsFailureView(
        error: error,
        onRetry: () => ref.invalidate(savedFormationsProvider),
      ),
      data: (savedItems) {
        if (savedItems.isEmpty) {
          return const SizedBox.shrink(); // Don't show section if empty
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(title: context.l10n.savedForLater),
            const SizedBox(height: 12),
            ...savedItems.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SavedItemCard(item: item),
                )),
          ],
        );
      },
    );
  }
}

class _SavedForLaterSkeleton extends StatelessWidget {
  const _SavedForLaterSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 80,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SavedItemCard extends ConsumerWidget {
  const _SavedItemCard({required this.item});

  final SavedFormationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // Resolve the actual course/lesson from canonical content
    Widget? content;

    if (item.type == SavedItemType.course) {
      final courseAsync = ref.watch(courseDetailProvider(item.targetId));
      content = courseAsync.when(
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => Text(
          l10n.errorLoadingFormations,
          style: TextStyle(color: Colors.red[700], fontSize: 12),
        ),
        data: (course) {
          if (course == null) {
            return Text(
              l10n.errorLoadingFormations,
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            );
          }

          return _SavedCourseCard(course: course, savedItemId: item.id);
        },
      );
    } else if (item.type == SavedItemType.lesson) {
      if (item.courseId == null) {
        content = Text(
          l10n.errorLoadingFormations,
          style: TextStyle(color: Colors.red[700], fontSize: 12),
        );
      } else {
        final courseAsync = ref.watch(courseDetailProvider(item.courseId!));
        final lessonsAsync = ref.watch(courseLessonsProvider(item.courseId!));

        content = courseAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => Text(
            l10n.errorLoadingFormations,
            style: TextStyle(color: Colors.red[700], fontSize: 12),
          ),
          data: (course) {
            if (course == null) {
              return Text(
                l10n.errorLoadingFormations,
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              );
            }

            return lessonsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => Text(
                l10n.errorLoadingFormations,
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
              data: (lessons) {
                final lesson = lessons.firstWhere(
                  (l) => l.id == item.targetId,
                  orElse: () => lessons.first,
                );

                return _SavedLessonCard(
                  course: course,
                  lesson: lesson,
                  savedItemId: item.id,
                );
              },
            );
          },
        );
      }
    }

    return content ?? const SizedBox.shrink();
  }
}

class _SavedCourseCard extends ConsumerWidget {
  const _SavedCourseCard({
    required this.course,
    required this.savedItemId,
  });

  final Course course;
  final String savedItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final content = CourseContentResolver.resolve(course, locale);
    final title = content.title;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          context.push('/training/course/${course.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Formation',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark, size: 20),
                color: AppTheme.accentGold,
                onPressed: () async {
                  final notifier = ref.read(savedFormationsNotifierProvider);
                  await notifier.removeSavedItem(
                    type: SavedItemType.course,
                    targetId: course.id,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedLessonCard extends ConsumerWidget {
  const _SavedLessonCard({
    required this.course,
    required this.lesson,
    required this.savedItemId,
  });

  final Course course;
  final Lesson lesson;
  final String savedItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final courseContent = CourseContentResolver.resolve(course, locale);
    final lessonContent = LessonContentResolver.resolve(lesson, locale);
    final courseTitle = courseContent.title;
    final lessonTitle = lessonContent.title;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          context.push('/training/course/${course.id}/lesson/${lesson.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lessonTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      courseTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark, size: 20),
                color: AppTheme.accentGold,
                onPressed: () async {
                  final notifier = ref.read(savedFormationsNotifierProvider);
                  await notifier.removeSavedItem(
                    type: SavedItemType.lesson,
                    targetId: lesson.id,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. PILLAR FILTER
// ═════════════════════════════════════════════════════════════════════════════

class _PillarFilter extends StatelessWidget {
  const _PillarFilter({
    required this.selectedPillar,
    required this.onPillarSelected,
  });

  final PedagogicalPillar? selectedPillar;
  final ValueChanged<PedagogicalPillar?> onPillarSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _PillarChip(
          label: l10n.all,
          isSelected: selectedPillar == null,
          onTap: () => onPillarSelected(null),
        ),
        const SizedBox(width: 8),
        ...PedagogicalPillar.values.map((pillar) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _PillarChip(
              label: CoursePresentationLabels.pillar(
                pillar,
                AppLocalizations.of(context)!,
              ),
              isSelected: selectedPillar == pillar,
              onTap: () => onPillarSelected(pillar),
            ),
          );
        }),
        const SizedBox(width: 12), // Right padding
      ],
    );
  }
}

class _PillarChip extends StatelessWidget {
  const _PillarChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COMPACT PILLAR GRID (Hub Landing)
// ═════════════════════════════════════════════════════════════════════════════

// ═════════════════════════════════════════════════════════════════════════════
// MODULE PREVIEW WIDGET
// ═════════════════════════════════════════════════════════════════════════════

class _ModulePreview extends ConsumerWidget {
  const _ModulePreview({required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(courseModulesProvider(courseId));
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    return modulesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => FormationsFailureView(
        error: error,
        onRetry: () => ref.invalidate(courseModulesProvider(courseId)),
      ),
      data: (modules) {
        if (modules.isEmpty) return const SizedBox.shrink();

        final visibleModules = modules.take(3).toList();
        final remainingCount = modules.length > 3 ? modules.length - 3 : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...visibleModules.map((module) {
              final resolved = ModuleContentResolver.resolve(module, locale);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resolved.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          height: 1.3,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (remainingCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+ $remainingCount autres modules',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 4. FEATURED COURSE CARD
// ═════════════════════════════════════════════════════════════════════════════

class _FeaturedCourseCard extends ConsumerWidget {
  const _FeaturedCourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(courseProgressProvider(course.id));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push(
              '/formations/${course.id}',
              extra: {'course': course},
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Decorative color block
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.15),
                      AppTheme.primaryGreen.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              course.localizedPillarOrCategory(context),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            course.localizedLevel(context),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.localizedTitle(context),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      course.localizedDescription(context),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    _ModulePreview(courseId: course.id),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 18,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${course.totalLessons} leçons',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: AppTheme.primaryGreen,
                        ),
                      ],
                    ),

                    // Progress if exists
                    progressAsync.when(
                      data: (progress) {
                        if (progress == null ||
                            progress.completedLessonIds.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final percent =
                            progress.progressPercent(course.totalLessons);
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation(
                                    AppTheme.primaryGreen,
                                  ),
                                  minHeight: 5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${(percent * 100).toInt()}% complété',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 5. PREMIUM LIVE CARD
// ═════════════════════════════════════════════════════════════════════════════

class _LiveCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(
        minHeight: 200,
        maxHeight: 230,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC91F35).withValues(alpha: 0.25),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // ═══ LAYERED GRADIENT BACKGROUND ═══
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.4, 0.85, 1.0],
                    colors: [
                      Color(0xFF8F1020), // Deep ruby
                      Color(0xFFC91F35), // Rich red
                      Color(0xFFE84455), // Warm coral
                      Color(0xFFE84455),
                    ],
                  ),
                ),
              ),
            ),

            // ═══ SOFT IVORY GLOW (Right) ═══
            Positioned(
              right: -60,
              top: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFF9F2).withValues(alpha: 0.25),
                      const Color(0xFFF8D9DD).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ═══ PREMIUM PLAY SYMBOL (Right) ═══
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: CustomPaint(
                  size: const Size(80, 80),
                  painter: _PremiumPlayPainter(),
                ),
              ),
            ),

            // ═══ BROADCAST WAVES (Near Play) ═══
            Positioned(
              right: 16,
              bottom: 40,
              child: Opacity(
                opacity: 0.35,
                child: CustomPaint(
                  size: const Size(48, 48),
                  painter: _BroadcastWavesPainter(),
                ),
              ),
            ),

            // ═══ DECORATIVE TONAL RINGS ═══
            Positioned(
              right: -20,
              top: 30,
              child: Opacity(
                opacity: 0.08,
                child: CustomPaint(
                  size: const Size(140, 140),
                  painter: _TonalRingsPainter(),
                ),
              ),
            ),

            // ═══ MAIN CONTENT (Left) ═══
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ═══ STATUS LABEL ═══
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9F2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFF9F2).withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'EN DIRECT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFFFF9F2),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 11),

                    // ═══ TITLE ═══
                    Text(
                      l10n.liveSessionsCardTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFFF9F2),
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 7),

                    // ═══ DESCRIPTION ═══
                    Flexible(
                      child: Text(
                        l10n.liveSessionsDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFFFF9F2).withValues(alpha: 0.95),
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // ═══ SECONDARY TEXT ═══
                    Flexible(
                      child: Text(
                        l10n.liveSessionsSecondary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFFFF9F2).withValues(alpha: 0.75),
                          height: 1.3,
                          fontSize: 11.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const Spacer(),

                    // ═══ STATUS CAPSULE ═══
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.accentGold.withValues(alpha: 0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        l10n.upcoming.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF8F1020),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══ PREMIUM PLAY PAINTER ═══
class _PremiumPlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer gold ring
    final goldRingPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, goldRingPaint);

    // Main ivory circle
    final circlePaint = Paint()
      ..color = const Color(0xFFFFF9F2).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 3, circlePaint);

    // Subtle inner shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF8F1020).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 3, shadowPaint);

    // Red play triangle
    final trianglePaint = Paint()
      ..color = const Color(0xFFC91F35)
      ..style = PaintingStyle.fill;

    final trianglePath = Path();
    final triangleSize = radius * 0.5;
    trianglePath.moveTo(center.dx - triangleSize * 0.3, center.dy - triangleSize * 0.8);
    trianglePath.lineTo(center.dx - triangleSize * 0.3, center.dy + triangleSize * 0.8);
    trianglePath.lineTo(center.dx + triangleSize * 0.9, center.dy);
    trianglePath.close();
    canvas.drawPath(trianglePath, trianglePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══ BROADCAST WAVES PAINTER ═══
class _BroadcastWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFF9F2).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final center = Offset(0, size.height / 2);

    // Draw 3 concentric broadcast arcs
    for (int i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: i * 12.0),
        -3.14 / 2.8,
        3.14 / 1.4,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══ TONAL RINGS PAINTER ═══
class _TonalRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFFFF9F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw 4 concentric rings
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, i * 30.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// 5. QUESTIONS CARD
// ═════════════════════════════════════════════════════════════════════════════

class _QuestionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.primaryGreen.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.forum,
                  color: AppTheme.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    l10n.comingSoon,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.accentGold.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.questionsTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryGreen,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.questionsDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[800],
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CapabilityPill(
                icon: Icons.lock_outline,
                label: l10n.privateQuestion,
              ),
              _CapabilityPill(
                icon: Icons.public,
                label: l10n.publicAnswers,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapabilityPill extends StatelessWidget {
  const _CapabilityPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 6. COMPACT COURSE CARD (All Formations)
// ═════════════════════════════════════════════════════════════════════════════

class _CompactCourseCard extends ConsumerWidget {
  const _CompactCourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(courseProgressProvider(course.id));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push(
              '/formations/${course.id}',
              extra: {'course': course},
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left accent
                Container(
                  width: 4,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.localizedPillarOrCategory(context),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            course.localizedLevel(context),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppTheme.primaryGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.localizedTitle(context),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _ModulePreview(courseId: course.id),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${course.totalLessons} leçons',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      // Progress if exists
                      progressAsync.when(
                        data: (progress) {
                          if (progress == null ||
                              progress.completedLessonIds.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final percent =
                              progress.progressPercent(course.totalLessons);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation(
                                        AppTheme.primaryGreen,
                                      ),
                                      minHeight: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(percent * 100).toInt()}%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOADING / EMPTY / ERROR STATES
// ═════════════════════════════════════════════════════════════════════════════

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 48,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noFormationsAvailable,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
