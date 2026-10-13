require('dotenv').config();
const http = require('http');
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');

const v1Routes = require('./routes');
const { JWT_SECRET } = require('./middleware/auth');
const Organization = require('./models/Organization');

const app = express();
const server = http.createServer(app);

// CORS configuration
const allowedOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(',').map((o) => o.trim())
  : ['http://localhost:3000', 'http://localhost:5173', 'http://localhost:8080', '*'];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow mobile apps, local tools, or matched origins
      if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(null, true); // Permissive for local dev & mobile
      }
    },
    credentials: true,
  })
);

app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'navixa-owner-api',
  });
});

// Versioned APIs
app.use('/api/v1', v1Routes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Global error handler (no stack traces leaked in production)
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  const isProd = process.env.NODE_ENV === 'production';
  res.status(err.status || 500).json({
    error: isProd ? 'Internal server error' : err.message || 'Internal server error',
  });
});

// Socket.IO Setup
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

app.set('io', io);

// Socket Auth Middleware
io.use((socket, next) => {
  const token = socket.handshake.auth?.token || socket.handshake.query?.token;
  if (!token) {
    return next(new Error('Authentication required'));
  }
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    socket.user = decoded;
    next();
  } catch (err) {
    next(new Error('Invalid token'));
  }
});

io.on('connection', (socket) => {
  const user = socket.user;
  const orgId = user.organizationId || user.companyId;

  console.log(`⚡ Socket connected: socketId=${socket.id} user=${user.userId} org=${orgId}`);

  // Automatically join organization and user room
  if (orgId) {
    const orgRoom = `org:${orgId.toString()}`;
    socket.join(orgRoom);
    socket.join(`company:${orgId.toString()}`);
  }

  if (user.userId) {
    socket.join(`user:${user.userId.toString()}`);
  }

  // Subscribe to a specific vehicle within the organization
  socket.on('subscribe:vehicle', async (vehicleId) => {
    try {
      if (!vehicleId || !mongoose.Types.ObjectId.isValid(vehicleId)) return;
      socket.join(`vehicle:${vehicleId}`);
      console.log(`🚗 User ${user.userId} joined vehicle:${vehicleId}`);
    } catch (e) {
      console.error('Error joining vehicle room:', e.message);
    }
  });

  socket.on('unsubscribe:vehicle', (vehicleId) => {
    socket.leave(`vehicle:${vehicleId}`);
  });

  socket.on('disconnect', (reason) => {
    console.log(`🔌 Socket disconnected: user=${user?.userId} reason=${reason}`);
  });
});

const PORT = process.env.PORT || 3000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/navixa_fleet';

async function startServer() {
  if (process.env.NODE_ENV !== 'test') {
    try {
      await mongoose.connect(MONGODB_URI);
      console.log('✅ Connected to MongoDB');
      server.listen(PORT, () => {
        console.log(`🚀 Navixa Owner API server running on port ${PORT}`);
        console.log(`🩺 Health check at http://localhost:${PORT}/health`);
      });
    } catch (err) {
      console.error('Failed to connect to MongoDB:', err.message);
    }
  }
}

startServer();

module.exports = { app, server, io };
