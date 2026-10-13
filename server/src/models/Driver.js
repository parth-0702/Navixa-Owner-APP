const mongoose = require('mongoose');

const driverSchema = new mongoose.Schema(
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
    name: {
      type: String,
      required: true,
      trim: true,
    },
    phone: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      trim: true,
      lowercase: true,
    },
    licenseNumber: {
      type: String,
      trim: true,
      default: '',
    },
    safetyScore: {
      type: Number,
      min: 0,
      max: 100,
      default: 95,
    },
    totalTrips: {
      type: Number,
      default: 0,
    },
    onTimeRate: {
      type: String,
      default: '98%',
    },
    status: {
      type: String,
      enum: ['active', 'on_duty', 'off_duty', 'inactive'],
      default: 'active',
    },
    currentVehicleId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Vehicle',
      default: null,
    },
    avatarUrl: {
      type: String,
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

driverSchema.pre('save', function (next) {
  if (this.organizationId && !this.companyId) {
    this.companyId = this.organizationId;
  } else if (this.companyId && !this.organizationId) {
    this.organizationId = this.companyId;
  }
  next();
});

module.exports = mongoose.model('Driver', driverSchema);
