const express = require('express');
const DeviceToken = require('../models/DeviceToken');
const { verifyToken, scopeToOrganization } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken, scopeToOrganization);

// POST /api/v1/devices/register
router.post('/register', async (req, res) => {
  try {
    const { token, platform = 'android', deviceModel = '' } = req.body;
    if (!token || typeof token !== 'string') {
      return res.status(400).json({ error: 'Valid FCM token is required' });
    }

    const device = await DeviceToken.findOneAndUpdate(
      { token: token.trim() },
      {
        userId: req.user.userId,
        organizationId: req.organizationId,
        platform,
        deviceModel,
        lastUsedAt: new Date(),
      },
      { upsert: true, new: true }
    );

    res.status(201).json({ success: true, deviceId: device._id.toString() });
  } catch (err) {
    console.error('Device register error:', err);
    res.status(500).json({ error: 'Server error registering device token' });
  }
});

// DELETE /api/v1/devices/:token
router.delete('/:token', async (req, res) => {
  try {
    const { token } = req.params;
    await DeviceToken.deleteOne({
      token,
      userId: req.user.userId,
    });
    res.json({ success: true, message: 'Device token unregistered' });
  } catch (err) {
    res.status(500).json({ error: 'Server error unregistering device' });
  }
});

module.exports = router;
