const express = require('express');
const mongoose = require('mongoose');
const Vehicle = require('../models/Vehicle');
const Driver = require('../models/Driver');
const Trip = require('../models/Trip');
const Alert = require('../models/Alert');
const AuditLog = require('../models/AuditLog');
const { verifyToken, requireRole, scopeToOrganization } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken, scopeToOrganization);

const STALE_THRESHOLD_MS = 15 * 60 * 1000; // 15 minutes

function formatLastUpdated(date) {
  if (!date) return 'No data';
  const diffSec = Math.floor((Date.now() - new Date(date).getTime()) / 1000);
  if (diffSec < 60) return 'Just now';
  const diffMin = Math.floor(diffSec / 60);
  if (diffMin < 60) return `Last updated ${diffMin} min ago`;
  const diffHr = Math.floor(diffMin / 60);
  if (diffHr < 24) return `Last updated ${diffHr} hr ago`;
  const diffDays = Math.floor(diffHr / 24);
  return `Last updated ${diffDays} d ago`;
}

// GET /api/v1/vehicles
router.get('/', async (req, res) => {
  try {
    const { search, status, sort = 'lastUpdated', page = 1, limit = 20 } = req.query;
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));

    const filter = {
      organizationId: req.organizationId,
      isDeleted: false,
    };

    // If searching by driver name, find matching driver IDs first
    if (search && search.trim()) {
      const searchRegex = new RegExp(search.trim(), 'i');
      const matchingDrivers = await Driver.find({
        organizationId: req.organizationId,
        name: searchRegex,
      }).select('_id');

      const driverIds = matchingDrivers.map((d) => d._id);

      filter.$or = [
        { plateNumber: searchRegex },
        { nickname: searchRegex },
        { make: searchRegex },
        { model: searchRegex },
        { assignedDriverId: { $in: driverIds } },
      ];
    }

    if (status && status !== 'all') {
      if (status === 'offline') {
        const staleDate = new Date(Date.now() - STALE_THRESHOLD_MS);
        filter.$or = [
          { status: 'offline' },
          { lastLocationUpdatedAt: { $lt: staleDate }, status: { $ne: 'maintenance' } },
        ];
      } else {
        filter.status = status;
      }
    }

    let sortCriteria = { lastLocationUpdatedAt: -1 };
    if (sort === 'name') sortCriteria = { nickname: 1, plateNumber: 1 };
    else if (sort === 'status') sortCriteria = { status: 1 };
    else if (sort === 'distance') sortCriteria = { todayDistanceKm: -1 };

    const total = await Vehicle.countDocuments(filter);
    const vehicles = await Vehicle.find(filter)
      .sort(sortCriteria)
      .skip((pageNum - 1) * limitNum)
      .limit(limitNum)
      .populate('assignedDriverId', 'name phone safetyScore avatarUrl')
      .populate('currentTripId', 'tripNumber status startAddress endAddress');

    const now = Date.now();
    const formatted = vehicles.map((v) => {
      const isStale = v.lastLocationUpdatedAt
        ? now - new Date(v.lastLocationUpdatedAt).getTime() > STALE_THRESHOLD_MS
        : true;

      let effectiveStatus = v.status;
      if (v.status !== 'maintenance' && isStale) {
        effectiveStatus = 'offline';
      }

      return {
        id: v._id.toString(),
        plateNumber: v.plateNumber,
        nickname: v.nickname || v.plateNumber,
        type: v.type,
        make: v.make,
        model: v.model,
        year: v.year,
        status: effectiveStatus,
        speedKmh: v.speedKmh,
        heading: v.heading,
        ignition: v.ignition,
        fuelType: v.fuelType,
        currentFuelLevel: v.currentFuelLevel,
        batteryLevel: v.batteryLevel,
        odometerKm: v.odometerKm,
        todayDistanceKm: v.todayDistanceKm,
        hasHardwareGps: v.hasHardwareGps,
        lastKnownLocation: v.lastKnownLocation
          ? {
              latitude: v.lastKnownLocation.coordinates[1],
              longitude: v.lastKnownLocation.coordinates[0],
              address: v.lastKnownLocation.address,
              timestamp: v.lastKnownLocation.timestamp,
            }
          : null,
        lastLocationUpdatedAt: v.lastLocationUpdatedAt,
        lastUpdatedAgo: formatLastUpdated(v.lastLocationUpdatedAt),
        isStale,
        assignedDriver: v.assignedDriverId
          ? {
              id: v.assignedDriverId._id.toString(),
              name: v.assignedDriverId.name,
              phone: v.assignedDriverId.phone,
              safetyScore: v.assignedDriverId.safetyScore,
            }
          : null,
        currentTrip: v.currentTripId
          ? {
              id: v.currentTripId._id.toString(),
              tripNumber: v.currentTripId.tripNumber,
              status: v.currentTripId.status,
            }
          : null,
      };
    });

    res.json({
      vehicles: formatted,
      total,
      page: pageNum,
      totalPages: Math.ceil(total / limitNum),
    });
  } catch (err) {
    console.error('GET /api/v1/vehicles error:', err);
    res.status(500).json({ error: 'Server error retrieving fleet vehicles' });
  }
});

