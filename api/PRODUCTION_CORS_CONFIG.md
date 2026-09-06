# Production CORS Configuration Guide

## Overview
The ANIS REST API uses environment-driven CORS configuration to support multi-platform deployment:
- **iOS/Android**: Native apps are NOT restricted by CORS (no origin header)
- **Flutter Web**: Restricted by browser CORS policy
- **Future Backoffice**: Will require explicit origin allowlist

## Environment Variable

**`ALLOWED_ORIGINS`**: Comma-separated list of allowed web origins

### Development (Default)
```bash
# api/.env
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5000,http://127.0.0.1:3000
```

### Production (Infomaniak Deployment)

**Required Configuration**:
```bash
# Infomaniak environment variables
NODE_ENV=production
PORT=<assigned-by-infomaniak>
FIREBASE_PROJECT_ID=anis-437c3
ALLOWED_ORIGINS=https://anis-khatamat.com,https://www.anis-khatamat.com,https://anis-khatamat.web.app

# Firebase Admin Credentials (secure, outside Git)
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

**Expected Production Origins**:
1. `https://anis-khatamat.com` - Primary custom domain
2. `https://www.anis-khatamat.com` - WWW variant
3. `https://anis-khatamat.web.app` - Firebase Hosting default domain (if used)

**Future Expansion** (when Backoffice is deployed):
4. `https://admin.anis-khatamat.com` - Admin panel (add only when live)

## Security Constraints

✅ **Enforced**:
- NO wildcard `*` origin in production
- Explicit origin allowlist ONLY
- `credentials: false` (using Bearer tokens, not cookies)
- Authorization header allowed in preflight
- Mobile apps (no origin) always allowed

❌ **Forbidden**:
- `Access-Control-Allow-Origin: *`
- `credentials: true` (no cookie-based auth)
- Allowing unknown origins at runtime

## Testing CORS Locally

### 1. Test Allowed Origin
```bash
curl -i -X OPTIONS http://localhost:3000/v1/khatmat \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Authorization, Content-Type"
```

**Expected**:
```
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: http://localhost:3000
Access-Control-Allow-Methods: GET,POST,OPTIONS
Access-Control-Allow-Headers: Content-Type,Authorization,X-Request-Id
```

### 2. Test Forbidden Origin
```bash
curl -i -X OPTIONS http://localhost:3000/v1/khatmat \
  -H "Origin: https://evil.com" \
  -H "Access-Control-Request-Method: POST"
```

**Expected**:
```
HTTP/1.1 204 No Content
(NO Access-Control-Allow-Origin header)
```

### 3. Test Mobile App (No Origin)
```bash
curl -i http://localhost:3000/health
```

**Expected**:
```
HTTP/1.1 200 OK
{"status":"healthy","timestamp":"..."}
```

## Infomaniak Deployment Checklist

- [ ] Set `NODE_ENV=production`
- [ ] Set `ALLOWED_ORIGINS` with production domains (comma-separated, no spaces)
- [ ] Set `FIREBASE_PROJECT_ID=anis-437c3`
- [ ] Upload Firebase service account JSON (secure location, NOT in Git)
- [ ] Set `GOOGLE_APPLICATION_CREDENTIALS` path to service account
- [ ] Verify DNS for `anis-khatamat.com` points to Infomaniak
- [ ] Test preflight from Flutter Web production build
- [ ] Verify iOS/Android apps work (no CORS restriction)

## Troubleshooting

### Symptom: Flutter Web gets CORS error in production
**Cause**: Origin not in `ALLOWED_ORIGINS`  
**Fix**: Add exact production URL to `ALLOWED_ORIGINS` (check protocol, subdomain, port)

### Symptom: iOS/Android apps fail
**Cause**: NOT a CORS issue (native apps bypass CORS)  
**Fix**: Check Firebase Auth token, network connectivity, API URL configuration

### Symptom: Preflight fails with 404
**Cause**: API route not handling OPTIONS  
**Fix**: CORS middleware already handles OPTIONS globally - check route path

## Code References

- **CORS Middleware**: `api/src/middleware/cors.ts`
- **Environment Config**: `api/src/config/environment.ts`
- **CORS Tests**: `api/test/cors.test.ts`
- **Flutter API Config**: `lib/core/config/api_config.dart`
