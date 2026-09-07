import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/anis_api_client.dart';

final apiClientProvider = Provider<AnisApiClient>((ref) {
  return AnisApiClient();
});
