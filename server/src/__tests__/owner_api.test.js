process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-owner-2026';
process.env.JWT_REFRESH_SECRET = 'test-jwt-refresh-secret-owner-2026';

const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const request = require('supertest');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const { app } = require('../index');
const Organization = require('../models/Organization');
const User = require('../models/User');
const Vehicle = require('../models/Vehicle');
const Driver = require('../models/Driver');
const Trip = require('../models/Trip');
const Alert = require('../models/Alert');
const NotificationPreference = require('../models/NotificationPreference');

let mongoServer;
let orgA;
let orgB;
let ownerA;
let managerA;
let viewerA;
let ownerB;

let tokenOwnerA;
let tokenManagerA;
let tokenViewerA;
let tokenOwnerB;

let vehicleA1;
let vehicleA2Stale;
let vehicleB1;
let alertA1;
let alertA2;

function makeToken(user, orgId, expiresIn = '1h') {
  return jwt.sign(
    {
      userId: user._id.toString(),
      role: user.role,
      organizationId: orgId.toString(),
      companyId: orgId.toString(),
      name: user.name,
      email: user.email,
    },
    process.env.JWT_SECRET,
    { expiresIn }
  );
}

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);

  // 1. Create two Organizations to test strict tenant isolation
  orgA = await Organization.create({
    name: 'Org A Logistics',
    code: 'ORGA',
    contactEmail: 'a@example.com',
  });

  orgB = await Organization.create({
    name: 'Org B Express',
    code: 'ORGB',
    contactEmail: 'b@example.com',
  });

  const passwordHash = await bcrypt.hash('Secret123!', 10);

  // 2. Create users
  ownerA = await User.create({
    name: 'Owner Alice',
    email: 'alice@orga.com',
    phone: '+1000000001',
    role: 'owner',
    organizationId: orgA._id,
    companyId: orgA._id,
    passwordHash,
    isActive: true,
  });

  managerA = await User.create({
    name: 'Manager Bob',
    email: 'bob@orga.com',
    phone: '+1000000002',
    role: 'manager',
    organizationId: orgA._id,
    companyId: orgA._id,
    passwordHash,
    isActive: true,
  });

  viewerA = await User.create({
    name: 'Viewer Charlie',
    email: 'charlie@orga.com',
    phone: '+1000000003',
    role: 'viewer',
    organizationId: orgA._id,
    companyId: orgA._id,
    passwordHash,
    isActive: true,
  });

  ownerB = await User.create({
    name: 'Owner B Mallory',
    email: 'mallory@orgb.com',
    phone: '+1000000004',
    role: 'owner',
    organizationId: orgB._id,
    companyId: orgB._id,
    passwordHash,
    isActive: true,
  });

  tokenOwnerA = makeToken(ownerA, orgA._id);
  tokenManagerA = makeToken(managerA, orgA._id);
  tokenViewerA = makeToken(viewerA, orgA._id);
  tokenOwnerB = makeToken(ownerB, orgB._id);

  // 3. Vehicles
  const now = new Date();
  const staleTime = new Date(now.getTime() - 40 * 60 * 1000); // 40m ago

  vehicleA1 = await Vehicle.create({
    organizationId: orgA._id,
    companyId: orgA._id,
    plateNumber: 'NX-01-AAA',
    nickname: 'Alpha Truck',
    status: 'moving',
    speedKmh: 65,
    lastKnownLocation: {
      type: 'Point',
      coordinates: [77.59, 12.97],
      address: 'Route A',
      timestamp: now,
    },
    lastLocationUpdatedAt: now,
  });

  vehicleA2Stale = await Vehicle.create({
    organizationId: orgA._id,
    companyId: orgA._id,
    plateNumber: 'NX-02-STALE',
    nickname: 'Stale Van',
    status: 'idle',
    lastKnownLocation: {
      type: 'Point',
      coordinates: [77.6, 12.95],
      address: 'Old Warehouse',
      timestamp: staleTime,
    },
    lastLocationUpdatedAt: staleTime,
  });

  vehicleB1 = await Vehicle.create({
    organizationId: orgB._id,
    companyId: orgB._id,
    plateNumber: 'NX-99-BBB',
    nickname: 'Bravo Vehicle',
    status: 'moving',
    lastKnownLocation: {
      type: 'Point',
      coordinates: [77.7, 12.8],
      address: 'Org B Secret Depot',
      timestamp: now,
    },
    lastLocationUpdatedAt: now,
  });

  // 4. Alerts
  alertA1 = await Alert.create({
    organizationId: orgA._id,
    companyId: orgA._id,
    vehicleId: vehicleA1._id,
    type: 'overspeed',
    severity: 'critical',
    title: 'Overspeed Alert',
    description: 'Vehicle exceeded limit',
    isAcknowledged: false,
    isRead: false,
  });

  alertA2 = await Alert.create({
    organizationId: orgA._id,
    companyId: orgA._id,
    vehicleId: vehicleA1._id,
    type: 'vehicle_started',
    severity: 'info',
    title: 'Vehicle Started',
    isAcknowledged: false,
    isRead: false,
  });
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe('Navixa Owner API Suite', () => {
  describe('1. Organization Isolation & Access Control', () => {
    it('Owner A cannot access vehicles belonging to Org B', async () => {
      const res = await request(app)
        .get(`/api/v1/vehicles/${vehicleB1._id}`)
        .set('Authorization', `Bearer ${tokenOwnerA}`);

      expect(res.status).toBe(404);
    });

    it('Owner A list query never returns Org B vehicles', async () => {
      const res = await request(app)
        .get('/api/v1/vehicles')
        .set('Authorization', `Bearer ${tokenOwnerA}`);

      expect(res.status).toBe(200);
      expect(res.body.vehicles).toBeDefined();
      const plates = res.body.vehicles.map((v) => v.plateNumber);
      expect(plates).toContain('NX-01-AAA');
      expect(plates).not.toContain('NX-99-BBB');
    });

    it('Owner B cannot access Org A vehicle details', async () => {
      const res = await request(app)
        .get(`/api/v1/vehicles/${vehicleA1._id}`)
        .set('Authorization', `Bearer ${tokenOwnerB}`);

      expect(res.status).toBe(404);
    });
  });

  describe('2. Role-Based Permissions & Alert Lifecycle', () => {
    it('Viewer cannot acknowledge an alert (forbidden 403)', async () => {
      const res = await request(app)
        .patch(`/api/v1/alerts/${alertA1._id}/acknowledge`)
        .set('Authorization', `Bearer ${tokenViewerA}`)
        .send({ note: 'Attempt by viewer' });

      expect(res.status).toBe(403);
      expect(res.body.error).toMatch(/Access denied/i);
    });

    it('Manager can acknowledge an alert', async () => {
      const res = await request(app)
        .patch(`/api/v1/alerts/${alertA1._id}/acknowledge`)
        .set('Authorization', `Bearer ${tokenManagerA}`)
        .send({ note: 'Handled by manager' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.alert.isAcknowledged).toBe(true);
    });

    it('Viewer can mark an alert as read', async () => {
      const res = await request(app)
        .patch(`/api/v1/alerts/${alertA2._id}/read`)
        .set('Authorization', `Bearer ${tokenViewerA}`);

      expect(res.status).toBe(200);
      expect(res.body.isRead).toBe(true);
    });
  });

  describe('3. Token Lifecycle & Expiration Handling', () => {
    it('Expired access token returns 401 with TOKEN_EXPIRED code', async () => {
      const expiredToken = makeToken(ownerA, orgA._id, '-10s');
      const res = await request(app)
        .get('/api/v1/owner/overview')
        .set('Authorization', `Bearer ${expiredToken}`);

      expect(res.status).toBe(401);
      expect(res.body.code).toBe('TOKEN_EXPIRED');
    });

    it('Valid login generates refresh token and allows refresh', async () => {
      const loginRes = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'alice@orga.com', password: 'Secret123!' });

      expect(loginRes.status).toBe(200);
      expect(loginRes.body.accessToken).toBeDefined();
      expect(loginRes.body.refreshToken).toBeDefined();

      const refreshRes = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: loginRes.body.refreshToken });

      expect(refreshRes.status).toBe(200);
      expect(refreshRes.body.accessToken).toBeDefined();
    });

    it('Revoked refresh token is rejected', async () => {
      // Log out Alice to clear the refresh token hash
      await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${tokenOwnerA}`);

      const badRefresh = jwt.sign(
        { userId: ownerA._id.toString() },
        process.env.JWT_REFRESH_SECRET,
        { expiresIn: '7d' }
      );

      const res = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: badRefresh });

      expect(res.status).toBe(401);
    });
  });

  describe('4. Telemetry & Stale GPS Presentation', () => {
    it('Stale location is accurately flagged as isStale and effective status offline', async () => {
      const res = await request(app)
        .get(`/api/v1/vehicles/${vehicleA2Stale._id}`)
        .set('Authorization', `Bearer ${tokenOwnerA}`);

      expect(res.status).toBe(200);
      expect(res.body.vehicle.isStale).toBe(true);
      expect(res.body.vehicle.status).toBe('offline');
      expect(res.body.vehicle.lastUpdatedAgo).toMatch(/min ago/i);
    });

    it('Fresh location is not flagged as stale', async () => {
      const res = await request(app)
        .get(`/api/v1/vehicles/${vehicleA1._id}`)
        .set('Authorization', `Bearer ${tokenOwnerA}`);

      expect(res.status).toBe(200);
      expect(res.body.vehicle.isStale).toBe(false);
      expect(res.body.vehicle.status).toBe('moving');
    });
  });

  describe('5. Owner Overview Dashboard Aggregates', () => {
    it('Returns aggregated metrics and greeting for the organization', async () => {
      const res = await request(app)
        .get('/api/v1/owner/overview')
        .set('Authorization', `Bearer ${tokenOwnerA}`);

      expect(res.status).toBe(200);
      expect(res.body.organizationName).toBe('Org A Logistics');
      expect(res.body.statusCounts.total).toBe(2);
      expect(res.body.statusCounts.moving).toBe(1);
      expect(res.body.statusCounts.offline).toBe(1);
      expect(res.body.fleetMapPreview).toBeDefined();
      expect(res.body.greeting).toBeDefined();
    });
  });

  describe('6. Team Management & Invitations', () => {
    it('Owner can invite a new manager', async () => {
      const res = await request(app)
        .post('/api/v1/team/invitations')
        .set('Authorization', `Bearer ${tokenOwnerA}`)
        .send({
          name: 'Dana Scully',
          email: 'dana@orga.com',
          role: 'manager',
        });

      expect(res.status).toBe(201);
      expect(res.body.user.role).toBe('manager');
      expect(res.body.user.email).toBe('dana@orga.com');
    });

    it('Viewer cannot invite team members (forbidden 403)', async () => {
      const res = await request(app)
        .post('/api/v1/team/invitations')
        .set('Authorization', `Bearer ${tokenViewerA}`)
        .send({
          name: 'Hacker',
          email: 'hacker@orga.com',
          role: 'manager',
        });

      expect(res.status).toBe(403);
    });
  });
});
