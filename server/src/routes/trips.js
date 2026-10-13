const express = require('express');
const mongoose = require('mongoose');
const Trip = require('../models/Trip');
const { verifyToken, scopeToOrganization } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken, scopeToOrganization);

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