// GET /api/v1/vehicles/:id
router.get('/:id', async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid vehicle ID format' });
    }

    const vehicle = await Vehicle.findOne({
      _id: req.params.id,
      organizationId: req.organizationId,
      isDeleted: false,
    }).populate('assignedDriverId');

    if (!vehicle) {
      return res.status(404).json({ error: 'Vehicle not found' });
    }

    // Fetch open alerts and recent trips for this vehicle
    const [openAlerts, recentTrips] = await Promise.all([
      Alert.find({
        vehicleId: vehicle._id,
        organizationId: req.organizationId,
        isAcknowledged: false,
        isDeleted: false,
      })
        .sort({ timestamp: -1 })
        .limit(10),
      Trip.find({
        vehicleId: vehicle._id,
        organizationId: req.organizationId,
      })
        .sort({ startTime: -1 })
        .limit(5)
        .populate('driverId', 'name phone'),
    ]);

    const isStale = vehicle.lastLocationUpdatedAt
      ? Date.now() - new Date(vehicle.lastLocationUpdatedAt).getTime() > STALE_THRESHOLD_MS
      : true;

    res.json({
      vehicle: {
        id: vehicle._id.toString(),
        plateNumber: vehicle.plateNumber,
        nickname: vehicle.nickname || vehicle.plateNumber,
        type: vehicle.type,
        make: vehicle.make,
        model: vehicle.model,
        year: vehicle.year,
        status: isStale && vehicle.status !== 'maintenance' ? 'offline' : vehicle.status,
        speedKmh: vehicle.speedKmh,
        heading: vehicle.heading,
        ignition: vehicle.ignition,
        fuelType: vehicle.fuelType,
        currentFuelLevel: vehicle.currentFuelLevel,
        batteryLevel: vehicle.batteryLevel,
        odometerKm: vehicle.odometerKm,
        todayDistanceKm: vehicle.todayDistanceKm,
        lastKnownLocation: vehicle.lastKnownLocation
          ? {
              latitude: vehicle.lastKnownLocation.coordinates[1],
              longitude: vehicle.lastKnownLocation.coordinates[0],
              address: vehicle.lastKnownLocation.address,
              timestamp: vehicle.lastKnownLocation.timestamp,
            }
          : null,
        lastLocationUpdatedAt: vehicle.lastLocationUpdatedAt,
        lastUpdatedAgo: formatLastUpdated(vehicle.lastLocationUpdatedAt),
        isStale,
        assignedDriver: vehicle.assignedDriverId
          ? {
              id: vehicle.assignedDriverId._id.toString(),
              name: vehicle.assignedDriverId.name,
              phone: vehicle.assignedDriverId.phone,
              safetyScore: vehicle.assignedDriverId.safetyScore,
              licenseNumber: vehicle.assignedDriverId.licenseNumber,
              totalTrips: vehicle.assignedDriverId.totalTrips,
            }
          : null,
        openAlerts: openAlerts.map((a) => ({
          id: a._id.toString(),
          type: a.type,
          severity: a.severity,
          title: a.title,
          description: a.description,
          timestamp: a.timestamp,
        })),
        recentTrips: recentTrips.map((t) => ({
          id: t._id.toString(),
          tripNumber: t.tripNumber,
          status: t.status,
          startAddress: t.startAddress,
          endAddress: t.endAddress,
          distanceKm: t.distanceKm,
          durationMinutes: t.durationMinutes,
          startTime: t.startTime,
          endTime: t.endTime,
        })),
      },
    });
  } catch (err) {
    console.error('GET /api/v1/vehicles/:id error:', err);
    res.status(500).json({ error: 'Server error retrieving vehicle details' });
  }
});

