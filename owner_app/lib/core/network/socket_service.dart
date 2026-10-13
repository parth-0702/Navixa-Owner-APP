import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import '../storage/preferences_service.dart';

class SocketService {
  SocketService({required PreferencesService preferencesService})
      : _preferencesService = preferencesService;

  final PreferencesService _preferencesService;
  io.Socket? _socket;

  final _locationUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusChangedController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripCompletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _alertCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _alertAcknowledgedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onVehicleLocationUpdated => _locationUpdatesController.stream;
  Stream<Map<String, dynamic>> get onVehicleStatusChanged => _statusChangedController.stream;
  Stream<Map<String, dynamic>> get onTripStarted => _tripStartedController.stream;
  Stream<Map<String, dynamic>> get onTripCompleted => _tripCompletedController.stream;
  Stream<Map<String, dynamic>> get onAlertCreated => _alertCreatedController.stream;
  Stream<Map<String, dynamic>> get onAlertAcknowledged => _alertAcknowledgedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    final customUrl = _preferencesService.getCustomBaseUrl();
    String socketUrl = AppConfig.defaultSocketUrl;
    if (customUrl != null && customUrl.isNotEmpty) {
      final uri = Uri.parse(customUrl);
      socketUrl = '${uri.scheme}://${uri.host}:${uri.port}';
    }

    final options = io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(8000)
        .build();

    _socket = io.io(socketUrl, options);

    _socket?.onConnect((_) {
      debugPrint('⚡ Socket connected to $socketUrl');
    });

    _socket?.onDisconnect((reason) {
      debugPrint('🔌 Socket disconnected: $reason');
    });

    _socket?.onConnectError((err) {
      debugPrint('⚠️ Socket connection error: $err');
    });

    // Event listeners
    _socket?.on('vehicle.location.updated', (data) {
      if (data is Map) {
        _locationUpdatesController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('vehicle.status.changed', (data) {
      if (data is Map) {
        _statusChangedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('trip.started', (data) {
      if (data is Map) {
        _tripStartedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('trip.completed', (data) {
      if (data is Map) {
        _tripCompletedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('alert.created', (data) {
      if (data is Map) {
        _alertCreatedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('alert.acknowledged', (data) {
      if (data is Map) {
        _alertAcknowledgedController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  void subscribeVehicle(String vehicleId) {
    _socket?.emit('subscribe:vehicle', vehicleId);
  }

  void unsubscribeVehicle(String vehicleId) {
    _socket?.emit('unsubscribe:vehicle', vehicleId);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _locationUpdatesController.close();
    _statusChangedController.close();
    _tripStartedController.close();
    _tripCompletedController.close();
    _alertCreatedController.close();
    _alertAcknowledgedController.close();
  }
}
