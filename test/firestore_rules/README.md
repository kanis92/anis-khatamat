# Tests Firestore Rules — Khatamat P0

Infrastructure minimale pour valider `firestore.rules` via l’émulateur Firebase.

## Prérequis

- Node.js 18+
- **JDK 21+** (requis par firebase-tools récent)
- `firebase-tools` : `npm install -g firebase-tools`

Sur macOS avec Homebrew :

```bash
brew install openjdk@21
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
```

## Installation

```bash
cd test/firestore_rules
npm install
```

## Lancer les tests

Depuis `test/firestore_rules` :

```bash
npm test
```

Ou depuis la racine du repo :

```bash
firebase emulators:exec --only firestore,auth "cd test/firestore_rules && node khatmat_rules.test.js"
```

## Couverture

Les scénarios couvrent les cas P0 listés dans le sprint (creator, membre, invité, outsider, delete).

**Non testable sans émulateur actif** : concurrence réelle (test 8) — couverte côté Dart par simulation logique dans `test/reservation_service_test.dart`.
