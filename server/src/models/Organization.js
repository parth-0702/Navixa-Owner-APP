const mongoose = require('mongoose');

const organizationSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Organization name is required'],
      trim: true,
    },
    code: {
      type: String,
      unique: true,
      sparse: true,
      uppercase: true,
      trim: true,
    },
    contactEmail: {
      type: String,
      trim: true,
      lowercase: true,
    },
    contactPhone: {
      type: String,
      trim: true,
    },
    address: {
      street: String,
      city: String,
      state: String,
      country: String,
      postalCode: String,
    },
    plan: {
      type: String,
      enum: ['starter', 'professional', 'enterprise'],
      default: 'professional',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    settings: {
      speedLimitThresholdKmh: { type: Number, default: 80 },
      idleTimeThresholdMinutes: { type: Number, default: 15 },
      offlineThresholdMinutes: { type: Number, default: 20 },
      lowFuelThresholdPercent: { type: Number, default: 15 },
    },
  },
  {
    timestamps: true,
  }
);

// Compatibility alias for Company
module.exports = mongoose.model('Organization', organizationSchema);
