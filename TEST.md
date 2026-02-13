# Guide de test - ANIS Khatamat

## Lancer l'application

```bash
# 1. Aller dans le projet
cd /Users/jaouad/Desktop/KHATAMAT/anis_khatamat

# 2. Installer les dépendances
/Users/jaouad/development/flutter/bin/flutter pub get

# 3. Lancer sur Chrome (sans Firebase configuré → mode démo automatique)
/Users/jaouad/development/flutter/bin/flutter run -d chrome

# Ou sur iOS (si Xcode installé)
/Users/jaouad/development/flutter/bin/flutter run -d ios

# Ou sur Android (si émulateur ou appareil connecté)
/Users/jaouad/development/flutter/bin/flutter run -d android
```

## Mode démo (sans Firebase)

Quand Firebase n'est pas configuré (web, ou fichiers manquants), l'app démarre **directement sur l'accueil** en mode démo.

Sur l'écran de connexion, vous pouvez aussi cliquer sur **"Mode démo (tester sans connexion)"** pour accéder à l'app sans créer de compte.

## Scénarios de test

### 1. Accueil
- Vérifier l'affichage de la carte de bienvenue
- Tester les 4 boutons : Créer une Khatma, Accomplissements, Formation, Mushaf

### 2. Création de Khatma
- Onglet **Khatma** → **Créer une Khatma**
- Choisir **Individuelle** ou **Groupe**
- Remplir titre et objectifs
- (Groupe) Ajouter des emails de membres
- Cliquer **Suivant → Distribution des Hizb**

### 3. Distribution des Hizb
- Tester **Distribution auto** (répartition des 60 Hizb)
- Tester **Manuel** (bouton ✏️ sur chaque Hizb)
- Cliquer **Confirmer la distribution**

### 4. Accomplissements
- Accueil → **Accomplissements**
- Vérifier la carte visuelle
- Tester **Partager (WhatsApp, etc.)**

### 5. Navigation
- Vérifier les 5 onglets : Accueil, Khatma, Notifications, Formation, Paramètres

### 6. Paramètres
- Onglet **Paramètres**
- Tester **Déconnexion** (retour à l'écran de connexion)
