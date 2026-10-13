const express = require('express');
const mongoose = require('mongoose');
const User = require('../models/User');
const AuditLog = require('../models/AuditLog');
const { verifyToken, requireRole, scopeToOrganization } = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken, scopeToOrganization);

// GET /api/v1/team
router.get('/', async (req, res) => {
  try {
    const teamMembers = await User.find({
      organizationId: req.organizationId,
    })
      .select('-passwordHash -currentRefreshTokenHash')
      .sort({ createdAt: -1 });

    res.json({
      team: teamMembers.map((m) => ({
        id: m._id.toString(),
        name: m.name,
        email: m.email,
        phone: m.phone,
        role: m.role,
        isActive: m.isActive,
        lastLoginAt: m.lastLoginAt,
        createdAt: m.createdAt,
      })),
    });
  } catch (err) {
    console.error('GET /api/v1/team error:', err);
    res.status(500).json({ error: 'Server error retrieving team members' });
  }
});

// POST /api/v1/team/invitations (Owner only)
router.post('/invitations', requireRole('owner'), async (req, res) => {
  try {
    const { name, email, phone, role = 'viewer', tempPassword } = req.body;
    if (!name || (!email && !phone)) {
      return res.status(400).json({ error: 'Name and either email or phone are required' });
    }

    const allowedRoles = ['manager', 'viewer'];
    if (!allowedRoles.includes(role)) {
      return res.status(400).json({ error: 'Allowed roles for invitation: manager, viewer' });
    }

    const defaultPassword = tempPassword || 'NavixaTemp2026!';
    const passwordHash = await User.hashPassword(defaultPassword);

    const newUser = await User.create({
      name: name.trim(),
      email: email ? email.trim().toLowerCase() : undefined,
      phone: phone ? phone.trim() : undefined,
      role,
      organizationId: req.organizationId,
      companyId: req.organizationId,
      passwordHash,
      isActive: true,
    });

    await AuditLog.create({
      organizationId: req.organizationId,
      userId: req.user.userId,
      action: 'team_invite',
      targetType: 'User',
      targetId: newUser._id,
      metadata: { role, invitedEmail: email },
    }).catch((e) => console.error('AuditLog error:', e.message));

    res.status(201).json({
      success: true,
      user: {
        id: newUser._id.toString(),
        name: newUser.name,
        email: newUser.email,
        phone: newUser.phone,
        role: newUser.role,
        isActive: newUser.isActive,
      },
      message: 'Team invitation created successfully',
    });
  } catch (err) {
    console.error('POST /api/v1/team/invitations error:', err);
    res.status(500).json({ error: err.code === 11000 ? 'A user with this email or phone already exists' : 'Server error creating invitation' });
  }
});

// PATCH /api/v1/team/:id (Owner only)
router.patch('/:id', requireRole('owner'), async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid user ID' });
    }

    const user = await User.findOne({
      _id: req.params.id,
      organizationId: req.organizationId,
    });
    if (!user) return res.status(404).json({ error: 'Team member not found' });

    // Cannot modify oneself
    if (user._id.toString() === req.user.userId) {
      return res.status(400).json({ error: 'Cannot modify your own owner account via this endpoint' });
    }

    const { role, isActive } = req.body;
    let actionType = 'team_role_update';

    if (role && ['manager', 'viewer'].includes(role)) {
      user.role = role;
    }

    if (isActive !== undefined) {
      user.isActive = Boolean(isActive);
      actionType = 'team_deactivate';
    }

    await user.save();

    await AuditLog.create({
      organizationId: req.organizationId,
      userId: req.user.userId,
      action: actionType,
      targetType: 'User',
      targetId: user._id,
      metadata: { role: user.role, isActive: user.isActive },
    }).catch((e) => console.error('AuditLog error:', e.message));

    res.json({
      success: true,
      user: {
        id: user._id.toString(),
        name: user.name,
        role: user.role,
        isActive: user.isActive,
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error updating team member' });
  }
});

module.exports = router;
