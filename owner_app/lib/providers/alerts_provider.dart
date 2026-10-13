import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/socket_service.dart';
import '../data/models/alert.dart';
import '../data/repositories/alerts_repository.dart';

class AlertsProvider extends ChangeNotifier {
  AlertsProvider({
    required AlertsRepository alertsRepository,
    required SocketService socketService,
  })  : _alertsRepository = alertsRepository,
        _socketService = socketService {
    _initSocketListeners();
  }

  final AlertsRepository _alertsRepository;
  final SocketService _socketService;

  List<Alert> _alerts = [];
  List<Alert> get alerts => _alerts;

  List<Alert> _today = [];
  List<Alert> get today => _today;

  List<Alert> _yesterday = [];
  List<Alert> get yesterday => _yesterday;

  List<Alert> _earlier = [];
  List<Alert> get earlier => _earlier;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _selectedStatus = 'all'; // 'all', 'unread', 'critical'
  String get selectedStatus => _selectedStatus;

  String? _selectedType;
  String? get selectedType => _selectedType;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  int _criticalCount = 0;
  int get criticalCount => _criticalCount;

  StreamSubscription? _alertCreatedSubscription;
  StreamSubscription? _alertAckSubscription;

  void _initSocketListeners() {
    _alertCreatedSubscription = _socketService.onAlertCreated.listen((data) {
      final newAlert = Alert.fromJson(data);
      _alerts.insert(0, newAlert);
      _today.insert(0, newAlert);
      _unreadCount += 1;
      if (newAlert.severity == AlertSeverity.critical) {
        _criticalCount += 1;
      }
      notifyListeners();
    });

    _alertAckSubscription = _socketService.onAlertAcknowledged.listen((data) {
      final id = data['id']?.toString();
      if (id == null) return;

      void updateList(List<Alert> list) {
        final idx = list.indexWhere((a) => a.id == id);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(
            isAcknowledged: true,
            acknowledgedAt: DateTime.tryParse(data['acknowledgedAt']?.toString() ?? '') ?? DateTime.now(),
            acknowledgedBy: data['acknowledgedBy']?.toString(),
            acknowledgmentNote: data['note']?.toString() ?? '',
          );
        }
      }

      updateList(_alerts);
      updateList(_today);
      updateList(_yesterday);
      updateList(_earlier);

      if (_criticalCount > 0) _criticalCount -= 1;
      notifyListeners();
    });
  }

  void setFilterStatus(String status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    loadAlerts();
  }

  void setFilterType(String? type) {
    if (_selectedType == type) return;
    _selectedType = type;
    loadAlerts();
  }

  Future<void> loadAlerts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _alertsRepository.getAlerts(
        status: _selectedStatus,
        type: _selectedType,
      );

      _alerts = result.alerts;
      _today = result.today;
      _yesterday = result.yesterday;
      _earlier = result.earlier;
      _unreadCount = result.unreadCount;
      _criticalCount = result.criticalCount;
      _isOffline = false;
      _errorMessage = null;
    } on NetworkException catch (e) {
      _isOffline = true;
      if (_alerts.isEmpty) _errorMessage = e.message;
    } catch (e) {
      if (_alerts.isEmpty) _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx != -1 && !_alerts[idx].isRead) {
      _alerts[idx] = _alerts[idx].copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount -= 1;
      notifyListeners();
    }

    try {
      await _alertsRepository.markAlertAsRead(id);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    _alerts = _alerts.map((a) => a.copyWith(isRead: true)).toList();
    _today = _today.map((a) => a.copyWith(isRead: true)).toList();
    _yesterday = _yesterday.map((a) => a.copyWith(isRead: true)).toList();
    _earlier = _earlier.map((a) => a.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _alertsRepository.markAllAlertsAsRead();
    } catch (_) {}
  }

  Future<bool> acknowledgeAlert(String id, {String note = ''}) async {
    try {
      final updated = await _alertsRepository.acknowledgeAlert(id, note: note);

      void updateList(List<Alert> list) {
        final idx = list.indexWhere((a) => a.id == id);
        if (idx != -1) {
          list[idx] = updated;
        }
      }

      updateList(_alerts);
      updateList(_today);
      updateList(_yesterday);
      updateList(_earlier);

      if (_criticalCount > 0) _criticalCount -= 1;
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
    _alertCreatedSubscription?.cancel();
    _alertAckSubscription?.cancel();
    super.dispose();
  }
}
