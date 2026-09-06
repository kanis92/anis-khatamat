/**
 * ANIS API Server Entry Point
 */

import { createApp } from './app';
import { getEnvironment } from './config/environment';
import { logger } from './utils/logger';

function startServer(): void {
  try {
    const env = getEnvironment();
    const app = createApp();

    const server = app.listen(env.port, () => {
      logger.info('ANIS API server started', {
        nodeEnv: env.nodeEnv,
        port: env.port,
        firebaseProjectId: env.firebaseProjectId,
        allowedOrigins: env.allowedOrigins,
      });
    });

    // Graceful shutdown
    process.on('SIGTERM', () => {
      logger.info('SIGTERM received, shutting down gracefully');
      server.close(() => {
        logger.info('Server closed');
        process.exit(0);
      });
    });

    process.on('SIGINT', () => {
      logger.info('SIGINT received, shutting down gracefully');
      server.close(() => {
        logger.info('Server closed');
        process.exit(0);
      });
    });
  } catch (error) {
    logger.error('Failed to start server', {
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    process.exit(1);
  }
}

// Start server if executed directly
if (require.main === module) {
  startServer();
}
