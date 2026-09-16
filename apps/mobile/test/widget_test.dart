// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prioritas_tugas/data/tugas_repository.dart';
import 'package:prioritas_tugas/main.dart';
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
}
