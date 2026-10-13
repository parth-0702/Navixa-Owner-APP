const express = require('express');
const mongoose = require('mongoose');
const Alert = require('../models/Alert');
const AuditLog = require('../models/AuditLog');
const { verifyToken, requireRole, scopeToOrganization } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken, scopeToOrganization);

// Grouping helper
function groupAlerts(alerts) {
  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const yesterdayStart = todayStart - 24 * 60 * 60 * 1000;

  const groups = {
    today: [],
    yesterday: [],
    earlier: [],
  };

  for (const a of alerts) {
    const t = new Date(a.timestamp).getTime();
    if (t >= todayStart) {
      groups.today.push(a);
    } else if (t >= yesterdayStart) {
      groups.yesterday.push(a);
    } else {
      groups.earlier.push(a);
    }
  }

  return groups;
}

// GET /api/v1/alerts
router.get('/', async (req, res) => {
  try {
    const { status = 'all', type, page = 1, limit = 20 } = req.query;
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));

    const filter = {
      organizationId: req.organizationId,
      isDeleted: false,
    };

    if (status === 'unread') {
      filter.isRead = false;
    } else if (status === 'critical') {
      filter.severity = 'critical';
      filter.isAcknowledged = false;
    }

    if (type && type !== 'all') {
      filter.type = type;
    }

    const [total, unreadCount, criticalCount, alerts] = await Promise.all([
      Alert.countDocuments(filter),
      Alert.countDocuments({ organizationId: req.organizationId, isRead: false, isDeleted: false }),
      Alert.countDocuments({
        organizationId: req.organizationId,
        severity: 'critical',
        isAcknowledged: false,
        isDeleted: false,
      }),
      Alert.find(filter)
        .sort({ timestamp: -1 })
        .skip((pageNum - 1) * limitNum)
        .limit(limitNum)
        .populate('vehicleId', 'plateNumber nickname type')
        .populate('acknowledgedBy', 'name email'),
    ]);

    const formatted = alerts.map((a) => ({
      id: a._id.toString(),
      type: a.type,
      severity: a.severity,
      title: a.title,
      description: a.description,
      location: a.location?.name || '',
      coordinates: a.location?.coordinates || [0, 0],
      timestamp: a.timestamp,
      isRead: a.isRead || (a.readBy && a.readBy.some((uid) => uid.toString() === req.user.userId)),
      isAcknowledged: a.isAcknowledged,
      acknowledgedAt: a.acknowledgedAt,
      acknowledgedBy: a.acknowledgedBy ? a.acknowledgedBy.name : null,
      acknowledgmentNote: a.acknowledgmentNote,
      vehicle: a.vehicleId
        ? {
            id: a.vehicleId._id.toString(),
            plateNumber: a.vehicleId.plateNumber,
            nickname: a.vehicleId.nickname || a.vehicleId.plateNumber,
            type: a.vehicleId.type,
          }
        : null,
    }));

    res.json({
      alerts: formatted,
      groups: groupAlerts(formatted),
      total,
      unreadCount,
      criticalCount,
      page: pageNum,
      totalPages: Math.ceil(total / limitNum),
    });
  } catch (err) {
    console.error('GET /api/v1/alerts error:', err);
    res.status(500).json({ error: 'Server error retrieving alerts' });
  }
});

// PATCH /api/v1/alerts/:id/read
router.patch('/:id/read', async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid alert ID' });
    }

    const alert = await Alert.findOne({
      _id: req.params.id,
      organizationId: req.organizationId,
    });
    if (!alert) return res.status(404).json({ error: 'Alert not found' });

    alert.isRead = true;
    if (!alert.readBy.some((id) => id.toString() === req.user.userId)) {
      alert.readBy.push(req.user.userId);
    }
    await alert.save();

    res.json({ success: true, id: alert._id.toString(), isRead: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error marking alert as read' });
  }
});

// PATCH /api/v1/alerts/:id/acknowledge (Owner and Manager only! Viewer denied)
router.patch('/:id/acknowledge', requireRole('owner', 'manager'), async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid alert ID' });
    }

    const alert = await Alert.findOne({
      _id: req.params.id,
      organizationId: req.organizationId,
    });
    if (!alert) return res.status(404).json({ error: 'Alert not found' });

    const { note = '' } = req.body;
    alert.isAcknowledged = true;
    alert.acknowledgedBy = req.user.userId;
    alert.acknowledgedAt = new Date();
    alert.acknowledgmentNote = note.trim();
    alert.isRead = true;
    await alert.save();

    // Log audit
    await AuditLog.create({
      organizationId: req.organizationId,
      userId: req.user.userId,
      action: 'alert_acknowledged',
      targetType: 'Alert',
      targetId: alert._id,
      metadata: { note: alert.acknowledgmentNote },
    }).catch((e) => console.error('AuditLog error:', e.message));

    // Emit socket event if io is configured on app
    const io = req.app.get('io');
    if (io) {
      const room = `org:${req.organizationId.toString()}`;
      io.to(room).emit('alert.acknowledged', {
        id: alert._id.toString(),
        isAcknowledged: true,
        acknowledgedBy: req.user.name || 'Staff',
        acknowledgedAt: alert.acknowledgedAt,
        note: alert.acknowledgmentNote,
      });
    }

    res.json({
      success: true,
      alert: {
        id: alert._id.toString(),
        isAcknowledged: true,
        acknowledgedAt: alert.acknowledgedAt,
        acknowledgmentNote: alert.acknowledgmentNote,
      },
    });
  } catch (err) {
    console.error('Acknowledge alert error:', err);
    res.status(500).json({ error: 'Server error acknowledging alert' });
  }
});

// PATCH /api/v1/alerts/read-all
router.patch('/read-all', async (req, res) => {
  try {
    const result = await Alert.updateMany(
      { organizationId: req.organizationId, isRead: false },
      { $set: { isRead: true }, $addToSet: { readBy: req.user.userId } }
    );
    res.json({ success: true, message: 'All alerts marked as read', modifiedCount: result.modifiedCount });
  } catch (err) {
    res.status(500).json({ error: 'Server error marking all alerts as read' });
  }
});

module.exports = router;
