const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], default: [0, 0] }, // [lng, lat]
    address: { type: String, default: '' },
    speed: { type: Number, default: 0 },
    heading: { type: Number, default: 0 },
    timestamp: { type: Date, default: Date.now },
  },
  { _id: false }
);

const vehicleSchema = new mongoose.Schema(
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
    plateNumber: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
    },
    nickname: {
      type: String,
      trim: true,
      default: '',
    },
    type: {
      type: String,
      enum: ['truck', 'van', 'car', 'motorcycle', 'other'],
      default: 'truck',
    },
    make: { type: String, default: '' },
    model: { type: String, default: '' },
    year: { type: Number, default: 2024 },
    status: {
      type: String,
      enum: ['moving', 'idle', 'parked', 'offline', 'maintenance', 'available'],
      default: 'parked',
      index: true,
    },
    speedKmh: { type: Number, default: 0 },
    heading: { type: Number, default: 0 },
    ignition: { type: Boolean, default: false },
    fuelType: {
      type: String,
      enum: ['diesel', 'petrol', 'electric', 'hybrid'],
      default: 'diesel',
    },
    currentFuelLevel: { type: Number, min: 0, max: 100, default: 80 },
    batteryLevel: { type: Number, min: 0, max: 100, default: 100 },
    odometerKm: { type: Number, default: 0 },
    todayDistanceKm: { type: Number, default: 0 },
    hasHardwareGps: { type: Boolean, default: true },
    lastKnownLocation: {
      type: locationSchema,
      default: null,
    },
    lastLocationUpdatedAt: { type: Date, default: Date.now },
    assignedDriverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Driver',
      default: null,
    },
    currentTripId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Trip',
      default: null,
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

vehicleSchema.pre('save', function (next) {
  if (this.organizationId && !this.companyId) {
    this.companyId = this.organizationId;
  } else if (this.companyId && !this.organizationId) {
    this.organizationId = this.companyId;
  }
  next();
});

vehicleSchema.index({ 'lastKnownLocation.coordinates': '2dsphere' });

module.exports = mongoose.model('Vehicle', vehicleSchema);
