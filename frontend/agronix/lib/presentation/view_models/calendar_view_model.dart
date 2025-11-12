import 'package:flutter/foundation.dart';
import '../../domain/entities/task_entity.dart';
import '../../data/repositories/task_repository.dart';

enum CalendarState { initial, loading, loaded, error }

class CalendarViewModel extends ChangeNotifier {
  final TaskRepository _repository;

  CalendarViewModel(this._repository);

  CalendarState _state = CalendarState.initial;
  List<TaskEntity> _tasks = [];
  DateTime _selectedDate = DateTime.now();
  String? _errorMessage;

  CalendarState get state => _state;
  List<TaskEntity> get tasks => _tasks;
  DateTime get selectedDate => _selectedDate;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == CalendarState.loading;
  bool get hasError => _state == CalendarState.error;

  List<TaskEntity> get tasksForSelectedDate {
    return _tasks.where((task) {
      return task.scheduledDate.year == _selectedDate.year &&
          task.scheduledDate.month == _selectedDate.month &&
          task.scheduledDate.day == _selectedDate.day;
    }).toList();
  }

  Map<DateTime, List<TaskEntity>> get tasksByDate {
    final Map<DateTime, List<TaskEntity>> grouped = {};
    for (var task in _tasks) {
      final date = DateTime(
        task.scheduledDate.year,
        task.scheduledDate.month,
        task.scheduledDate.day,
      );
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(task);
    }
    return grouped;
  }

  Future<void> loadTasks() async {
    _state = CalendarState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _repository.getAllTasks();
      _state = CalendarState.loaded;
    } catch (e) {
      _state = CalendarState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> createTask(Map<String, dynamic> data) async {
    try {
      final newTask = await _repository.createTask(data);
      _tasks.add(newTask);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTask(int id, Map<String, dynamic> data) async {
    try {
      final updatedTask = await _repository.updateTask(id, data);
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> completeTask(int id) async {
    try {
      final completedTask = await _repository.completeTask(id);
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = completedTask;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _repository.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
