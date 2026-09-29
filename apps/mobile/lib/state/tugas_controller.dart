import 'package:flutter/foundation.dart';

import '../data/tugas_repository.dart';
import '../models/tugas.dart';

class TugasController extends ChangeNotifier {
  TugasController(this._repository);

  final TugasRepository _repository;
  final List<Tugas> _tugas = [];

  List<Tugas> get tugas => List.unmodifiable(_tugas);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isEmpty => !_isLoading && _error == null && _tugas.isEmpty;
  String? get error => _error;
  String? get submitError => _submitError;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  String? _submitError;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final hasil = await _repository.getAll();
      _tugas
        ..clear()
        ..addAll(hasil);
    } catch (error) {
      debugPrint('Gagal memuat tugas: $error');
      _error = 'Data belum dapat dimuat dari Firebase.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(Tugas tugas, {Tugas? existing}) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();
    try {
      if (existing == null) {
        _tugas.add(await _repository.add(tugas));
      } else {
        tugas.id = existing.id;
        await _repository.update(tugas);
        final index = _tugas.indexOf(existing);
        if (index >= 0) _tugas[index] = tugas;
      }
      return true;
    } catch (error) {
      debugPrint('Gagal menyimpan tugas: $error');
      _submitError = 'Gagal menyimpan tugas. Silakan coba lagi.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> toggleStatus(Tugas tugas) async {
    final statusLama = tugas.status;
    tugas.status = statusLama == StatusTugas.selesai
        ? StatusTugas.belum
        : StatusTugas.selesai;
    notifyListeners();
    try {
      await _repository.update(tugas);
      return true;
    } catch (error) {
      debugPrint('Gagal memperbarui status tugas: $error');
      tugas.status = statusLama;
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(Tugas tugas) async {
    try {
      await _repository.delete(tugas);
      _tugas.remove(tugas);
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('Gagal menghapus tugas: $error');
      return false;
    }
  }
}
