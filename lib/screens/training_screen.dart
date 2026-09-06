import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/extensions/l10n_extensions.dart';
import '../core/theme/app_theme.dart';
import '../features/formations/presentation/course_presentation.dart';
import '../features/formations/providers/formations_providers.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final coursesAsync = ref.watch(publishedCoursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.formations),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.myTraining,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox.shrink(),
              data: (courses) {
                if (courses.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    for (final course in courses)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.school,
                            color: AppTheme.primaryGreen,
                          ),
                          title: Text(course.localizedTitle(context)),
                          subtitle: Text(
                            course.localizedDescription(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(course.localizedLevel(context)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
