const express = require('express');
const NotificationPreference = require('../models/NotificationPreference');
const AuditLog = require('../models/AuditLog');
const { verifyToken, scopeToOrganization } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken, scopeToOrganization);

// GET /api/v1/notification-preferences
router.get('/', async (req, res) => {
  try {
    let prefs = await NotificationPreference.findOne({
      userId: req.user.userId,
    });

    if (!prefs) {
      prefs = await NotificationPreference.create({
        userId: req.user.userId,
        organizationId: req.organizationId,
        pushNotifications: true,
        emailNotifications: true,
        quietHoursEnabled: false,
        quietHoursStart: '22:00',
        quietHoursEnd: '07:00',
        criticalAlerts: true,
        overspeedAlerts: true,
        idleAlerts: true,
        geofenceAlerts: true,
        routeDeviationAlerts: true,
        lowFuelAlerts: true,
        offlineAlerts: true,
        maintenanceReminders: true,
      });
    }

    res.json({ preferences: prefs });
  } catch (err) {
    console.error('GET /api/v1/notification-preferences error:', err);
    res.status(500).json({ error: 'Server error retrieving notification preferences' });
  }
});

// PUT /api/v1/notification-preferences
router.put('/', async (req, res) => {
  try {
    const {
      pushNotifications,
      emailNotifications,
      quietHoursEnabled,
      quietHoursStart,
      quietHoursEnd,
      criticalAlerts,
      overspeedAlerts,
      idleAlerts,
      geofenceAlerts,
      routeDeviationAlerts,
      lowFuelAlerts,
      offlineAlerts,
      maintenanceReminders,
    } = req.body;

    let prefs = await NotificationPreference.findOne({
      userId: req.user.userId,
    });

    if (!prefs) {
      prefs = new NotificationPreference({
        userId: req.user.userId,
        organizationId: req.organizationId,
      });
    }

    if (pushNotifications !== undefined) prefs.pushNotifications = Boolean(pushNotifications);
    if (emailNotifications !== undefined) prefs.emailNotifications = Boolean(emailNotifications);
    if (quietHoursEnabled !== undefined) prefs.quietHoursEnabled = Boolean(quietHoursEnabled);
    if (quietHoursStart) prefs.quietHoursStart = quietHoursStart;
    if (quietHoursEnd) prefs.quietHoursEnd = quietHoursEnd;
    if (criticalAlerts !== undefined) prefs.criticalAlerts = Boolean(criticalAlerts);
    if (overspeedAlerts !== undefined) prefs.overspeedAlerts = Boolean(overspeedAlerts);
    if (idleAlerts !== undefined) prefs.idleAlerts = Boolean(idleAlerts);
    if (geofenceAlerts !== undefined) prefs.geofenceAlerts = Boolean(geofenceAlerts);
    if (routeDeviationAlerts !== undefined) prefs.routeDeviationAlerts = Boolean(routeDeviationAlerts);
    if (lowFuelAlerts !== undefined) prefs.lowFuelAlerts = Boolean(lowFuelAlerts);
    if (offlineAlerts !== undefined) prefs.offlineAlerts = Boolean(offlineAlerts);
    if (maintenanceReminders !== undefined) prefs.maintenanceReminders = Boolean(maintenanceReminders);

    await prefs.save();

    await AuditLog.create({
      organizationId: req.organizationId,
      userId: req.user.userId,
      action: 'preferences_update',
      targetType: 'NotificationPreference',
      targetId: prefs._id,
    }).catch((e) => console.error('AuditLog error:', e.message));

    res.json({ success: true, preferences: prefs });
  } catch (err) {
    console.error('PUT /api/v1/notification-preferences error:', err);
    res.status(500).json({ error: 'Server error saving notification preferences' });
  }
});

module.exports = router;
