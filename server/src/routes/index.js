const express = require('express');

const authRoutes = require('./auth');
const ownerRoutes = require('./owner');
const vehiclesRoutes = require('./vehicles');
const tripsRoutes = require('./trips');
const alertsRoutes = require('./alerts');
const notificationPreferencesRoutes = require('./notificationPreferences');
const devicesRoutes = require('./devices');
const teamRoutes = require('./team');
const driversRoutes = require('./drivers');

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/owner', ownerRoutes);
router.use('/vehicles', vehiclesRoutes);
router.use('/trips', tripsRoutes);
router.use('/alerts', alertsRoutes);
router.use('/notification-preferences', notificationPreferencesRoutes);
router.use('/devices', devicesRoutes);
router.use('/team', teamRoutes);
router.use('/drivers', driversRoutes);

module.exports = router;
