import 'package:flutter/foundation.dart';
import '../../domain/entities/parcela_entity.dart';
import '../../data/repositories/parcela_repository.dart';

enum ParcelasState { initial, loading, loaded, error }

class ParcelasViewModel extends ChangeNotifier {
  final ParcelaRepository _repository;

  ParcelasViewModel(this._repository);

  ParcelasState _state = ParcelasState.initial;
  List<ParcelaEntity> _parcelas = [];
  ParcelaEntity? _selectedParcela;
  String? _errorMessage;

  ParcelasState get state => _state;
  List<ParcelaEntity> get parcelas => _parcelas;
  ParcelaEntity? get selectedParcela => _selectedParcela;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ParcelasState.loading;
  bool get hasError => _state == ParcelasState.error;

  Future<void> loadParcelas() async {
    _state = ParcelasState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _parcelas = await _repository.getAllParcelas();
      _state = ParcelasState.loaded;
    } catch (e) {
      _state = ParcelasState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> selectParcela(int id) async {
    try {
      _selectedParcela = await _repository.getParcelaById(id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> createParcela(Map<String, dynamic> data) async {
    _state = ParcelasState.loading;
    notifyListeners();

    try {
      final newParcela = await _repository.createParcela(data);
      _parcelas.add(newParcela);
      _state = ParcelasState.loaded;
    } catch (e) {
      _state = ParcelasState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> updateParcela(int id, Map<String, dynamic> data) async {
    _state = ParcelasState.loading;
    notifyListeners();

    try {
      final updatedParcela = await _repository.updateParcela(id, data);
      final index = _parcelas.indexWhere((p) => p.id == id);
      if (index != -1) {
        _parcelas[index] = updatedParcela;
      }
      _state = ParcelasState.loaded;
    } catch (e) {
      _state = ParcelasState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> deleteParcela(int id) async {
    try {
      await _repository.deleteParcela(id);
      _parcelas.removeWhere((p) => p.id == id);
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
