import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/socket_service.dart';
import '../../core/utils/debouncer.dart';
import '../data/models/trip.dart';
import '../data/models/vehicle.dart';
import '../data/repositories/fleet_repository.dart';

class FleetProvider extends ChangeNotifier {
  FleetProvider({
    required FleetRepository fleetRepository,
    required SocketService socketService,
  })  : _fleetRepository = fleetRepository,
        _socketService = socketService {
    _initSocketListeners();
  }

  final FleetRepository _fleetRepository;
  final SocketService _socketService;
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 350);

  List<Vehicle> _vehicles = [];
  List<Vehicle> get vehicles => _vehicles;

  Vehicle? _selectedVehicle;
  Vehicle? get selectedVehicle => _selectedVehicle;

  List<Trip> _vehicleTrips = [];
  List<Trip> get vehicleTrips => _vehicleTrips;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _isLoadingDetails = false;
  bool get isLoadingDetails => _isLoadingDetails;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedStatus = 'all';
  String get selectedStatus => _selectedStatus;

  String _selectedSort = 'lastUpdated';
  String get selectedSort => _selectedSort;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  int get totalCount => _totalCount;
  bool get hasMore => _currentPage < _totalPages;

  StreamSubscription? _locationSubscription;
  StreamSubscription? _statusSubscription;

  void _initSocketListeners() {
    _locationSubscription = _socketService.onVehicleLocationUpdated.listen((data) {
      final vehicleId = data['vehicleId']?.toString() ?? data['id']?.toString();
      if (vehicleId == null) return;

      final index = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (index != -1) {
        final current = _vehicles[index];
        final newLoc = VehicleLocation.fromJson(data);
        _vehicles[index] = current.copyWith(
          lastLocation: newLoc,
          speedKmh: (data['speed'] as num?)?.toDouble() ?? current.speedKmh,
          heading: (data['heading'] as num?)?.toDouble() ?? current.heading,
          lastLocationUpdatedAt: DateTime.now(),
          isStale: false,
        );
        if (_selectedVehicle?.id == vehicleId) {
          _selectedVehicle = _vehicles[index];
        }
        notifyListeners();
      }
    });

    _statusSubscription = _socketService.onVehicleStatusChanged.listen((data) {
      final vehicleId = data['vehicleId']?.toString() ?? data['id']?.toString();
      final newStatus = data['status']?.toString();
      if (vehicleId == null || newStatus == null) return;

      final index = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (index != -1) {
        final current = _vehicles[index];
        _vehicles[index] = current.copyWith(
          status: VehicleStatus.fromString(newStatus),
        );
        if (_selectedVehicle?.id == vehicleId) {
          _selectedVehicle = _vehicles[index];
        }
        notifyListeners();
      }
    });
  }

  void setFilterStatus(String status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    loadVehicles(resetPage: true);
  }

  void setSort(String sort) {
    if (_selectedSort == sort) return;
    _selectedSort = sort;
    loadVehicles(resetPage: true);
  }

  void onSearchChanged(String query) {
    _searchQuery = query;
    _searchDebouncer.run(() {
      loadVehicles(resetPage: true);
    });
  }

  Future<void> loadVehicles({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final result = await _fleetRepository.getVehicles(
        search: _searchQuery,
        status: _selectedStatus,
        sort: _selectedSort,
        page: _currentPage,
        limit: 20,
      );

      if (resetPage) {
        _vehicles = result.vehicles;
      } else {
        _vehicles.addAll(result.vehicles);
      }

      _totalPages = result.totalPages;
      _totalCount = result.total;
      _isOffline = false;
      _errorMessage = null;
    } on NetworkException catch (e) {
      _isOffline = true;
      if (_vehicles.isEmpty) _errorMessage = e.message;
    } catch (e) {
      if (_vehicles.isEmpty) _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreVehicles() async {
    if (_isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    _currentPage += 1;
    notifyListeners();
    await loadVehicles(resetPage: false);
  }

  Future<void> loadVehicleDetails(String id) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final v = await _fleetRepository.getVehicleById(id);
      _selectedVehicle = v;

      // Subscribe to live socket updates for this vehicle
      _socketService.subscribeVehicle(id);

      // Load recent trips
      final trips = await _fleetRepository.getVehicleTrips(id);
      _vehicleTrips = trips;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<bool> updateNickname(String id, String newNickname) async {
    try {
      final updated = await _fleetRepository.updateVehicleNickname(id, newNickname);
      if (_selectedVehicle?.id == id) {
        _selectedVehicle = _selectedVehicle!.copyWith(nickname: updated);
      }
      final idx = _vehicles.indexWhere((v) => v.id == id);
      if (idx != -1) {
        _vehicles[idx] = _vehicles[idx].copyWith(nickname: updated);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _locationSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}
