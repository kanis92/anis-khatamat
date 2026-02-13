# Publication ANIS Khatamat sur l'App Store

Guide pour publier l'app et corriger progressivement.

---

## 1. Avant de publier

### Comptes requis
- **iOS** : Compte Apple Developer (99 €/an) — [developer.apple.com](https://developer.apple.com)
- **Android** : Compte Google Play (25 $ une fois) — [play.google.com/console](https://play.google.com/console)

### À configurer
- [ ] **Identifiant d'app** : `com.aniskhatamat.app` (ou votre domaine)
- [ ] **Politique de confidentialité** : URL réelle (obligatoire)
- [ ] **Icône** : 1024×1024 px pour iOS
- [ ] **Captures d'écran** : iPhone 6.7", 6.5", 5.5" (iOS)

---

## 2. Publication sur l'App Store (iOS)

### Étape 1 : Compte Apple Developer
1. Inscrivez-vous sur [developer.apple.com](https://developer.apple.com)
2. Activez le programme (99 €/an)

### Étape 2 : Xcode
1. Ouvrez `ios/Runner.xcworkspace` dans Xcode
2. Sélectionnez le projet **Runner** → **Signing & Capabilities**
3. Choisissez votre **Team** (compte développeur)
4. Vérifiez le **Bundle ID** : `com.aniskhatamat.app`

### Étape 3 : Build de release
```bash
cd /Users/jaouad/Desktop/KHATAMAT/anis_khatamat
flutter build ios --release
```

### Étape 4 : App Store Connect
1. Allez sur [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **Mes apps** → **+** → **Nouvelle app**
3. Renseignez : nom, langue, Bundle ID, SKU
4. **Informations sur l'app** : description, catégorie (Lifestyle ou Reference), âge
5. **Captures d'écran** : ajoutez des captures des écrans principaux
6. **Politique de confidentialité** : URL obligatoire

### Étape 5 : Envoi via Xcode
1. Dans Xcode : **Product** → **Archive**
2. **Distribute App** → **App Store Connect** → **Upload**
3. Dans App Store Connect : **Soumettre pour examen**

---

## 3. Publication sur Google Play (Android)

### Étape 1 : Clé de signature
```bash
cd android
keytool -genkey -v -keystore upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias anis-khatamat
```

### Étape 2 : Configurer la signature
Créez `android/key.properties` (ne pas commiter) :
```properties
storePassword=VOTRE_MOT_DE_PASSE
keyPassword=VOTRE_MOT_DE_PASSE
keyAlias=anis-khatamat
storeFile=upload-key.jks
```
Le fichier `build.gradle.kts` est déjà configuré pour utiliser cette clé automatiquement.

### Étape 3 : Build
```bash
flutter build appbundle --release
```

### Étape 4 : Google Play Console
1. Créez l'app sur [play.google.com/console](https://play.google.com/console)
2. **Fiche Store** : description, captures, icône
3. **Contenu** : politique de confidentialité
4. **Production** → **Créer une version** → uploadez le `.aab`

---

## 4. Corriger petit à petit

### Stratégie de mise à jour
1. **Version 1.0.0** : publiez une première version fonctionnelle
2. **Mises à jour** : corrigez les bugs et améliorez par petits pas
3. **Numérotation** : `1.0.1` (correctifs), `1.1.0` (nouvelles fonctionnalités)

### Modifier la version
Dans `pubspec.yaml` :
```yaml
version: 1.0.1+2   # 1.0.1 = version affichée, 2 = build number
```

### Envoyer une mise à jour
```bash
# iOS
flutter build ios --release
# Puis Archive dans Xcode

# Android
flutter build appbundle --release
# Puis uploader le nouveau .aab sur Google Play
```

---

## 5. Checklist avant soumission

- [ ] Politique de confidentialité en ligne
- [ ] URL de politique mise à jour dans `app_constants.dart`
- [ ] Application ID unique (pas `com.example`)
- [ ] Icône 1024×1024 (iOS)
- [ ] Captures d'écran pour chaque taille
- [ ] Description en français (et anglais si possible)
- [ ] Catégorie : Lifestyle ou Reference

---

## 6. Délais habituels

- **App Store** : examen de 24 à 48 h en général
- **Google Play** : examen de quelques heures à 1–2 jours

---

## 7. En cas de rejet

- Lisez attentivement le message d’Apple/Google
- Corrigez les points signalés
- Incrémentez le numéro de build (`+1`)
- Resoumettez l’app

Bonne publication.
