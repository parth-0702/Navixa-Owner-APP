const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Organization = require('../models/Organization');
const AuditLog = require('../models/AuditLog');
const {
  signAccessToken,
  signRefreshToken,
  verifyToken,
  JWT_REFRESH_SECRET,
} = require('../middleware/auth');

const router = express.Router();

// Stricter in-memory rate limiting for auth endpoints
const loginAttempts = new Map();
const MAX_ATTEMPTS = 10;
const WINDOW_MS = 15 * 60 * 1000; // 15 minutes

function checkRateLimit(key) {
  const now = Date.now();
  const record = loginAttempts.get(key) || { count: 0, resetAt: now + WINDOW_MS };
  if (now > record.resetAt) {
    record.count = 0;
    record.resetAt = now + WINDOW_MS;
  }
  record.count += 1;
  loginAttempts.set(key, record);
  return record.count <= MAX_ATTEMPTS;
}

// POST /api/v1/auth/login
router.post('/login', async (req, res) => {
  try {
    const { identifier, email, phone, password } = req.body;
    const loginTarget = (identifier || email || phone || '').trim();

    if (!loginTarget || !password) {
      return res.status(400).json({ error: 'Email/phone and password are required' });
    }

    const clientIp = req.ip || req.connection.remoteAddress || 'unknown';
    if (!checkRateLimit(clientIp)) {
      return res.status(429).json({ error: 'Too many login attempts. Please try again later.' });
    }

    // Match by email, phone, or loginId
    const query = {
      $or: [
        { email: loginTarget.toLowerCase() },
        { phone: loginTarget },
        { loginId: loginTarget.toLowerCase() },
      ],
      isActive: true,
    };

    const user = await User.findOne(query).select('+passwordHash +currentRefreshTokenHash');
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const orgId = user.organizationId || user.companyId;
    let organization = null;
    if (orgId) {
      organization = await Organization.findById(orgId);
    }

    const accessToken = signAccessToken(user);
    const refreshToken = signRefreshToken(user);

    // Store hash of current refresh token to enable safe revocation
    user.currentRefreshTokenHash = await bcrypt.hash(refreshToken, 8);
    user.lastLoginAt = new Date();
    await user.save();

    // Log audit
    if (orgId) {
      await AuditLog.create({
        organizationId: orgId,
        userId: user._id,
        action: 'login',
        targetType: 'User',
        targetId: user._id,
        ipAddress: clientIp,
      }).catch((e) => console.error('AuditLog error:', e.message));
    }

    res.json({
      accessToken,
      refreshToken,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role === 'fleet_owner' ? 'owner' : user.role,
        organizationId: orgId,
        organizationName: organization ? organization.name : 'Navixa Fleet',
        avatarUrl: user.avatarUrl,
      },
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server error during login' });
  }
});

// POST /api/v1/auth/refresh
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token required' });
    }

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    } catch (err) {
      return res.status(401).json({ error: 'Invalid or expired refresh token' });
    }

    const user = await User.findById(decoded.userId).select('+currentRefreshTokenHash');
    if (!user || !user.isActive) {
      return res.status(401).json({ error: 'User not found or account deactivated' });
    }

    // Check token revocation
    if (!user.currentRefreshTokenHash) {
      return res.status(401).json({ error: 'Refresh token has been revoked' });
    }

    const matches = await bcrypt.compare(refreshToken, user.currentRefreshTokenHash);
    if (!matches) {
      return res.status(401).json({ error: 'Revoked or outdated refresh token' });
    }

    // Issue new access token and rotate refresh token
    const newAccessToken = signAccessToken(user);
    const newRefreshToken = signRefreshToken(user);
    user.currentRefreshTokenHash = await bcrypt.hash(newRefreshToken, 8);
    await user.save();

    res.json({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    });
  } catch (err) {
    console.error('Refresh error:', err);
    res.status(500).json({ error: 'Server error during token refresh' });
  }
});

// POST /api/v1/auth/logout
router.post('/logout', verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (user) {
      user.currentRefreshTokenHash = null;
      await user.save();

      if (req.organizationId) {
        await AuditLog.create({
          organizationId: req.organizationId,
          userId: user._id,
          action: 'logout',
          targetType: 'User',
          targetId: user._id,
        }).catch((e) => console.error('AuditLog error:', e.message));
      }
    }
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (err) {
    console.error('Logout error:', err);
    res.status(500).json({ error: 'Server error during logout' });
  }
});

// GET /api/v1/auth/me
router.get('/me', verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('-passwordHash');
    if (!user) return res.status(404).json({ error: 'User not found' });

    let organization = null;
    const orgId = user.organizationId || user.companyId;
    if (orgId) {
      organization = await Organization.findById(orgId);
    }

    res.json({
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role === 'fleet_owner' ? 'owner' : user.role,
        organizationId: orgId,
        organizationName: organization ? organization.name : 'Navixa Fleet',
        avatarUrl: user.avatarUrl,
        createdAt: user.createdAt,
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT /api/v1/auth/profile
router.put('/profile', verifyToken, async (req, res) => {
  try {
    const { name, phone, email } = req.body;
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (name) user.name = name.trim();
    if (phone) user.phone = phone.trim();
    if (email) user.email = email.trim().toLowerCase();

    await user.save();
    res.json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error updating profile' });
  }
});

// POST /api/v1/auth/change-password
router.post('/change-password', verifyToken, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Current password and new password are required' });
    }
    if (newPassword.length < 8) {
      return res.status(400).json({ error: 'New password must be at least 8 characters long' });
    }

    const user = await User.findById(req.user.userId).select('+passwordHash');
    if (!user) return res.status(404).json({ error: 'User not found' });

    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(401).json({ error: 'Current password is incorrect' });
    }

    user.passwordHash = await User.hashPassword(newPassword);
    await user.save();

    res.json({ success: true, message: 'Password updated successfully' });
  } catch (err) {
    res.status(500).json({ error: 'Server error changing password' });
  }
});

module.exports = router;
