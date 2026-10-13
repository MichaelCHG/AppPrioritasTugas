import 'package:flutter_test/flutter_test.dart';
import 'package:prioritas_tugas/data/tugas_repository.dart';
import 'package:prioritas_tugas/models/tugas.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('CRUD cache tetap tersedia setelah repository dibuat ulang', () async {
    final repository = SharedPreferencesTugasRepository(userId: 'user-1');
    final tugas = _sampleTugas();

    await repository.add(tugas);
    final restartedRepository = SharedPreferencesTugasRepository(
      userId: 'user-1',
    );
    expect((await restartedRepository.getAll()).single.nama, 'Tugas awal');

    tugas.nama = 'Tugas diperbarui';
    await restartedRepository.update(tugas);
    expect((await repository.getAll()).single.nama, 'Tugas diperbarui');

    await restartedRepository.delete(tugas);
    expect(await repository.getAll(), isEmpty);
  });

  test('cache per pengguna dan fallback dari Firestore', () async {
    final remote = _FakeRemoteTugasRepository(initial: [_sampleTugas()]);
    final repository = CachedTugasRepository(
      remote: remote,
      cache: SharedPreferencesTugasRepository(userId: 'user-1'),
    );
    expect((await repository.getAll()).single.nama, 'Tugas awal');

    remote.failReads = true;
    final reopenedRepository = CachedTugasRepository(
      remote: remote,
      cache: SharedPreferencesTugasRepository(userId: 'user-1'),
    );
    expect((await reopenedRepository.getAll()).single.nama, 'Tugas awal');
    expect(
      await SharedPreferencesTugasRepository(userId: 'user-2').getAll(),
      isEmpty,
    );
  });
}

Tugas _sampleTugas() => Tugas(
  id: 'task-1',
  nama: 'Tugas awal',
  mataKuliah: 'Pemrograman Mobile',
  deadline: DateTime(2026, 10, 20, 9),
  prioritas: 3,
);

class _FakeRemoteTugasRepository implements TugasRepository {
  _FakeRemoteTugasRepository({List<Tugas>? initial}) : items = [...?initial];

  final List<Tugas> items;
  bool failReads = false;

  @override
  Future<List<Tugas>> getAll() async {
    if (failReads) throw StateError('Firestore unavailable');
    return [...items];
  }

  @override
  Future<Tugas> add(Tugas tugas) async {
    items.add(tugas);
    return tugas;
  }

  @override
  Future<void> update(Tugas tugas) async {}

  @override
  Future<void> delete(Tugas tugas) async => items.remove(tugas);
}
