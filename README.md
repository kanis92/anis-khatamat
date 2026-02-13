# ANIS Khatamat

Application mobile de lecture du Coran et gestion des Khatmat (Flutter - Android/iOS).

## Technologies

- **Flutter** – Framework multi-plateforme
- **Firebase** – Authentification, Firestore
- **Riverpod** – Gestion d'état
- **Go Router** – Navigation déclarative
- **Material 3** – Interface moderne

## Prérequis

- Flutter SDK 3.7+
- Compte Firebase (pour Auth/Firestore)

## Installation

```bash
# 1. Cloner et entrer dans le projet
cd anis_khatamat

# 2. Installer les dépendances
flutter pub get

# 3. Configurer Firebase (optionnel mais recommandé)
flutterfire configure
```

## Configuration Firebase

1. Créez un projet sur [Firebase Console](https://console.firebase.google.com)
2. Activez **Authentication** (Email/Password, Google)
3. Activez **Cloud Firestore**
4. Exécutez `flutterfire configure` pour générer les fichiers de config

## Lancement

```bash
# Android
flutter run

# iOS
flutter run
```

## Structure du projet

```
lib/
├── app/           # Configuration app, router, thème
├── core/          # Constantes, thème, providers
├── screens/       # Écrans de l'application
└── l10n/          # Fichiers de traduction (FR, EN, AR)
```

## Fonctionnalités (en cours)

- [x] Authentification (email, inscription)
- [x] Navigation avec barre d'onglets
- [x] Écran d'accueil
- [x] Création de Khatma (individuelle/groupe)
- [x] Paramètres (notifications, langue, thème)
- [x] Notifications
- [x] Gestion des ateliers de formation
- [ ] Mushaf électronique (Hafs, Warsh)
- [ ] Distribution des 60 Hizb
- [ ] Partage WhatsApp
- [ ] Mode hors ligne
- [ ] Authentification biométrique

## Licence

Projet privé.
