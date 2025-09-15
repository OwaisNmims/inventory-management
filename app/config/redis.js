const redis = require("redis");

// Create Redis client configuration
const client = redis.createClient({
    host: process.env.REDIS_HOST || '127.0.0.1',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASS || undefined,
});

// Handle Redis connection events
client.on('connect', () => {
    console.log('Redis client connected');
});

client.on('error', (err) => {
    console.error('Redis Client Error:', err);
});

// For older Redis clients (version 3.x), you might need to connect explicitly
// Uncomment the following lines if using Redis client version 3.x:
// client.on('ready', () => {
//     console.log('Redis client ready');
// });

module.exports = client; 