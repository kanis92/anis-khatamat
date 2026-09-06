# ANIS API

Multi-platform REST API for ANIS Khatamat application.

## Architecture

```
iOS + Android + Web + Backoffice
          │
          ▼
    ANIS REST API (this project)
          │
          ▼
    Firebase Admin SDK
          │
          ▼
    Cloud Firestore
```

## Technology Stack

- **Runtime**: Node.js 18+
- **Language**: TypeScript
- **Framework**: Express.js
- **Authentication**: Firebase Admin SDK (ID token verification)
- **Database**: Cloud Firestore (via Firebase Admin)
- **Testing**: Jest + Supertest

## Project Structure

```
api/
├── src/
│   ├── server.ts           # Entry point
│   ├── app.ts              # Express app setup
│   ├── config/
│   │   └── environment.ts  # Environment configuration
│   ├── errors/
│   │   └── api-error.ts    # API error contract
│   ├── firebase/
│   │   └── admin.ts        # Firebase Admin initialization
│   ├── middleware/
│   │   ├── auth.ts         # Firebase token verification
│   │   ├── cors.ts         # CORS for multi-platform
│   │   ├── error-handler.ts
│   │   ├── rate-limit.ts
│   │   ├── request-id.ts
│   │   └── request-logger.ts
│   ├── routes/
│   │   └── health.ts       # Health check endpoint
│   └── utils/
│       └── logger.ts       # Structured logging
├── test/                   # Jest tests
└── lib/                    # Compiled JavaScript (git-ignored)
```

## Setup

### 1. Install Dependencies

```bash
cd api
npm ci
```

### 2. Environment Configuration

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
NODE_ENV=development
PORT=8080
FIREBASE_PROJECT_ID=anis-437c3
ALLOWED_ORIGINS=http://localhost:3000
```

### 3. Firebase Admin Credentials

**Development/Test**: Use Firebase Emulators (no credentials needed)

```bash
# In separate terminal
firebase emulators:start --only auth,firestore
```

**Production**: Use one of:

- **Option 1**: Application Default Credentials (recommended for Cloud Run/GCE)
- **Option 2**: Service Account JSON (set `GOOGLE_APPLICATION_CREDENTIALS`)

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

⚠️ **NEVER commit service-account JSON files to Git**

## Development

### Build

```bash
npm run build
```

### Run

```bash
npm start
# Or for development with auto-reload:
npm run dev
```

### Test

```bash
npm test
```

### Lint

```bash
npm run lint
```

## API Endpoints

### Health Check

```http
GET /health
```

**Response**:

```json
{
  "status": "ok",
  "service": "anis-api"
}
```

### Protected Endpoints (coming in STEP 2B)

All protected endpoints require Firebase ID token:

```http
Authorization: Bearer <Firebase-ID-Token>
```

## Error Contract

All API errors return stable JSON structure:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable message"
  }
}
```

**Error Codes**:

- `AUTH_REQUIRED` (401) - Missing Authorization header
- `AUTH_INVALID` (401) - Invalid/expired token
- `FORBIDDEN` (403) - Authenticated but not authorized
- `INVALID_ARGUMENT` (400) - Invalid request data
- `NOT_FOUND` (404) - Resource not found
- `CONFLICT` (409) - Resource conflict (e.g., duplicate reservation)
- `RATE_LIMITED` (429) - Too many requests
- `INTERNAL` (500) - Internal server error

## Security

- ✅ HTTPS required in production
- ✅ Firebase ID token verification
- ✅ Request validation
- ✅ Body size limits (1MB default)
- ✅ Rate limiting
- ✅ Security headers (helmet)
- ✅ Structured logging (no tokens/passwords logged)
- ✅ Request IDs for tracing
- ✅ CORS for web clients
- ✅ No stack traces exposed to clients

## CORS Configuration

**iOS/Android**: Native apps are NOT restricted by CORS (no Origin header)

**Flutter Web + Backoffice**: Restricted by browser CORS policy

Allowed origins configured via `ALLOWED_ORIGINS` environment variable.

**Production Example**:

```
ALLOWED_ORIGINS=https://anis-khatamat.com,https://www.anis-khatamat.com,https://admin.anis-khatamat.com
```

## Deployment

Target: **Infomaniak Managed Cloud**

Production domain: `https://api.anis-khatamat.com`

Deployment instructions coming in STEP 2C.

## Testing

Test coverage:

- ✅ Health endpoint
- ✅ 404 handling
- ✅ Auth middleware (missing/malformed/invalid/valid tokens)
- ✅ CORS (allowed/forbidden origins)
- ✅ Error contract (stable structure, no stack traces)
- ✅ Request IDs
- ✅ Body size limits

Run tests:

```bash
npm test
```

## License

UNLICENSED - Private project
