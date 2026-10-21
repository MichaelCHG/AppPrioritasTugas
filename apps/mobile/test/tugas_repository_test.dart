import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prioritas_tugas/data/tugas_repository.dart';
import 'package:prioritas_tugas/models/tugas.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('model membaca data tugas valid', () {
    final tugas = Tugas.fromMap('task-1', {
      'nama': 'Tugas valid',
      'mataKuliah': 'Pemrograman Mobile',
      'deadline': DateTime(2026, 10, 20, 9),
      'prioritas': 3,
      'status': 'dikerjakan',
    });

    expect(tugas.id, 'task-1');
    expect(tugas.nama, 'Tugas valid');
    expect(tugas.prioritas, 3);
    expect(tugas.status, StatusTugas.dikerjakan);
  });

  test('model menolak data tugas tidak valid', () {
    expect(
      () => Tugas.fromMap('task-1', {
        'nama': '',
        'mataKuliah': 'Pemrograman Mobile',
        'deadline': 'bukan-tanggal',
        'prioritas': 3,
      }),
      throwsFormatException,
    );
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

  test('repository memuat data backend dan menyinkronkan cache', () async {
    final remote = _FakeRemoteTugasRepository(initial: [_sampleTugas()]);
    final cache = SharedPreferencesTugasRepository(userId: 'user-1');
    final repository = CachedTugasRepository(remote: remote, cache: cache);

    final result = await repository.getAll();

    expect(result.single.nama, 'Tugas awal');
    expect((await cache.getAll()).single.id, 'task-1');
  });

  test('repository menyimpan perubahan ke backend dan cache', () async {
    final remote = _FakeRemoteTugasRepository();
    final cache = SharedPreferencesTugasRepository(userId: 'user-1');
    final repository = CachedTugasRepository(remote: remote, cache: cache);
    final tugas = _sampleTugas();

    await repository.add(tugas);
    expect(remote.items.single.nama, 'Tugas awal');

    tugas.nama = 'Tugas diperbarui';
    await repository.update(tugas);
    expect(remote.items.single.nama, 'Tugas diperbarui');
    expect((await cache.getAll()).single.nama, 'Tugas diperbarui');

    await repository.delete(tugas);
    expect(remote.items, isEmpty);
    expect(await cache.getAll(), isEmpty);
  });

  test('repository mengembalikan daftar kosong dari backend', () async {
    final repository = CachedTugasRepository(
      remote: _FakeRemoteTugasRepository(),
      cache: SharedPreferencesTugasRepository(userId: 'user-1'),
    );

    expect(await repository.getAll(), isEmpty);
  });

  test(
    'repository meneruskan kegagalan backend saat tidak ada cache',
    () async {
      final backendError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'Backend tidak tersedia',
      );
      final repository = CachedTugasRepository(
        remote: _FakeRemoteTugasRepository(readError: backendError),
        cache: SharedPreferencesTugasRepository(userId: 'user-1'),
      );

      await expectLater(repository.getAll(), throwsA(same(backendError)));
    },
  );

  test('cache menolak JSON tugas yang rusak', () async {
    SharedPreferences.setMockInitialValues({
      'tugas_cache_user-1': '{json-rusak',
    });
    final repository = SharedPreferencesTugasRepository(userId: 'user-1');

    await expectLater(repository.getAll(), throwsFormatException);
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
  _FakeRemoteTugasRepository({List<Tugas>? initial, this.readError})
    : items = [...?initial];

  final List<Tugas> items;
  final Object? readError;
  bool failReads = false;

  @override
  Future<List<Tugas>> getAll() async {
    if (readError != null) throw readError!;
    if (failReads) throw StateError('Firestore unavailable');
    return [...items];
  }

  @override
  Future<Tugas> add(Tugas tugas) async {
    tugas.id ??= 'task-${items.length + 1}';
    items.add(tugas);
    return tugas;
  }

  @override
  Future<void> update(Tugas tugas) async {
    final index = items.indexWhere((item) => item.id == tugas.id);
    if (index < 0) throw StateError('Tugas tidak ditemukan.');
    items[index] = tugas;
  }

  @override
  Future<void> delete(Tugas tugas) async {
    items.removeWhere((item) => item.id == tugas.id);
  }
}
