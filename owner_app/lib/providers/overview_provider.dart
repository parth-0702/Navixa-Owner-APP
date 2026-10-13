import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/socket_service.dart';
import '../data/models/overview_data.dart';
import '../data/repositories/fleet_repository.dart';

class OverviewProvider extends ChangeNotifier {
  OverviewProvider({
    required FleetRepository fleetRepository,
    required SocketService socketService,
  })  : _fleetRepository = fleetRepository,
        _socketService = socketService {
    _initSocketListeners();
  }

  final FleetRepository _fleetRepository;
  final SocketService _socketService;

  OverviewData? _data;
  OverviewData? get data => _data;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _statusSubscription;
  StreamSubscription? _alertCreatedSubscription;
  StreamSubscription? _alertAckSubscription;

  void _initSocketListeners() {
    _statusSubscription = _socketService.onVehicleStatusChanged.listen((_) {
      loadOverview(silent: true);
    });
    _alertCreatedSubscription = _socketService.onAlertCreated.listen((_) {
      loadOverview(silent: true);
    });
    _alertAckSubscription = _socketService.onAlertAcknowledged.listen((_) {
      loadOverview(silent: true);
    });
  }

  Future<void> loadOverview({bool silent = false}) async {
    if (!silent && _data == null) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final res = await _fleetRepository.getOverview();
      _data = res;
      _isOffline = false;
      _errorMessage = null;
    } on NetworkException catch (e) {
      _isOffline = true;
      if (_data == null) {
        _errorMessage = e.message;
      }
    } catch (e) {
      if (_data == null) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _alertCreatedSubscription?.cancel();
    _alertAckSubscription?.cancel();
    super.dispose();
  }
}
