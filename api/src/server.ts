/**
 * API Server Entry Point
 * 
 * Starts Express server on configured port
 * PORT is configurable via environment variable (default: 3000)
 */

import { getEnvironment } from './config/environment';
import { createApp } from './app';
import { logger } from './utils/logger';

const { port, nodeEnv } = getEnvironment();
const app = createApp();

// Default port: 3000 (matches Flutter dev config)
const PORT = port || 3000;

app.listen(PORT, () => {
  logger.info(`ANIS API server listening`, {
    port: PORT,
    nodeEnv,
    baseUrl: `http://localhost:${PORT}`,
  });
});
