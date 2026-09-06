/**
 * API Error Contract
 * Stable machine-readable error codes for Flutter localization
 */

export enum ErrorCode {
  AUTH_REQUIRED = 'AUTH_REQUIRED',
  AUTH_INVALID = 'AUTH_INVALID',
  FORBIDDEN = 'FORBIDDEN',
  INVALID_ARGUMENT = 'INVALID_ARGUMENT',
  NOT_FOUND = 'NOT_FOUND',
  CONFLICT = 'CONFLICT',
  RATE_LIMITED = 'RATE_LIMITED',
  INTERNAL = 'INTERNAL',
}

export class ApiError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly code: ErrorCode,
    message: string,
    public readonly details?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'ApiError';
    Error.captureStackTrace(this, this.constructor);
  }

  toJSON() {
    return {
      error: {
        code: this.code,
        message: this.message,
        ...(this.details && { details: this.details }),
      },
    };
  }

  static authRequired(message = 'Authentication required'): ApiError {
    return new ApiError(401, ErrorCode.AUTH_REQUIRED, message);
  }

  static authInvalid(message = 'Invalid or expired authentication token'): ApiError {
    return new ApiError(401, ErrorCode.AUTH_INVALID, message);
  }

  static forbidden(message = 'Access forbidden'): ApiError {
    return new ApiError(403, ErrorCode.FORBIDDEN, message);
  }

  static invalidArgument(message: string, details?: Record<string, unknown>): ApiError {
    return new ApiError(400, ErrorCode.INVALID_ARGUMENT, message, details);
  }

  static notFound(resource: string, id?: string): ApiError {
    const message = id ? `${resource} ${id} not found` : `${resource} not found`;
    return new ApiError(404, ErrorCode.NOT_FOUND, message);
  }

  static conflict(message: string): ApiError {
    return new ApiError(409, ErrorCode.CONFLICT, message);
  }

  static rateLimited(message = 'Too many requests'): ApiError {
    return new ApiError(429, ErrorCode.RATE_LIMITED, message);
  }

  static internal(message = 'Internal server error'): ApiError {
    return new ApiError(500, ErrorCode.INTERNAL, message);
  }
}
