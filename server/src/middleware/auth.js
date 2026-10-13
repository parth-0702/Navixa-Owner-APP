const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'navixa_owner_jwt_secret_dev_key_2026';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'navixa_owner_jwt_refresh_dev_key_2026';
const ACCESS_EXPIRES_IN = process.env.JWT_ACCESS_EXPIRES_IN || '15m';
const REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '7d';

function signAccessToken(user) {
  const orgId = user.organizationId?.toString() || user.companyId?.toString() || null;
  return jwt.sign(
    {
      userId: user._id.toString(),
      role: user.role,
      organizationId: orgId,
      companyId: orgId,
      name: user.name,
      email: user.email,
    },
    JWT_SECRET,
    { expiresIn: ACCESS_EXPIRES_IN }
  );
}

function signRefreshToken(user) {
  return jwt.sign(
    { userId: user._id.toString() },
    JWT_REFRESH_SECRET,
    { expiresIn: REFRESH_EXPIRES_IN }
  );
}

function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const orgId = decoded.organizationId || decoded.companyId || null;
    req.user = {
      userId: decoded.userId,
      role: decoded.role === 'fleet_owner' ? 'owner' : decoded.role,
      organizationId: orgId,
      companyId: orgId,
      name: decoded.name,
      email: decoded.email,
    };
    req.organizationId = orgId;
    req.companyId = orgId;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired', code: 'TOKEN_EXPIRED' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    const currentRole = req.user.role === 'fleet_owner' ? 'owner' : req.user.role;
    const normalizedRoles = roles.map((r) => (r === 'fleet_owner' ? 'owner' : r));

    if (!normalizedRoles.includes(currentRole) && currentRole !== 'admin') {
      return res.status(403).json({
        error: 'Access denied: Insufficient permissions for this action',
        required: roles,
        current: currentRole,
      });
    }
    next();
  };
}

function scopeToOrganization(req, res, next) {
  if (req.user && req.user.role !== 'admin') {
    if (!req.user.organizationId) {
      return res.status(403).json({ error: 'User is not linked to any active organization' });
    }
    req.organizationId = req.user.organizationId;
    req.companyId = req.user.organizationId;
  }
  next();
}

module.exports = {
  signAccessToken,
  signRefreshToken,
  verifyToken,
  requireRole,
  scopeToOrganization,
  JWT_SECRET,
  JWT_REFRESH_SECRET,
};
