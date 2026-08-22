import 'khatma.dart';

enum KhatmaLoadFailure {
  notFound,
  accessDenied,
  network,
}

/// Résultat explicite du chargement d'une Khatma par ID (navigation / deep links).
class KhatmaLoadResult {
  final Khatma? khatma;
  final KhatmaLoadFailure? failure;

  const KhatmaLoadResult._({this.khatma, this.failure});

  const KhatmaLoadResult.data(Khatma khatma)
      : this._(khatma: khatma, failure: null);

  const KhatmaLoadResult.failure(KhatmaLoadFailure reason)
      : this._(khatma: null, failure: reason);

  bool get isSuccess => khatma != null && failure == null;
}

class KhatmaNotFoundException implements Exception {
  final String khatmaId;
  const KhatmaNotFoundException(this.khatmaId);
}

class KhatmaAccessDeniedException implements Exception {
  final String khatmaId;
  const KhatmaAccessDeniedException(this.khatmaId);
}

class KhatmaNetworkException implements Exception {
  final String khatmaId;
  const KhatmaNetworkException(this.khatmaId);
}
