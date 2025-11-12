import 'package:flutter/foundation.dart';
import '../../domain/entities/alert_entity.dart';
import '../../data/repositories/alert_repository.dart';

enum AlertsState { initial, loading, loaded, error }

class AlertsViewModel extends ChangeNotifier {
  final AlertRepository _repository;

  AlertsViewModel(this._repository);

  AlertsState _state = AlertsState.initial;
  List<AlertEntity> _alerts = [];
  String? _errorMessage;

  AlertsState get state => _state;
  List<AlertEntity> get alerts => _alerts;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AlertsState.loading;
  bool get hasError => _state == AlertsState.error;

  List<AlertEntity> get unreadAlerts =>
      _alerts.where((alert) => alert.isUnread).toList();

  List<AlertEntity> get criticalAlerts =>
      _alerts.where((alert) => alert.isCritical).toList();

  int get unreadCount => unreadAlerts.length;

  Future<void> loadAlerts() async {
    _state = AlertsState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _alerts = await _repository.getAllAlerts();
      _state = AlertsState.loaded;
    } catch (e) {
      _state = AlertsState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadUnreadAlerts() async {
    try {
      _alerts = await _repository.getUnreadAlerts();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final updatedAlert = await _repository.markAsRead(id);
      final index = _alerts.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alerts[index] = updatedAlert;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> dismissAlert(int id) async {
    try {
      await _repository.dismissAlert(id);
      _alerts.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteAlert(int id) async {
    try {
      await _repository.deleteAlert(id);
      _alerts.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
