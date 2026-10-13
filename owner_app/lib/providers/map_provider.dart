import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/socket_service.dart';
import '../data/models/trip.dart';
import '../data/models/vehicle.dart';
import '../data/repositories/fleet_repository.dart';

class MapProvider extends ChangeNotifier {
  MapProvider({
    required FleetRepository fleetRepository,
    required SocketService socketService,
  })  : _fleetRepository = fleetRepository,
        _socketService = socketService {
    _initSocketListeners();
  }

  final FleetRepository _fleetRepository;
  final SocketService _socketService;

  List<Vehicle> _vehicles = [];
  List<Vehicle> get vehicles => _vehicles;

  Vehicle? _selectedVehicle;
  Vehicle? get selectedVehicle => _selectedVehicle;

  Trip? _selectedTrip;
  Trip? get selectedTrip => _selectedTrip;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _statusFilter = 'all';
  String get statusFilter => _statusFilter;

  String _searchFilter = '';
  String get searchFilter => _searchFilter;

  // Throttled UI update handling
  DateTime _lastSocketUiUpdate = DateTime.now();
  static const _throttleDuration = Duration(milliseconds: 1200);

  // Playback state
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  int _playbackIndex = 0;
  int get playbackIndex => _playbackIndex;
  Timer? _playbackTimer;

  StreamSubscription? _locationSubscription;

  void _initSocketListeners() {
    _locationSubscription = _socketService.onVehicleLocationUpdated.listen((data) {
      final vehicleId = data['vehicleId']?.toString() ?? data['id']?.toString();
      if (vehicleId == null) return;

      final now = DateTime.now();
      final idx = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (idx != -1) {
        final current = _vehicles[idx];
        final newLoc = VehicleLocation.fromJson(data);
        _vehicles[idx] = current.copyWith(
          lastLocation: newLoc,
          speedKmh: (data['speed'] as num?)?.toDouble() ?? current.speedKmh,
          heading: (data['heading'] as num?)?.toDouble() ?? current.heading,
          lastLocationUpdatedAt: now,
          isStale: false,
        );

        if (_selectedVehicle?.id == vehicleId) {
          _selectedVehicle = _vehicles[idx];
        }

        // Throttle UI notification to avoid map jitter
        if (now.difference(_lastSocketUiUpdate) > _throttleDuration) {
          _lastSocketUiUpdate = now;
          notifyListeners();
        }
      }
    });
  }

  List<Vehicle> get filteredVehicles {
    return _vehicles.where((v) {
      if (v.lastLocation == null) return false;
      if (_statusFilter != 'all' && v.status.name != _statusFilter) {
        return false;
      }
      if (_searchFilter.isNotEmpty) {
        final q = _searchFilter.toLowerCase();
        final matchName = v.displayName.toLowerCase().contains(q);
        final matchPlate = v.plateNumber.toLowerCase().contains(q);
        final matchDriver = v.assignedDriver?.name.toLowerCase().contains(q) ?? false;
        if (!matchName && !matchPlate && !matchDriver) return false;
      }
      return true;
    }).toList();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setSearchFilter(String query) {
    _searchFilter = query;
    notifyListeners();
  }

  void selectVehicle(Vehicle? vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  Future<void> loadMapVehicles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _fleetRepository.getVehicles(limit: 100);
      _vehicles = res.vehicles;
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTripDetails(String tripId) async {
    _isLoading = true;
    _selectedTrip = null;
    _playbackIndex = 0;
    _isPlaying = false;
    _playbackTimer?.cancel();
    notifyListeners();

    try {
      final trip = await _fleetRepository.getTripById(tripId);
      _selectedTrip = trip;
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startPlayback() {
    if (_selectedTrip == null || _selectedTrip!.polyline.isEmpty) return;
    _isPlaying = true;
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (_selectedTrip == null || _playbackIndex >= _selectedTrip!.polyline.length - 1) {
        stopPlayback();
      } else {
        _playbackIndex += 1;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void stopPlayback() {
    _isPlaying = false;
    _playbackTimer?.cancel();
    notifyListeners();
  }

  void resetPlayback() {
    _playbackTimer?.cancel();
    _isPlaying = false;
    _playbackIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}
