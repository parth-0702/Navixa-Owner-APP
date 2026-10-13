require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const Organization = require('./models/Organization');
const User = require('./models/User');
const Vehicle = require('./models/Vehicle');
const Driver = require('./models/Driver');
const Trip = require('./models/Trip');
const Alert = require('./models/Alert');
const NotificationPreference = require('./models/NotificationPreference');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/navixa_fleet';

async function seedDatabase() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB for seeding...');

    // Clear existing data for clean seed
    await Promise.all([
      Organization.deleteMany({ code: 'APEX' }),
      User.deleteMany({ email: { $in: ['owner@navixa.com', 'manager@navixa.com', 'viewer@navixa.com'] } }),
      Vehicle.deleteMany({ plateNumber: { $regex: /^NX-/ } }),
      Driver.deleteMany({ email: { $regex: /@apexlogistics\.com$/ } }),
      Trip.deleteMany({ tripNumber: { $regex: /^APX-TRIP-/ } }),
      Alert.deleteMany({ title: { $regex: /Overspeed|Braking|Geofence|Offline|Started|Maintenance/ } }),
    ]);

    // 1. Create Organization
    const org = await Organization.create({
      name: 'Apex Logistics Fleet',
      code: 'APEX',
      contactEmail: 'ops@apexlogistics.com',
      contactPhone: '+1 (555) 019-2831',
      address: {
        street: '450 Innovation Parkway',
        city: 'Bangalore',
        state: 'Karnataka',
        country: 'India',
        postalCode: '560100',
      },
      plan: 'enterprise',
      isActive: true,
      settings: {
        speedLimitThresholdKmh: 80,
        idleTimeThresholdMinutes: 15,
        offlineThresholdMinutes: 20,
        lowFuelThresholdPercent: 15,
      },
    });
    console.log(`✅ Created Organization: ${org.name} (${org._id})`);

    // 2. Create Users (Owner, Manager, Viewer)
    const ownerPasswordHash = await bcrypt.hash('OwnerPass123!', 10);
    const managerPasswordHash = await bcrypt.hash('ManagerPass123!', 10);
    const viewerPasswordHash = await bcrypt.hash('ViewerPass123!', 10);

    const [owner, manager, viewer] = await Promise.all([
      User.create({
        name: 'Parth Patel',
        email: 'owner@navixa.com',
        phone: '+1234567890',
        role: 'owner',
        organizationId: org._id,
        companyId: org._id,
        passwordHash: ownerPasswordHash,
        isActive: true,
      }),
      User.create({
        name: 'Sarah Jenkins',
        email: 'manager@navixa.com',
        phone: '+1234567891',
        role: 'manager',
        organizationId: org._id,
        companyId: org._id,
        passwordHash: managerPasswordHash,
        isActive: true,
      }),
      User.create({
        name: 'David Chen',
        email: 'viewer@navixa.com',
        phone: '+1234567892',
        role: 'viewer',
        organizationId: org._id,
        companyId: org._id,
        passwordHash: viewerPasswordHash,
        isActive: true,
      }),
    ]);
    console.log(`✅ Created Users: Owner (${owner.email}), Manager (${manager.email}), Viewer (${viewer.email})`);

    // Create Notification Preferences
    await Promise.all([
      NotificationPreference.create({
        userId: owner._id,
        organizationId: org._id,
        pushNotifications: true,
        emailNotifications: true,
        criticalAlerts: true,
        overspeedAlerts: true,
        idleAlerts: true,
        geofenceAlerts: true,
      }),
      NotificationPreference.create({
        userId: manager._id,
        organizationId: org._id,
        pushNotifications: true,
        emailNotifications: true,
        criticalAlerts: true,
      }),
      NotificationPreference.create({
        userId: viewer._id,
        organizationId: org._id,
        pushNotifications: false,
        emailNotifications: true,
        criticalAlerts: true,
      }),
    ]);

    // 3. Create Drivers
    const drivers = await Driver.create([
      {
        organizationId: org._id,
        companyId: org._id,
        name: 'John Doe',
        phone: '+15550101',
        email: 'john.doe@apexlogistics.com',
        licenseNumber: 'KA-01-2021-9874',
        safetyScore: 96,
        totalTrips: 142,
        onTimeRate: '98%',
        status: 'on_duty',
      },
      {
        organizationId: org._id,
        companyId: org._id,
        name: 'Alex Rivera',
        phone: '+15550102',
        email: 'alex.rivera@apexlogistics.com',
        licenseNumber: 'KA-01-2022-3112',
        safetyScore: 92,
        totalTrips: 89,
        onTimeRate: '95%',
        status: 'on_duty',
      },
      {
        organizationId: org._id,
        companyId: org._id,
        name: 'Sarah Connor',
        phone: '+15550103',
        email: 'sarah.connor@apexlogistics.com',
        licenseNumber: 'KA-01-2019-7431',
        safetyScore: 98,
        totalTrips: 215,
        onTimeRate: '99%',
        status: 'off_duty',
      },
      {
        organizationId: org._id,
        companyId: org._id,
        name: 'Michael Scott',
        phone: '+15550104',
        email: 'michael.scott@apexlogistics.com',
        licenseNumber: 'KA-01-2023-4556',
        safetyScore: 81,
        totalTrips: 44,
        onTimeRate: '90%',
        status: 'on_duty',
      },
      {
        organizationId: org._id,
        companyId: org._id,
        name: 'Emma Watson',
        phone: '+15550105',
        email: 'emma.watson@apexlogistics.com',
        licenseNumber: 'KA-01-2020-6621',
        safetyScore: 95,
        totalTrips: 110,
        onTimeRate: '97%',
        status: 'off_duty',
      },
      {
        organizationId: org._id,
        companyId: org._id,
        name: 'David Miller',
        phone: '+15550106',
        email: 'david.miller@apexlogistics.com',
        licenseNumber: 'KA-01-2018-1290',
        safetyScore: 94,
        totalTrips: 168,
        onTimeRate: '96%',
        status: 'inactive',
      },
    ]);
    console.log(`✅ Created ${drivers.length} Drivers`);

    // 4. Create 6 Vehicles in different statuses
    const now = new Date();
    const staleTime = new Date(now.getTime() - 48 * 60 * 1000); // 48 mins ago

    const vehicles = await Vehicle.create([
      // 1. Moving (Apex Titan)
      {
        organizationId: org._id,
        companyId: org._id,
        plateNumber: 'NX-TRK-101',
        nickname: 'Apex Titan',
        type: 'truck',
        make: 'Volvo',
        model: 'FH16 750',
        year: 2024,
        status: 'moving',
        speedKmh: 68,
        heading: 142,
        ignition: true,
        fuelType: 'diesel',
        currentFuelLevel: 82,
        odometerKm: 38450,
        todayDistanceKm: 146.5,
        assignedDriverId: drivers[0]._id,
        lastKnownLocation: {
          type: 'Point',
          coordinates: [77.5946, 12.9716],
          address: 'MG Road, Central Business District, Bangalore',
          speed: 68,
          heading: 142,
          timestamp: now,
        },
        lastLocationUpdatedAt: now,
      },
      // 2. Idle (City Express)
      {
        organizationId: org._id,
        companyId: org._id,
        plateNumber: 'NX-VAN-102',
        nickname: 'City Express',
        type: 'van',
        make: 'Mercedes-Benz',
        model: 'Sprinter 319',
        year: 2023,
        status: 'idle',
        speedKmh: 0,
        heading: 45,
        ignition: true,
        fuelType: 'diesel',
        currentFuelLevel: 64,
        odometerKm: 24100,
        todayDistanceKm: 62.8,
        assignedDriverId: drivers[1]._id,
        lastKnownLocation: {
          type: 'Point',
          coordinates: [77.6389, 12.9172],
          address: '80 Feet Road, Koramangala 4th Block, Bangalore',
          speed: 0,
          heading: 45,
          timestamp: now,
        },
        lastLocationUpdatedAt: now,
      },
      // 3. Parked (Iron Hauler)
      {
        organizationId: org._id,
        companyId: org._id,
        plateNumber: 'NX-TRK-103',
        nickname: 'Iron Hauler',
        type: 'truck',
        make: 'Scania',
        model: 'R500 V8',
        year: 2024,
        status: 'parked',
        speedKmh: 0,
        heading: 0,
        ignition: false,
        fuelType: 'diesel',
        currentFuelLevel: 94,
        odometerKm: 42180,
        todayDistanceKm: 0,
        assignedDriverId: drivers[2]._id,
        lastKnownLocation: {
          type: 'Point',
          coordinates: [77.7275, 12.984],
          address: 'Whitefield Logistics Hub, ITPL Main Rd, Bangalore',
          speed: 0,
          heading: 0,
          timestamp: new Date(now.getTime() - 4 * 60 * 60 * 1000),
        },
        lastLocationUpdatedAt: new Date(now.getTime() - 4 * 60 * 60 * 1000),
      },
      // 4. Offline (Metro Carrier)
      {
        organizationId: org._id,
        companyId: org._id,
        plateNumber: 'NX-VAN-104',
        nickname: 'Metro Carrier',
        type: 'van',
        make: 'Ford',
        model: 'Transit 350',
        year: 2022,
        status: 'offline',
        speedKmh: 0,
        heading: 270,
        ignition: false,
        fuelType: 'diesel',
        currentFuelLevel: 38,
        odometerKm: 61300,
        todayDistanceKm: 18.2,
        assignedDriverId: drivers[4]._id,
        lastKnownLocation: {
          type: 'Point',
          coordinates: [77.534, 13.0358],
          address: 'Peenya Industrial Area Stage 1, Bangalore',
          speed: 0,
          heading: 270,
          timestamp: staleTime,
        },
        lastLocationUpdatedAt: staleTime,
      },
      // 5. Alert / Overspeed (Apex Falcon)
      {
        organizationId: org._id,
        companyId: org._id,
        plateNumber: 'NX-TRK-105',
        nickname: 'Apex Falcon',
        type: 'truck',
        make: 'MAN',
        model: 'TGX 18.510',
        year: 2024,
        status: 'moving',
        speedKmh: 94, // overspeed!
        heading: 195,
        ignition: true,
        fuelType: 'diesel',
        currentFuelLevel: 71,
        odometerKm: 19400,
        todayDistanceKm: 210.4,
        assignedDriverId: drivers[3]._id,
        lastKnownLocation: {
          type: 'Point',
          coordinates: [77.6033, 13.0112],
          address: 'Outer Ring Road, Hebbal Flyover, Bangalore',
          speed: 94,
          heading: 195,
          timestamp: now,
        },
        lastLocationUpdatedAt: now,
      },
      // 6. Maintenance (Cargo Cruiser)
      {
        organizationId: org._id,
        companyId: org._id,
        plateNumber: 'NX-VAN-106',
        nickname: 'Cargo Cruiser',
        type: 'van',
        make: 'Iveco',
        model: 'Daily 35S',
        year: 2021,
        status: 'maintenance',
        speedKmh: 0,
        heading: 90,
        ignition: false,
        fuelType: 'diesel',
        currentFuelLevel: 50,
        odometerKm: 89000,
        todayDistanceKm: 0,
        assignedDriverId: drivers[5]._id,
        lastKnownLocation: {
          type: 'Point',
          coordinates: [77.58, 12.93],
          address: 'Jayanagar Authorized Service Center, Bangalore',
          speed: 0,
          heading: 90,
          timestamp: new Date(now.getTime() - 24 * 60 * 60 * 1000),
        },
        lastLocationUpdatedAt: new Date(now.getTime() - 24 * 60 * 60 * 1000),
      },
    ]);
    console.log(`✅ Created ${vehicles.length} Vehicles`);

    // Update drivers with their current vehicle
    await Promise.all(
      drivers.map((d, idx) => {
        d.currentVehicleId = vehicles[idx]._id;
        return d.save();
      })
    );

    // 5. Create Realistic Trips
    const polylineTitan = [
      { lat: 12.925, lng: 77.583 },
      { lat: 12.934, lng: 77.586 },
      { lat: 12.945, lng: 77.591 },
      { lat: 12.958, lng: 77.593 },
      { lat: 12.9716, lng: 77.5946 },
    ];

    const polylineFalcon = [
      { lat: 13.045, lng: 77.618 },
      { lat: 13.032, lng: 77.612 },
      { lat: 13.021, lng: 77.607 },
      { lat: 13.0112, lng: 77.6033 },
    ];

    const trips = await Trip.create([
      {
        organizationId: org._id,
        companyId: org._id,
        vehicleId: vehicles[0]._id,
        driverId: drivers[0]._id,
        tripNumber: 'APX-TRIP-1001',
        status: 'in_progress',
        startTime: new Date(now.getTime() - 95 * 60 * 1000),
        distanceKm: 34.2,
        durationMinutes: 95,
        startAddress: 'Electronic City Phase 1 Logistics Park, Bangalore',
        endAddress: 'Hebbal Tech Hub, North Bangalore',
        startLocation: [77.6648, 12.8452],
        endLocation: [77.5925, 13.0358],
        polyline: polylineTitan,
        stops: [
          {
            name: 'Koramangala Transfer Hub',
            arrivalTime: new Date(now.getTime() - 60 * 60 * 1000),
            departureTime: new Date(now.getTime() - 48 * 60 * 1000),
            durationMinutes: 12,
            coordinates: [77.6245, 12.9352],
          },
        ],
        idleEvents: [
          {
            startTime: new Date(now.getTime() - 40 * 60 * 1000),
            endTime: new Date(now.getTime() - 32 * 60 * 1000),
            durationMinutes: 8,
            coordinates: [77.591, 12.945],
          },
        ],
        maxSpeedKmh: 74,
        averageSpeedKmh: 42,
        safetyScore: 98,
      },
      {
        organizationId: org._id,
        companyId: org._id,
        vehicleId: vehicles[4]._id,
        driverId: drivers[3]._id,
        tripNumber: 'APX-TRIP-1002',
        status: 'in_progress',
        startTime: new Date(now.getTime() - 45 * 60 * 1000),
        distanceKm: 28.5,
        durationMinutes: 45,
        startAddress: 'Yelahanka Freight Terminal, Bangalore',
        endAddress: 'Indiranagar Metro Distribution Centre, Bangalore',
        startLocation: [77.5963, 13.1007],
        endLocation: [77.6412, 12.9784],
        polyline: polylineFalcon,
        stops: [],
        idleEvents: [],
        maxSpeedKmh: 94,
        averageSpeedKmh: 58,
        safetyScore: 82,
      },
      {
        organizationId: org._id,
        companyId: org._id,
        vehicleId: vehicles[1]._id,
        driverId: drivers[1]._id,
        tripNumber: 'APX-TRIP-1003',
        status: 'completed',
        startTime: new Date(now.getTime() - 5 * 60 * 60 * 1000),
        endTime: new Date(now.getTime() - 3 * 60 * 60 * 1000),
        distanceKm: 48.0,
        durationMinutes: 120,
        startAddress: 'Bidadi Industrial Area, Karnataka',
        endAddress: 'Koramangala 4th Block, Bangalore',
        startLocation: [77.401, 12.802],
        endLocation: [77.6389, 12.9172],
        polyline: polylineTitan,
        stops: [
          {
            name: 'Kengeri Checkpoint',
            arrivalTime: new Date(now.getTime() - 4 * 60 * 60 * 1000),
            departureTime: new Date(now.getTime() - 3.75 * 60 * 60 * 1000),
            durationMinutes: 15,
            coordinates: [77.482, 12.911],
          },
        ],
        idleEvents: [],
        maxSpeedKmh: 65,
        averageSpeedKmh: 38,
        safetyScore: 94,
      },
    ]);
    console.log(`✅ Created ${trips.length} Trips`);

    // Assign current trip to moving vehicles
    vehicles[0].currentTripId = trips[0]._id;
    vehicles[4].currentTripId = trips[1]._id;
    await Promise.all([vehicles[0].save(), vehicles[4].save()]);

    // 6. Create Alerts
    const alerts = await Alert.create([
      {
        organizationId: org._id,
        companyId: org._id,
        vehicleId: vehicles[4]._id,
        tripId: trips[1]._id,
        type: 'overspeed',
        severity: 'critical',
        title: 'Overspeed Violation: 94 km/h in 80 km/h zone',
        description: 'Vehicle Apex Falcon exceeded speed threshold on Outer Ring Road.',
        location: {
          name: 'Outer Ring Road, Hebbal Flyover',
          coordinates: [77.6033, 13.0112],
        },
        timestamp: new Date(now.getTime() - 5 * 60 * 1000),
        isRead: false,
        isAcknowledged: false,
      },
      {
        organizationId: org._id,
        companyId: org._id,
        vehicleId: vehicles[4]._id,
        tripId: trips[1]._id,
        type: 'safety_event',
        severity: 'critical',
        title: 'Harsh Braking Event Detected (-0.68g)',
        description: 'Sudden deceleration recorded near Hebbal flyover ramp.',
        location: {
          name: 'Hebbal Flyover Ramp, Bangalore',
          coordinates: [77.6035, 13.0115],
        },
        timestamp: new Date(now.getTime() - 8 * 60 * 1000),
        isRead: false,
        isAcknowledged: false,
      },
      {
        organizationId: org._id,
        companyId: org._id,
        vehicleId: vehicles[1]._id,
        type: 'long_idle',
        severity: 'warning',
        title: 'Excessive Idle Time (> 22 mins)',
        description: 'Vehicle City Express idling with engine running for over 22 minutes.',
        location: {
          name: 'Koramangala 4th Block, Bangalore',
          coordinates: [77.6389, 12.9172],
        },
        timestamp: new Date(now.getTime() - 25 * 60 * 1000),
        isRead: false,
        isAcknowledged: false,
      },
      {
        organizationId: org._id,
        companyId: org._id,
        vehicleId: vehicles[3]._id,
        type: 'device_offline',
        severity: 'warning',
        title: 'GPS Device Offline (> 45 mins)',
        description: 'No telemetry signal received from Metro Carrier GPS unit.',
        location: {
          name: 'Peenya Industrial Area Stage 1, Bangalore',
          coordinates: [77.534, 13.0358],
        },
        timestamp: new Date(now.getTime() - 45 * 60 * 1000),
        isRead: false,
        isAcknowledged: false,
      },
      {
        organizationId: org._id,
        companyId: org._id,
        vehicleId: vehicles[0]._id,
        tripId: trips[0]._id,
        type: 'vehicle_started',
        severity: 'info',
        title: 'Ignition ON: Trip APX-TRIP-1001 Started',
        description: 'Driver John Doe initiated scheduled morning delivery run.',
        location: {
          name: 'Electronic City Phase 1, Bangalore',
          coordinates: [77.6648, 12.8452],
        },
        timestamp: new Date(now.getTime() - 95 * 60 * 1000),
        isRead: true,
        isAcknowledged: true,
        acknowledgedBy: owner._id,
        acknowledgedAt: new Date(now.getTime() - 90 * 60 * 1000),
        acknowledgmentNote: 'Trip departure acknowledged',
      },
      {
        organizationId: org._id,
        companyId: org._id,
        vehicleId: vehicles[5]._id,
        type: 'maintenance_due',
        severity: 'info',
        title: 'Periodic Brake & Suspension Service Due',
        description: '90,000 km inspection overdue for Cargo Cruiser.',
        location: {
          name: 'Jayanagar Authorized Service Center',
          coordinates: [77.58, 12.93],
        },
        timestamp: new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000),
        isRead: true,
        isAcknowledged: true,
        acknowledgedBy: manager._id,
        acknowledgedAt: new Date(now.getTime() - 24 * 60 * 60 * 1000),
        acknowledgmentNote: 'Vehicle booked at service center',
      },
    ]);
    console.log(`✅ Created ${alerts.length} Alerts`);

    console.log('\n🎉 Development seed completed successfully!');
    console.log('--------------------------------------------------');
    console.log('Organization: Apex Logistics Fleet (Code: APEX)');
    console.log('Owner:   owner@navixa.com   / OwnerPass123!');
    console.log('Manager: manager@navixa.com / ManagerPass123!');
    console.log('Viewer:  viewer@navixa.com  / ViewerPass123!');
    console.log('Vehicles: 6 (Moving, Idle, Parked, Offline, Alert, Maintenance)');
    console.log('--------------------------------------------------');

    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('Seed error:', err);
    process.exit(1);
  }
}

if (require.main === module) {
  seedDatabase();
}

module.exports = { seedDatabase };
