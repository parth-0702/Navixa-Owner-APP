const express = require('express');
const Driver = require('../models/Driver');
const Vehicle = require('../models/Vehicle');
const { verifyToken, scopeToOrganization } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken, scopeToOrganization);

router.get('/', async (req, res) => {
  try {
    const { search, status } = req.query;
    const filter = { organizationId: req.organizationId, isDeleted: false };
    if (status && status !== 'all') filter.status = status;
    if (search && search.trim()) {
      const value = new RegExp(search.trim(), 'i');
      filter.$or = [{ name: value }, { phone: value }, { licenseNumber: value }];
    }

    const drivers = await Driver.find(filter).sort({ status: 1, name: 1 });
    const vehicleIds = drivers.map((d) => d.currentVehicleId).filter(Boolean);
    const vehicles = await Vehicle.find({
      organizationId: req.organizationId,
      _id: { $in: vehicleIds },
      isDeleted: false,
    }).select('plateNumber nickname status');
    const vehicleMap = new Map(vehicles.map((v) => [v._id.toString(), v]));

    res.json({
      drivers: drivers.map((d) => {
        const vehicle = d.currentVehicleId ? vehicleMap.get(d.currentVehicleId.toString()) : null;
        return {
          id: d._id.toString(),
          name: d.name,
          phone: d.phone,
          licenseNumber: d.licenseNumber,
          safetyScore: d.safetyScore,
          totalTrips: d.totalTrips,
          onTimeRate: d.onTimeRate,
          status: d.status,
          avatarUrl: d.avatarUrl,
          currentVehicle: vehicle
            ? {
                id: vehicle._id.toString(),
                plateNumber: vehicle.plateNumber,
                nickname: vehicle.nickname || vehicle.plateNumber,
                status: vehicle.status,
              }
            : null,
        };
      }),
    });
  } catch (err) {
    console.error('GET /api/v1/drivers error:', err);
    res.status(500).json({ error: 'Server error retrieving drivers' });
  }
});

module.exports = router;
