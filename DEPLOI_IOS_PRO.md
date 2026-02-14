# Déploiement iOS – Méthode professionnelle ANIS Khatamat

## Changement majeur (février 2025)

**Avant :** `flutter build ipa` → IPA sans SwiftSupport → erreurs 90426 et 90725

**Maintenant :** `xcode-project build-ipa` → archive + export natifs Xcode → IPA conforme Apple

---

## Pourquoi cette approche ?

| Problème | Solution |
|----------|----------|
| SwiftSupport manquant (90426) | `xcode-project build-ipa` utilise `xcodebuild -exportArchive` qui génère un IPA correct |
| Provisioning profile | `use-profiles` + `build-ipa` gèrent ensemble le signing |
| Méthode recommandée | Approche officielle Codemagic pour les apps iOS natives |

---

## Workflow actuel

1. **Flutter pub get** – dépendances Dart
2. **pod install** – dépendances iOS (CocoaPods)
3. **xcode-project use-profiles** – configuration du signing
4. **xcode-project build-ipa** – archive Xcode + export IPA

---

## Publication automatique TestFlight (optionnel)

Pour envoyer automatiquement sur TestFlight après le build :

1. **App Store Connect** → Users and Access → Integrations → App Store Connect API  
   - Créer une clé API (App Manager)  
   - Télécharger le fichier .p8 (une seule fois)

2. **Codemagic** → Team settings → Developer Portal  
   - Ajouter la clé API (Issuer ID, Key ID, fichier .p8)  
   - Donner un nom à l’intégration (ex. `app_store_connect`)

3. **codemagic.yaml** – décommenter :
   ```yaml
   integrations:
     app_store_connect: NOM_DE_VOTRE_INTEGRATION
   publishing:
     app_store_connect:
       auth: integration
       submit_to_testflight: true
   ```

---

## Publication manuelle (Transporter)

Si la publication automatique n’est pas configurée :

1. Télécharger les artefacts Codemagic
2. Extraire le ZIP
3. Lancer : `./scripts/prepare_ios_release.sh ~/Downloads`
4. Envoyer `Runner.ipa` via Transporter

---

## Références

- [Codemagic – App iOS native](https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/)
- [Codemagic – App Store Connect](https://docs.codemagic.io/yaml-publishing/app-store-connect/)
