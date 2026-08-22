import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bookmark.dart';
import '../services/bookmark_service.dart';
import 'auth_provider.dart';

final bookmarkServiceProvider = Provider<BookmarkService>((ref) => BookmarkService());

final bookmarksProvider = FutureProvider<List<Bookmark>>((ref) async {
  final service = ref.watch(bookmarkServiceProvider);
  final user = ref.watch(currentUserProvider);
  final userId = user?.email ?? 'demo';
  return service.getBookmarks(userId);
});
