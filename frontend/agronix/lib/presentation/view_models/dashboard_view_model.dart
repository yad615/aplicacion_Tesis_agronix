import 'package:flutter/foundation.dart';
import '../../domain/entities/parcela_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/alert_entity.dart';
import '../../data/repositories/parcela_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/alert_repository.dart';

enum DashboardState { initial, loading, loaded, error }

class DashboardViewModel extends ChangeNotifier {
  final ParcelaRepository _parcelaRepository;
  final TaskRepository _taskRepository;
  final AlertRepository _alertRepository;

  DashboardViewModel(
    this._parcelaRepository,
    this._taskRepository,
    this._alertRepository,
  );

  DashboardState _state = DashboardState.initial;
  List<ParcelaEntity> _parcelas = [];
  List<TaskEntity> _recentTasks = [];
  List<AlertEntity> _unreadAlerts = [];
  String? _errorMessage;

  DashboardState get state => _state;
  List<ParcelaEntity> get parcelas => _parcelas;
  List<TaskEntity> get recentTasks => _recentTasks;
  List<AlertEntity> get unreadAlerts => _unreadAlerts;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == DashboardState.loading;
  bool get hasError => _state == DashboardState.error;

  Future<void> loadDashboardData() async {
    _state = DashboardState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cargar datos en paralelo
      final results = await Future.wait([
        _parcelaRepository.getAllParcelas(),
        _taskRepository.getAllTasks(),
        _alertRepository.getUnreadAlerts(),
      ]);

      _parcelas = results[0] as List<ParcelaEntity>;
      _recentTasks = (results[1] as List<TaskEntity>).take(5).toList();
      _unreadAlerts = results[2] as List<AlertEntity>;

      _state = DashboardState.loaded;
    } catch (e) {
      _state = DashboardState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadDashboardData();
  }

  void clearError() {
    _errorMessage = null;
    _state = DashboardState.initial;
    notifyListeners();
  }
}
