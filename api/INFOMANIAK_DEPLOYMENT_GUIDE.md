# Infomaniak Managed Cloud Deployment Guide

## Overview
The ANIS REST API is designed to run on **Infomaniak Managed Cloud** (Node.js hosting), replacing Firebase Cloud Functions to avoid vendor lock-in and Blaze plan requirements.

## Production Architecture

```
┌─────────────────┐
│  Flutter Apps   │
│ iOS/Android/Web │
└────────┬────────┘
         │ HTTPS + Firebase ID Token
         ▼
┌─────────────────────────────────────┐
│   Infomaniak Managed Cloud          │
│   ─────────────────────────         │
│   ANIS REST API (Node.js/Express)   │
│   Port: <Infomaniak-assigned>       │
│   Domain: api.anis-khatamat.com     │
└────────┬────────────────────────────┘
         │ Firebase Admin SDK
         ▼
┌─────────────────────────────────────┐
│   Firebase (Google Cloud)           │
│   ─────────────────────────         │
│   • Firestore Database              │
│   • Firebase Authentication         │
│   • Firebase Hosting (Flutter Web)  │
└─────────────────────────────────────┘
```

## Required Environment Variables

### 1. Node.js Runtime
```bash
NODE_ENV=production
```
- **Purpose**: Enables production mode (strict validation, security hardening)
- **Values**: `development` | `test` | `production`

### 2. Server Port
```bash
PORT=<assigned-by-infomaniak>
```
- **Purpose**: HTTP server listening port
- **Default**: 3000 (development), must be overridden by Infomaniak
- **Note**: Infomaniak will assign this automatically

### 3. Firebase Project ID
```bash
FIREBASE_PROJECT_ID=anis-437c3
```
- **Purpose**: Firebase Admin SDK initialization
- **Value**: Must match deployed Firebase project
- **Critical**: Required for Firestore and Auth verification

### 4. CORS Allowed Origins
```bash
ALLOWED_ORIGINS=https://anis-khatamat.com,https://www.anis-khatamat.com,https://anis-khatamat.web.app
```
- **Purpose**: Multi-platform CORS policy
- **Format**: Comma-separated list (no spaces after commas)
- **Security**: NO wildcards (`*`) allowed in production

### 5. Firebase Admin Credentials (CRITICAL)

**Option A: Service Account JSON File (Recommended)**
```bash
GOOGLE_APPLICATION_CREDENTIALS=/path/to/anis-437c3-service-account.json
```

**Option B: Inline Service Account (Alternative)**
```bash
FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"anis-437c3",...}'
```

#### How to Obtain Service Account

1. **Firebase Console**: https://console.firebase.google.com/project/anis-437c3/settings/serviceaccounts
2. Click **"Generate New Private Key"**
3. Download JSON file (e.g., `anis-437c3-firebase-adminsdk-xyz.json`)
4. **NEVER commit to Git** - store securely on Infomaniak server

#### Infomaniak Upload Strategy

1. Upload service account JSON via Infomaniak file manager to secure location:
   ```
   /home/aniskhatamat/secrets/firebase-service-account.json
   ```

2. Set environment variable to absolute path:
   ```bash
   GOOGLE_APPLICATION_CREDENTIALS=/home/aniskhatamat/secrets/firebase-service-account.json
   ```

3. **Verify file permissions**: Read-only for Node.js process user
   ```bash
   chmod 600 /home/aniskhatamat/secrets/firebase-service-account.json
   ```

## Optional Environment Variables

### Rate Limiting
```bash
RATE_LIMIT_WINDOW_MS=60000          # 1 minute window (default)
RATE_LIMIT_MAX_REQUESTS=100         # 100 requests/min (default)
```

### Request Size Limit
```bash
BODY_LIMIT_BYTES=1048576            # 1MB (default)
```

## Deployment Steps

