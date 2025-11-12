import '../../domain/entities/task_entity.dart';
import '../data_sources/remote/api_client.dart';
import '../models/task_model.dart';
import '../../services/endpoints/endpoints.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> getAllTasks();
  Future<List<TaskEntity>> getTasksByParcela(int parcelaId);
  Future<TaskEntity> getTaskById(int id);
  Future<TaskEntity> createTask(Map<String, dynamic> data);
  Future<TaskEntity> updateTask(int id, Map<String, dynamic> data);
  Future<void> deleteTask(int id);
  Future<TaskEntity> completeTask(int id);
}

class TaskRepositoryImpl implements TaskRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<TaskEntity>> getAllTasks() async {
    try {
      final response = await _apiClient.get(TaskEndpoints.list);
      final List<dynamic> tasksJson = response as List<dynamic>;
      return tasksJson.map((json) => TaskModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error obteniendo tareas: $e');
    }
  }

  @override
  Future<List<TaskEntity>> getTasksByParcela(int parcelaId) async {
    try {
      final response = await _apiClient.get('${TaskEndpoints.list}?parcela_id=$parcelaId');
      final List<dynamic> tasksJson = response as List<dynamic>;
      return tasksJson.map((json) => TaskModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error obteniendo tareas de la parcela: $e');
    }
  }

  @override
  Future<TaskEntity> getTaskById(int id) async {
    try {
      final response = await _apiClient.get(TaskEndpoints.detail(id));
      return TaskModel.fromJson(response);
    } catch (e) {
      throw Exception('Error obteniendo tarea: $e');
    }
  }

  @override
  Future<TaskEntity> createTask(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(TaskEndpoints.create, data);
      return TaskModel.fromJson(response);
    } catch (e) {
      throw Exception('Error creando tarea: $e');
    }
  }

  @override
  Future<TaskEntity> updateTask(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(TaskEndpoints.update(id), data);
      return TaskModel.fromJson(response);
    } catch (e) {
      throw Exception('Error actualizando tarea: $e');
    }
  }

  @override
  Future<void> deleteTask(int id) async {
    try {
      await _apiClient.delete(TaskEndpoints.delete(id));
    } catch (e) {
      throw Exception('Error eliminando tarea: $e');
    }
  }

  @override
  Future<TaskEntity> completeTask(int id) async {
    try {
      final response = await _apiClient.post(
        '${TaskEndpoints.detail(id)}/complete/',
        {},
      );
      return TaskModel.fromJson(response);
    } catch (e) {
      throw Exception('Error completando tarea: $e');
    }
  }
}
