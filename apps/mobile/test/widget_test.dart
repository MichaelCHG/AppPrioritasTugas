// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prioritas_tugas/data/tugas_repository.dart';
import 'package:prioritas_tugas/screens/dashboard_screen.dart';
import 'package:prioritas_tugas/models/tugas.dart';

void main() {
  testWidgets('Menampilkan beranda prioritas tugas', (
    WidgetTester tester,
  ) async {
    final repository = MemoryTugasRepository([
      Tugas(
        nama: 'Membuat rancangan aplikasi mobile',
        mataKuliah: 'Pemrograman Mobile',
        deadline: DateTime(2026, 9, 18),
        prioritas: 3,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: BerandaPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prioritas Tugas'), findsOneWidget);
    expect(find.text('Membuat rancangan aplikasi mobile'), findsOneWidget);
    expect(find.text('Tambah tugas'), findsOneWidget);
  });
  testWidgets('menampilkan loading awal lalu data berhasil dimuat', (
    WidgetTester tester,
  ) async {
    final load = Completer<List<Tugas>>();
    final repository = _TestTugasRepository(loadResult: load.future);

    await _render(tester, repository);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    load.complete([_sampleTask()]);
    await tester.pumpAndSettle();
    expect(find.text('Membuat rancangan aplikasi'), findsOneWidget);
  });

  testWidgets('menampilkan data tugas yang berhasil dimuat', (
    WidgetTester tester,
  ) async {
    await _render(tester, _TestTugasRepository(initial: [_sampleTask()]));
    await tester.pumpAndSettle();

    expect(find.text('Prioritas Tugas'), findsOneWidget);
    expect(find.text('Membuat rancangan aplikasi'), findsOneWidget);
    expect(find.text('Tambah tugas'), findsOneWidget);
    await expectLater(
      find.byType(BerandaPage),
      matchesGoldenFile('dashboard-loaded.png'),
    );
  });

  testWidgets('menampilkan empty state saat belum ada tugas', (
    WidgetTester tester,
  ) async {
    await _render(tester, _TestTugasRepository());
    await tester.pumpAndSettle();

    expect(find.text('Belum ada tugas'), findsOneWidget);
    expect(
      find.text('Tambahkan tugas pertamamu untuk memulai.'),
      findsOneWidget,
    );
  });

  testWidgets('menampilkan error dan memuat ulang setelah retry', (
    WidgetTester tester,
  ) async {
    final repository = _TestTugasRepository(loadFailures: 1);
    await _render(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Data belum dapat dimuat dari Firebase.'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada tugas'), findsOneWidget);
    expect(repository.loadCalls, 2);
  });

  testWidgets('menampilkan validasi ketika nama tugas kosong', (
    WidgetTester tester,
  ) async {
    await _render(tester, _TestTugasRepository());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah tugas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Nama tugas wajib diisi'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('submit menampilkan loading dan mencegah tap ganda', (
    WidgetTester tester,
  ) async {
    final add = Completer<Tugas>();
    final repository = _TestTugasRepository(addResult: add.future);
    await _render(tester, repository);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah tugas'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Membuat rancangan aplikasi',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.byKey(const Key('submit-progress')), findsOneWidget);
    expect(repository.addCalls, 1);
    final saveButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.byKey(const Key('submit-progress')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(saveButton.onPressed, isNull);
    await tester.tap(find.byKey(const Key('submit-progress')));
    expect(repository.addCalls, 1);

    add.complete(_sampleTask());
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}

Future<void> _render(WidgetTester tester, TugasRepository repository) async {
  await tester.pumpWidget(
    MaterialApp(home: BerandaPage(repository: repository)),
  );
}

Tugas _sampleTask() => Tugas(
  id: 'task-1',
  nama: 'Membuat rancangan aplikasi',
  mataKuliah: 'Pemrograman Mobile',
  deadline: DateTime(2026, 10, 10),
  prioritas: 3,
);

class _TestTugasRepository implements TugasRepository {
  _TestTugasRepository({
    List<Tugas>? initial,
    this.loadResult,
    this.addResult,
    this.loadFailures = 0,
  }) : items = [...?initial];

  final List<Tugas> items;
  final Future<List<Tugas>>? loadResult;
  final Future<Tugas>? addResult;
  int loadFailures;
  int loadCalls = 0;
  int addCalls = 0;

  @override
  Future<List<Tugas>> getAll() async {
    loadCalls++;
    if (loadFailures > 0) {
      loadFailures--;
      throw StateError('Simulated load failure');
    }
    if (loadResult != null) return loadResult!;
    return [...items];
  }

  @override
  Future<Tugas> add(Tugas tugas) async {
    addCalls++;
    if (addResult != null) return addResult!;
    tugas.id ??= 'task-${items.length + 1}';
    items.add(tugas);
    return tugas;
  }

  @override
  Future<void> delete(Tugas tugas) async => items.remove(tugas);

  @override
  Future<void> update(Tugas tugas) async {}
}
