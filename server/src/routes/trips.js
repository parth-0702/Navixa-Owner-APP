const express = require('express');
const mongoose = require('mongoose');
const Trip = require('../models/Trip');
const { verifyToken, scopeToOrganization } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken, scopeToOrganization);

// GET /api/v1/trips — owner trip overview with status, driver, vehicle and date filters
router.get('/', async (req, res) => {
  try {
    const { status, vehicleId, driverId, search, from, to, page = 1, limit = 50 } = req.query;
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 50));
    const filter = { organizationId: req.organizationId };

    if (status && status !== 'all') filter.status = status;
    if (vehicleId) filter.vehicleId = vehicleId;
    if (driverId) filter.driverId = driverId;
    if (from || to) {
      filter.startTime = {};
      if (from) filter.startTime.$gte = new Date(`${from}T00:00:00.000Z`);
      if (to) filter.startTime.$lte = new Date(`${to}T23:59:59.999Z`);
    }
    if (search && search.trim()) {
      filter.tripNumber = new RegExp(search.trim(), 'i');
    }

    const total = await Trip.countDocuments(filter);
    const trips = await Trip.find(filter)
      .sort({ startTime: -1 })
      .skip((pageNum - 1) * limitNum)
      .limit(limitNum)
      .populate('vehicleId', 'plateNumber nickname type')
      .populate('driverId', 'name phone safetyScore');

    res.json({
      trips: trips.map((t) => ({
        id: t._id.toString(),
        tripNumber: t.tripNumber,
        status: t.status,
        startTime: t.startTime,
        endTime: t.endTime,
        distanceKm: t.distanceKm,
        durationMinutes: t.durationMinutes,
        startAddress: t.startAddress,
        endAddress: t.endAddress,
        maxSpeedKmh: t.maxSpeedKmh,
        averageSpeedKmh: t.averageSpeedKmh,
        safetyScore: t.safetyScore,
        vehicle: t.vehicleId,
        driver: t.driverId,
      })),
      total,
      page: pageNum,
      totalPages: Math.ceil(total / limitNum),
    });
  } catch (err) {
    console.error('GET /api/v1/trips error:', err);
    res.status(500).json({ error: 'Server error retrieving trips' });
  }
});

// GET /api/v1/trips/:id
router.get('/:id', async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid trip ID format' });
    }

    const trip = await Trip.findOne({
      _id: req.params.id,
      organizationId: req.organizationId,
    })
      .populate('vehicleId', 'plateNumber nickname type make model year')
      .populate('driverId', 'name phone safetyScore licenseNumber');

    if (!trip) {
      return res.status(404).json({ error: 'Trip not found or unauthorized' });
    }

    res.json({
      trip: {
        id: trip._id.toString(),
        tripNumber: trip.tripNumber,
        status: trip.status,
        startTime: trip.startTime,
        endTime: trip.endTime,
        distanceKm: trip.distanceKm,
        durationMinutes: trip.durationMinutes,
        startAddress: trip.startAddress,
        endAddress: trip.endAddress,
        startLocation: trip.startLocation,
        endLocation: trip.endLocation,
        maxSpeedKmh: trip.maxSpeedKmh,
        averageSpeedKmh: trip.averageSpeedKmh,
        safetyScore: trip.safetyScore,
        polyline: trip.polyline || [],
        plannedPolyline: trip.plannedPolyline || [],
        stops: trip.stops || [],
        idleEvents: trip.idleEvents || [],
        vehicle: trip.vehicleId
          ? {
              id: trip.vehicleId._id.toString(),
              plateNumber: trip.vehicleId.plateNumber,
              nickname: trip.vehicleId.nickname || trip.vehicleId.plateNumber,
              type: trip.vehicleId.type,
              make: trip.vehicleId.make,
              model: trip.vehicleId.model,
            }
          : null,
        driver: trip.driverId
          ? {
              id: trip.driverId._id.toString(),
              name: trip.driverId.name,
              phone: trip.driverId.phone,
              safetyScore: trip.driverId.safetyScore,
              licenseNumber: trip.driverId.licenseNumber,
            }
          : null,
      },
    });
  } catch (err) {
    console.error('GET /api/v1/trips/:id error:', err);
    res.status(500).json({ error: 'Server error retrieving trip details' });
  }
});

module.exports = router;
