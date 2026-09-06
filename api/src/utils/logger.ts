/**
 * Simple structured logging
 * NEVER log tokens, passwords, private keys, or sensitive payloads
 */

type LogLevel = 'info' | 'warn' | 'error' | 'debug';

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  requestId?: string;
  message: string;
  [key: string]: unknown;
}

function log(level: LogLevel, message: string, meta?: Record<string, unknown>): void {
  const entry: LogEntry = {
    timestamp: new Date().toISOString(),
    level,
    message,
    ...meta,
  };

  // Simple JSON logging for now
  // In production, could use Winston, Pino, or cloud logging
  console.log(JSON.stringify(entry));
}

export const logger = {
  info: (message: string, meta?: Record<string, unknown>) => log('info', message, meta),
  warn: (message: string, meta?: Record<string, unknown>) => log('warn', message, meta),
  error: (message: string, meta?: Record<string, unknown>) => log('error', message, meta),
  debug: (message: string, meta?: Record<string, unknown>) => log('debug', message, meta),
};

/**
 * Sanitize headers for logging - remove Authorization and other sensitive headers
 */
export function sanitizeHeaders(headers: Record<string, unknown>): Record<string, unknown> {
  const sanitized = { ...headers };
  delete sanitized.authorization;
  delete sanitized.Authorization;
  delete sanitized['x-api-key'];
  delete sanitized['X-API-Key'];
  return sanitized;
}
