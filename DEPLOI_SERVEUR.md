# Déployer ANIS Khatamat sur un serveur

## Option 1 : Serveur local (aperçu rapide)

```bash
# Rendez le script exécutable
chmod +x scripts/serve_web.sh

# Construire et lancer le serveur
./scripts/serve_web.sh
```

Ouvrez **http://localhost:8080** dans votre navigateur.

---

## Option 2 : Firebase Hosting (serveur en ligne gratuit)

Votre projet utilise déjà Firebase. Vous pouvez héberger l'app gratuitement :

### 1. Installer Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Se connecter et initialiser

```bash
firebase login
firebase init hosting
# Choisir "Use an existing project" → votre projet Firebase
# Public directory: build/web
# Single-page app: Yes
```

### 3. Déployer

```bash
# Construire l'app
flutter build web --release

# Déployer
firebase deploy
```

Vous obtiendrez une URL comme : **https://votre-projet.web.app**

---

## Option 3 : Vercel / Netlify

Pour déployer sur Vercel ou Netlify :

1. **Build command** : `flutter build web --release`
2. **Output directory** : `build/web`

*(Vercel/Netlify nécessitent Flutter dans l'environnement de build)*

---

## Prérequis

- **Flutter** doit être installé et dans le PATH
- Si vous utilisez FVM : `fvm flutter build web --release`
