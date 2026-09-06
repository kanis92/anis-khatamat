process.env.ALLOWED_ORIGINS = 'http://localhost:3000,https://anis-khatamat.com';

const { getEnvironment, resetEnvironment } = require('./lib/config/environment');

console.log('Before reset:', getEnvironment().allowedOrigins);
resetEnvironment();
console.log('After reset:', getEnvironment().allowedOrigins);
