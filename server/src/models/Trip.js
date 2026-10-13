const mongoose = require('mongoose');

const stopSchema = new mongoose.Schema(
  {
    name: { type: String, default: '' },
    arrivalTime: { type: Date },
    departureTime: { type: Date },
    durationMinutes: { type: Number, default: 0 },
    coordinates: { type: [Number], default: [0, 0] }, // [lng, lat]
  },
  { _id: false }
);

const idleEventSchema = new mongoose.Schema(
  {
    startTime: { type: Date },
    endTime: { type: Date },
    durationMinutes: { type: Number, default: 0 },
    coordinates: { type: [Number], default: [0, 0] }, // [lng, lat]
  },
  { _id: false }
);

const tripSchema = new mongoose.Schema(
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
      required: true,
      index: true,
    },
    driverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Driver',
      required: true,
      index: true,
    },
    tripNumber: {
      type: String,
      required: true,
      trim: true,
    },
    status: {
      type: String,
      enum: ['scheduled', 'in_progress', 'completed', 'cancelled'],
      default: 'scheduled',
      index: true,
    },
    startTime: { type: Date, default: Date.now },
    endTime: { type: Date, default: null },
    distanceKm: { type: Number, default: 0 },
    durationMinutes: { type: Number, default: 0 },
    startAddress: { type: String, default: '' },
    endAddress: { type: String, default: '' },
    startLocation: {
      type: [Number],
      default: [0, 0], // [lng, lat]
    },
    endLocation: {
      type: [Number],
      default: [0, 0], // [lng, lat]
    },
    polyline: [
      {
        lat: { type: Number, required: true },
        lng: { type: Number, required: true },
      },
    ],
    plannedPolyline: [
      {
        lat: { type: Number, required: true },
        lng: { type: Number, required: true },
      },
    ],
    stops: [stopSchema],
    idleEvents: [idleEventSchema],
    maxSpeedKmh: { type: Number, default: 0 },
    averageSpeedKmh: { type: Number, default: 0 },
    safetyScore: { type: Number, default: 100 },
  },
  {
    timestamps: true,
  }
);

tripSchema.pre('save', function (next) {
  if (this.organizationId && !this.companyId) {
    this.companyId = this.organizationId;
  } else if (this.companyId && !this.organizationId) {
    this.organizationId = this.companyId;
  }
  next();
});

module.exports = mongoose.model('Trip', tripSchema);
