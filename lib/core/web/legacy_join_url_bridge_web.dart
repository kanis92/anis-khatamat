import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Remplace l'entrée d'historique pour retirer un fragment `#/join/...` legacy.
void stripLegacyJoinFragment(String canonicalPath) {
  final href = web.window.location.href;
  final uri = Uri.parse(href);
  if (!uri.fragment.contains('join')) return;
  web.window.history.replaceState(null, '', canonicalPath);
}

void listenLegacyJoinHashChanges(void Function() onChanged) {
  void handler(web.Event _) => onChanged();
  web.window.addEventListener('hashchange', handler.toJS);
}
