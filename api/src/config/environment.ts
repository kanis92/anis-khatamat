/**
 * Environment configuration with validation
 * Fail fast if required configuration is missing in production
 */

export interface EnvironmentConfig {
  nodeEnv: 'development' | 'test' | 'production';
  port: number;
  firebaseProjectId: string;
  allowedOrigins: string[];
  rateLimitWindowMs: number;
  rateLimitMaxRequests: number;
  bodyLimitBytes: number;
}

function parseAllowedOrigins(originsEnv: string | undefined): string[] {
  if (!originsEnv || originsEnv.trim().length === 0) {
    // Default for development
    return [
      'http://localhost:3000',
      'http://localhost:5000',
      'http://127.0.0.1:3000',
    ];
  }
  return originsEnv.split(',').map(o => o.trim()).filter(o => o.length > 0);
}

function getRequiredEnv(key: string, defaultValue?: string): string {
  const value = process.env[key] || defaultValue;
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

function getOptionalEnv(key: string, defaultValue: string): string {
  return process.env[key] || defaultValue;
}

export function loadEnvironment(): EnvironmentConfig {
  const nodeEnv = getOptionalEnv('NODE_ENV', 'development') as EnvironmentConfig['nodeEnv'];
  
  // In test mode, use minimal config
  if (nodeEnv === 'test') {
    return {
      nodeEnv: 'test',
      port: 0, // Random port for tests
      firebaseProjectId: getOptionalEnv('FIREBASE_PROJECT_ID', 'anis-437c3'), // Match emulator project
      allowedOrigins: ['http://localhost:3000'],
      rateLimitWindowMs: 60000,
      rateLimitMaxRequests: 100,
      bodyLimitBytes: 1024 * 1024, // 1MB
    };
  }

  // Production requires explicit Firebase project
  const firebaseProjectId = nodeEnv === 'production'
    ? getRequiredEnv('FIREBASE_PROJECT_ID')
    : getOptionalEnv('FIREBASE_PROJECT_ID', 'anis-437c3');

  const config: EnvironmentConfig = {
    nodeEnv,
    port: parseInt(getOptionalEnv('PORT', '8080'), 10),
    firebaseProjectId,
    allowedOrigins: parseAllowedOrigins(process.env.ALLOWED_ORIGINS),
    rateLimitWindowMs: parseInt(getOptionalEnv('RATE_LIMIT_WINDOW_MS', '60000'), 10),
    rateLimitMaxRequests: parseInt(getOptionalEnv('RATE_LIMIT_MAX_REQUESTS', '100'), 10),
    bodyLimitBytes: parseInt(getOptionalEnv('BODY_LIMIT_BYTES', String(1024 * 1024)), 10),
  };

  // Validate configuration
  if (config.port < 0 || config.port > 65535) {
    throw new Error(`Invalid PORT: ${config.port}`);
  }

  if (config.bodyLimitBytes < 1024 || config.bodyLimitBytes > 10 * 1024 * 1024) {
    throw new Error(`Invalid BODY_LIMIT_BYTES: ${config.bodyLimitBytes} (must be 1KB-10MB)`);
  }

  return config;
}

// Singleton instance
let envConfig: EnvironmentConfig | null = null;

export function getEnvironment(): EnvironmentConfig {
  if (!envConfig) {
    envConfig = loadEnvironment();
  }
  return envConfig;
}

/**
 * Reset environment cache (for testing)
 */
export function resetEnvironment(): void {
  envConfig = null;
}
