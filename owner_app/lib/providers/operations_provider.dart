import 'package:flutter/material.dart';
import '../data/models/driver.dart';
import '../data/models/trip.dart';
import '../data/models/vehicle.dart';
import '../data/repositories/fleet_repository.dart';

class OperationsProvider extends ChangeNotifier {
  OperationsProvider({required FleetRepository fleetRepository})
    : _repository = fleetRepository;

  final FleetRepository _repository;
  List<Trip> _trips = [];
  List<DriverSummary> _drivers = [];
  List<Vehicle> _vehicles = [];
  bool _isLoadingTrips = false;
  bool _isLoadingDrivers = false;
  String? _errorMessage;
  String _tripStatus = 'all';
  String _tripSearch = '';
  String? _driverId;
  String? _vehicleId;
  DateTimeRange? _dateRange;
  String _driverSearch = '';
  String _driverStatus = 'all';

  List<Trip> get trips => _trips;
  List<DriverSummary> get drivers => _drivers;
  List<Vehicle> get vehicles => _vehicles;
  bool get isLoadingTrips => _isLoadingTrips;
  bool get isLoadingDrivers => _isLoadingDrivers;
  String? get errorMessage => _errorMessage;
  String get tripStatus => _tripStatus;
  String get tripSearch => _tripSearch;
  String? get driverId => _driverId;
  String? get vehicleId => _vehicleId;
  DateTimeRange? get dateRange => _dateRange;
  String get driverStatus => _driverStatus;

  int get activeTrips => _trips
      .where(
        (t) =>
            t.status == TripStatus.inProgress ||
            t.status == TripStatus.scheduled,
      )
      .length;
  int get completedTrips =>
      _trips.where((t) => t.status == TripStatus.completed).length;
  double get totalDistance =>
      _trips.fold(0, (sum, trip) => sum + trip.distanceKm);
  int get totalDuration =>
      _trips.fold(0, (sum, trip) => sum + trip.durationMinutes);
  int get totalStops => _trips.fold(0, (sum, trip) => sum + trip.stops.length);

  Future<void> loadTrips() async {
    _isLoadingTrips = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.getTrips(
        status: _tripStatus,
        search: _tripSearch,
        vehicleId: _vehicleId,
        driverId: _driverId,
        from: _dateRange?.start,
        to: _dateRange?.end,
      );
      _trips = result.trips;
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingTrips = false;
      notifyListeners();
    }
  }

  Future<void> setTripStatus(String value) async {
    _tripStatus = value;
    await loadTrips();
  }

  Future<void> setTripSearch(String value) async {
    _tripSearch = value;
    await loadTrips();
  }

  Future<void> setDriverFilter(String? value) async {
    _driverId = value;
    await loadTrips();
  }

  Future<void> setVehicleFilter(String? value) async {
    _vehicleId = value;
    await loadTrips();
  }

  Future<void> setDateRange(DateTimeRange? value) async {
    _dateRange = value;
    await loadTrips();
  }

  Future<void> loadDrivers() async {
    _isLoadingDrivers = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _drivers = await _repository.getDrivers(
        search: _driverSearch,
        status: _driverStatus,
      );
    } catch (error) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingDrivers = false;
      notifyListeners();
    }
  }

  Future<void> loadVehicles() async {
    try {
      final result = await _repository.getVehicles(limit: 100, sort: 'name');
      _vehicles = result.vehicles;
      notifyListeners();
    } catch (_) {
      // Trip list remains usable if the filter lookup cannot be loaded.
    }
  }

  Future<void> setDriverSearch(String value) async {
    _driverSearch = value;
    await loadDrivers();
  }

  Future<void> setDriverStatus(String value) async {
    _driverStatus = value;
    await loadDrivers();
  }
}
