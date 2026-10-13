const express = require('express');
const mongoose = require('mongoose');
const Vehicle = require('../models/Vehicle');
const Trip = require('../models/Trip');
const Alert = require('../models/Alert');
const Organization = require('../models/Organization');
const { verifyToken, scopeToOrganization } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken, scopeToOrganization);

function getTimeGreeting(date = new Date()) {
  const hour = date.getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

// GET /api/v1/owner/overview
router.get('/overview', async (req, res) => {
  try {
    const orgId = req.organizationId;
    if (!orgId) {
      return res.status(403).json({ error: 'Organization context missing' });
    }

    const org = await Organization.findById(orgId);
    const orgName = org ? org.name : 'Navixa Fleet';

    const now = new Date();
    const offlineThresholdMs = 20 * 60 * 1000; // 20 mins

    // 1. Fetch vehicles
    const vehicles = await Vehicle.find({
      organizationId: orgId,
      isDeleted: false,
    }).populate('assignedDriverId', 'name phone safetyScore');

    let totalVehicles = vehicles.length;
    let movingCount = 0;
    let idleCount = 0;
    let parkedCount = 0;
    let offlineCount = 0;
    let maintenanceCount = 0;

    const fleetMapPreview = [];

    for (const v of vehicles) {
      const isStale = v.lastLocationUpdatedAt
        ? now.getTime() - new Date(v.lastLocationUpdatedAt).getTime() > offlineThresholdMs
        : true;

      let effectiveStatus = v.status;
      if (v.status !== 'maintenance' && isStale) {
        effectiveStatus = 'offline';
      }

      if (effectiveStatus === 'moving') movingCount += 1;
      else if (effectiveStatus === 'idle') idleCount += 1;
      else if (effectiveStatus === 'parked') parkedCount += 1;
      else if (effectiveStatus === 'maintenance') maintenanceCount += 1;
      else offlineCount += 1;

      if (v.lastKnownLocation && v.lastKnownLocation.coordinates) {
        fleetMapPreview.push({
          id: v._id.toString(),
          plateNumber: v.plateNumber,
          nickname: v.nickname || v.plateNumber,
          type: v.type,
          status: effectiveStatus,
          speedKmh: v.speedKmh || 0,
          heading: v.heading || 0,
          ignition: v.ignition,
          fuelLevel: v.currentFuelLevel,
          coordinates: v.lastKnownLocation.coordinates, // [lng, lat]
          latitude: v.lastKnownLocation.coordinates[1],
          longitude: v.lastKnownLocation.coordinates[0],
          address: v.lastKnownLocation.address || '',
          lastLocationUpdatedAt: v.lastLocationUpdatedAt,
          isStale,
        });
      }
    }

    // 2. Fetch unread and critical alerts
    const [unreadAlertsCount, criticalAlertsCount, recentAlerts, bannerAlert] = await Promise.all([
      Alert.countDocuments({ organizationId: orgId, isRead: false, isDeleted: false }),
      Alert.countDocuments({
        organizationId: orgId,
        severity: 'critical',
        isAcknowledged: false,
        isDeleted: false,
      }),
      Alert.find({ organizationId: orgId, isDeleted: false })
        .sort({ timestamp: -1 })
        .limit(5)
        .populate('vehicleId', 'plateNumber nickname'),
      Alert.findOne({
        organizationId: orgId,
        severity: 'critical',
        isAcknowledged: false,
        isDeleted: false,
      })
        .sort({ timestamp: -1 })
        .populate('vehicleId', 'plateNumber nickname'),
    ]);

    // 3. Fetch recent trips
    const recentTrips = await Trip.find({ organizationId: orgId })
      .sort({ startTime: -1 })
      .limit(5)
      .populate('vehicleId', 'plateNumber nickname type')
      .populate('driverId', 'name phone');

    res.json({
      greeting: `${getTimeGreeting(now)}, ${req.user.name || 'Fleet Owner'}`,
      organizationName: orgName,
      lastUpdated: now.toISOString(),
      unreadCount: unreadAlertsCount,
      criticalAlertsCount,
      statusCounts: {
        total: totalVehicles,
        moving: movingCount,
        idle: idleCount,
        parked: parkedCount,
        offline: offlineCount,
        maintenance: maintenanceCount,
      },
      criticalAlertBanner: bannerAlert
        ? {
            id: bannerAlert._id.toString(),
            title: bannerAlert.title,
            description: bannerAlert.description,
            severity: bannerAlert.severity,
            vehicleName: bannerAlert.vehicleId
              ? bannerAlert.vehicleId.nickname || bannerAlert.vehicleId.plateNumber
              : 'Fleet Vehicle',
            timestamp: bannerAlert.timestamp,
          }
        : null,
      fleetMapPreview,
      recentAlerts: recentAlerts.map((a) => ({
        id: a._id.toString(),
        type: a.type,
        severity: a.severity,
        title: a.title,
        description: a.description,
        vehicleName: a.vehicleId ? a.vehicleId.nickname || a.vehicleId.plateNumber : 'Fleet Vehicle',
        vehicleId: a.vehicleId ? a.vehicleId._id.toString() : null,
        location: a.location?.name || '',
        timestamp: a.timestamp,
        isRead: a.isRead,
        isAcknowledged: a.isAcknowledged,
      })),
      recentTrips: recentTrips.map((t) => ({
        id: t._id.toString(),
        tripNumber: t.tripNumber,
        status: t.status,
        vehicleName: t.vehicleId ? t.vehicleId.nickname || t.vehicleId.plateNumber : 'Fleet Vehicle',
        driverName: t.driverId ? t.driverId.name : 'Assigned Driver',
        startAddress: t.startAddress,
        endAddress: t.endAddress,
        distanceKm: t.distanceKm,
        durationMinutes: t.durationMinutes,
        startTime: t.startTime,
        endTime: t.endTime,
      })),
    });
  } catch (err) {
    console.error('GET /api/v1/owner/overview error:', err);
    res.status(500).json({ error: 'Server error retrieving dashboard overview' });
  }
});

module.exports = router;
