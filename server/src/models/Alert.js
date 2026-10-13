const mongoose = require('mongoose');

const alertSchema = new mongoose.Schema(
  {
    organizationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      required: true,
      index: true,
    },
    companyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      required: true,
      index: true,
    },
    vehicleId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Vehicle',
      default: null,
      index: true,
    },
    tripId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Trip',
      default: null,
    },
    type: {
      type: String,
      enum: [
        'vehicle_started',
        'vehicle_stopped',
        'overspeed',
        'long_idle',
        'geofence_entry',
        'geofence_exit',
        'route_deviation',
        'device_offline',
        'low_fuel',
        'low_battery',
        'maintenance_due',
        'safety_event',
      ],
      required: true,
      index: true,
    },
    severity: {
      type: String,
      enum: ['info', 'warning', 'critical'],
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      default: '',
    },
    location: {
      name: { type: String, default: '' },
      coordinates: { type: [Number], default: [0, 0] }, // [lng, lat]
    },
    timestamp: {
      type: Date,
      default: Date.now,
      index: true,
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    readBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    isAcknowledged: {
      type: Boolean,
      default: false,
      index: true,
    },
    acknowledgedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    acknowledgedAt: {
      type: Date,
      default: null,
    },
    acknowledgmentNote: {
      type: String,
      default: '',
    },
    isDeleted: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

alertSchema.pre('save', function (next) {
  if (this.organizationId && !this.companyId) {
    this.companyId = this.organizationId;
  } else if (this.companyId && !this.organizationId) {
    this.organizationId = this.companyId;
  }
  next();
});

module.exports = mongoose.model('Alert', alertSchema);