// PATCH /api/v1/vehicles/:id/nickname (Owner only)
router.patch('/:id/nickname', requireRole('owner'), async (req, res) => {
  try {
    const { nickname } = req.body;
    if (typeof nickname !== 'string') {
      return res.status(400).json({ error: 'Nickname must be a string' });
    }

    const vehicle = await Vehicle.findOne({
      _id: req.params.id,
      organizationId: req.organizationId,
    });
    if (!vehicle) return res.status(404).json({ error: 'Vehicle not found' });

    vehicle.nickname = nickname.trim();
    await vehicle.save();

    await AuditLog.create({
      organizationId: req.organizationId,
      userId: req.user.userId,
      action: 'vehicle_nickname_update',
      targetType: 'Vehicle',
      targetId: vehicle._id,
      metadata: { newNickname: nickname.trim() },
    }).catch((e) => console.error('AuditLog error:', e.message));

    res.json({ success: true, nickname: vehicle.nickname });
  } catch (err) {
    res.status(500).json({ error: 'Server error updating vehicle nickname' });
  }
});

// GET /api/v1/vehicles/:id/location
router.get('/:id/location', async (req, res) => {
  try {
    const vehicle = await Vehicle.findOne({
      _id: req.params.id,
      organizationId: req.organizationId,
    });
    if (!vehicle) return res.status(404).json({ error: 'Vehicle not found' });

    const isStale = vehicle.lastLocationUpdatedAt
      ? Date.now() - new Date(vehicle.lastLocationUpdatedAt).getTime() > STALE_THRESHOLD_MS
      : true;

    res.json({
      vehicleId: vehicle._id.toString(),
      plateNumber: vehicle.plateNumber,
      nickname: vehicle.nickname || vehicle.plateNumber,
      status: isStale && vehicle.status !== 'maintenance' ? 'offline' : vehicle.status,
      speedKmh: vehicle.speedKmh,
      heading: vehicle.heading,
      ignition: vehicle.ignition,
      isStale,
      lastUpdatedAgo: formatLastUpdated(vehicle.lastLocationUpdatedAt),
      location: vehicle.lastKnownLocation
        ? {
            latitude: vehicle.lastKnownLocation.coordinates[1],
            longitude: vehicle.lastKnownLocation.coordinates[0],
            address: vehicle.lastKnownLocation.address,
            timestamp: vehicle.lastKnownLocation.timestamp,
          }
        : null,
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error retrieving vehicle location' });
  }
});

// GET /api/v1/vehicles/:id/trips
router.get('/:id/trips', async (req, res) => {
  try {
    const { date, page = 1, limit = 20 } = req.query;
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));

    const filter = {
      vehicleId: req.params.id,
      organizationId: req.organizationId,
    };

    if (date) {
      const startOfDay = new Date(date);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(date);
      endOfDay.setHours(23, 59, 59, 999);
      filter.startTime = { $gte: startOfDay, $lte: endOfDay };
    }

    const total = await Trip.countDocuments(filter);
    const trips = await Trip.find(filter)
      .sort({ startTime: -1 })
      .skip((pageNum - 1) * limitNum)
      .limit(limitNum)
      .populate('driverId', 'name phone');

    res.json({
      trips: trips.map((t) => ({
        id: t._id.toString(),
        tripNumber: t.tripNumber,
        status: t.status,
        driverName: t.driverId ? t.driverId.name : 'Assigned Driver',
        startTime: t.startTime,
        endTime: t.endTime,
        distanceKm: t.distanceKm,
        durationMinutes: t.durationMinutes,
        startAddress: t.startAddress,
        endAddress: t.endAddress,
        safetyScore: t.safetyScore,
      })),
      total,
      page: pageNum,
      totalPages: Math.ceil(total / limitNum),
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error retrieving trips' });
  }
});

module.exports = router;