### 1. Pre-Deployment Verification (Local)
```bash
cd /Users/jaouad/Desktop/KHATAMAT/anis_merge_main/api

# Run all tests
npm run build
npm test

# Run E2E tests against emulators
bash scripts/run-e2e.sh

# Verify environment loading
node -e "require('./src/config/environment').getEnvironment()"
```

### 2. Prepare Deployment Package
```bash
# Build TypeScript to JavaScript
npm run build

# Create deployment archive (excluding dev files)
tar -czf anis-api-deploy.tar.gz \
  --exclude=node_modules \
  --exclude=.git \
  --exclude=test \
  --exclude=*.test.ts \
  src/ dist/ package.json package-lock.json
```

### 3. Infomaniak Upload
- Upload `anis-api-deploy.tar.gz` to Infomaniak via SFTP/FTP
- Extract in target directory
- Run `npm install --production` (installs only production dependencies)

### 4. Configure Environment Variables
Set in Infomaniak control panel:
```bash
NODE_ENV=production
PORT=<infomaniak-assigned>
FIREBASE_PROJECT_ID=anis-437c3
ALLOWED_ORIGINS=https://anis-khatamat.com,https://www.anis-khatamat.com,https://anis-khatamat.web.app
GOOGLE_APPLICATION_CREDENTIALS=/home/aniskhatamat/secrets/firebase-service-account.json
```

### 5. Start Node.js Application
```bash
node dist/server.js
```

Or use Infomaniak's process manager (PM2):
```bash
pm2 start dist/server.js --name anis-api
pm2 save
pm2 startup
```

### 6. Configure DNS
Point `api.anis-khatamat.com` to Infomaniak server IP:
```
A record: api.anis-khatamat.com → <infomaniak-ip>
```

### 7. SSL/TLS Certificate
Infomaniak provides Let's Encrypt SSL - enable for `api.anis-khatamat.com`

## Health Check

After deployment, verify:
```bash
curl https://api.anis-khatamat.com/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2026-09-06T22:00:00.000Z"
}
```

## Production Monitoring

### Essential Logs to Monitor
- **Authentication failures**: Check `logger.warn('Auth verification failed')`
- **CORS rejections**: Check `logger.warn('CORS origin rejected')`
- **Rate limit hits**: Check `logger.warn('Rate limit exceeded')`
- **Firestore errors**: Check `logger.error('createCollaborativeKhatma failed')`

### Health Endpoint
```bash
# Automated monitoring
*/5 * * * * curl -f https://api.anis-khatamat.com/health || alert
```

## Security Checklist

- [ ] `NODE_ENV=production` set
- [ ] Firebase service account JSON NOT in Git
- [ ] `GOOGLE_APPLICATION_CREDENTIALS` points to secure location
- [ ] File permissions: `chmod 600` on service account
- [ ] `ALLOWED_ORIGINS` has NO wildcard (`*`)
- [ ] Rate limiting enabled (default: 100 req/min)
- [ ] Body size limit set (default: 1MB)
- [ ] SSL/TLS certificate active for `api.anis-khatamat.com`
- [ ] DNS A record points to Infomaniak IP
- [ ] Firestore rules still enforced (server uses Admin SDK, but rules protect direct client access if misconfigured)

## Rollback Strategy

If deployment fails:
1. Keep Firebase Functions code as backup (committed at `f307c37`)
2. Revert Flutter app to use Firebase Callable Functions
3. Redeploy Functions: `firebase deploy --only functions`
4. Update Flutter `pubspec.yaml` to restore `cloud_functions` dependency

## Cost Comparison

### Firebase Cloud Functions (Blaze Plan)
- **Monthly**: ~$25-50 (100K invocations)
- **Vendor lock-in**: Yes
- **Cold starts**: 1-3 seconds

### Infomaniak Managed Cloud
- **Monthly**: ~€10-20 (estimated)
- **Vendor lock-in**: No
- **Cold starts**: None (always-on process)

## Support Contacts

- **Infomaniak Support**: https://www.infomaniak.com/en/support
- **Firebase Console**: https://console.firebase.google.com/project/anis-437c3
- **API Source Code**: `/api` directory in Git repo
