import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prioritas_tugas/data/profile_repository.dart';
import 'package:prioritas_tugas/data/tugas_repository.dart';
import 'package:prioritas_tugas/models/user_profile.dart';
import 'package:prioritas_tugas/screens/dashboard_screen.dart';
import 'package:prioritas_tugas/widgets/profile_form.dart';

void main() {
  testWidgets('memuat dan menyimpan nama tampilan serta jurusan', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileRepository(
      profile: const UserProfile(displayName: 'Alya', major: 'Informatika'),
    );
    await _openProfileForm(tester, repository);

    expect(find.text('Alya'), findsOneWidget);
    expect(find.text('Informatika'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('profile-display-name')),
      '  Alya Putri  ',
    );
    await tester.enterText(
      find.byKey(const Key('profile-major')),
      '  Sistem Informasi  ',
    );
    await tester.tap(find.text('Simpan profil'));
    await tester.pumpAndSettle();

    expect(repository.savedProfile?.displayName, 'Alya Putri');
    expect(repository.savedProfile?.major, 'Sistem Informasi');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('validasi menolak field profil kosong', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileRepository();
    await _openProfileForm(tester, repository);

    await tester.tap(find.text('Simpan profil'));
    await tester.pumpAndSettle();

    expect(find.text('Nama tampilan wajib diisi'), findsOneWidget);
    expect(find.text('Jurusan wajib diisi'), findsOneWidget);
    expect(repository.savedProfile, isNull);
  });

  testWidgets('memperlihatkan status menyimpan dan mencegah submit ganda', (
    WidgetTester tester,
  ) async {
    final save = Completer<void>();
    final repository = _FakeProfileRepository(saveCompleter: save);
    await _openProfileForm(tester, repository);
    await tester.enterText(
      find.byKey(const Key('profile-display-name')),
      'Alya',
    );
    await tester.enterText(
      find.byKey(const Key('profile-major')),
      'Informatika',
    );

    await tester.tap(find.text('Simpan profil'));
    await tester.pump();

    expect(find.byKey(const Key('profile-submit-progress')), findsOneWidget);
    expect(repository.saveCalls, 1);
    save.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('menampilkan error baca dan menyediakan coba lagi', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileRepository(loadFailures: 1);
    await _openProfileForm(tester, repository);

    expect(
      find.text('Profil gagal dimuat. Periksa koneksi, lalu coba lagi.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-display-name')), findsOneWidget);
    expect(repository.loadCalls, 2);
  });

  testWidgets('menampilkan error simpan dan mempertahankan input', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileRepository(saveError: StateError('offline'));
    await _openProfileForm(tester, repository);
    await tester.enterText(
      find.byKey(const Key('profile-display-name')),
      'Alya',
    );
    await tester.enterText(
      find.byKey(const Key('profile-major')),
      'Informatika',
    );

    await tester.tap(find.text('Simpan profil'));
    await tester.pumpAndSettle();

    expect(
      find.text('Profil gagal disimpan. Periksa koneksi, lalu coba lagi.'),
      findsOneWidget,
    );
    expect(find.text('Alya'), findsOneWidget);
    expect(find.text('Informatika'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('menu akun membuka form profil', (WidgetTester tester) async {
    final profileRepository = _FakeProfileRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: BerandaPage(
          repository: MemoryTugasRepository(),
          profileRepository: profileRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Menu akun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-display-name')), findsOneWidget);
    expect(profileRepository.loadCalls, 2);
  });

  testWidgets(
    'header menampilkan profil dan langsung diperbarui saat disimpan',
    (WidgetTester tester) async {
      final profileRepository = _FakeProfileRepository(
        profile: const UserProfile(displayName: 'Alya', major: 'Informatika'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BerandaPage(
            repository: MemoryTugasRepository(),
            profileRepository: profileRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alya'), findsOneWidget);
      expect(find.text('Informatika'), findsOneWidget);

      await tester.tap(find.byTooltip('Menu akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('profile-display-name')),
        'Alya Putri',
      );
      await tester.enterText(
        find.byKey(const Key('profile-major')),
        'Sistem Informasi',
      );
      await tester.tap(find.text('Simpan profil'));
      await tester.pumpAndSettle();

      expect(find.text('Alya Putri'), findsOneWidget);
      expect(find.text('Sistem Informasi'), findsOneWidget);
      expect(find.text('Prioritas Tugas'), findsNothing);
    },
  );
}

Future<void> _openProfileForm(
  WidgetTester tester,
  ProfileRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => ProfileForm(repository: repository),
              );
            },
            child: const Text('Buka profil'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Buka profil'));
  await tester.pumpAndSettle();
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({
    this.profile = const UserProfile(),
    this.saveCompleter,
    this.saveError,
    this.loadFailures = 0,
  });

  final UserProfile profile;
  final Completer<void>? saveCompleter;
  final Object? saveError;
  int loadFailures;
  int loadCalls = 0;
  int saveCalls = 0;
  UserProfile? savedProfile;

  @override
  Future<UserProfile> getProfile() async {
    loadCalls++;
    if (loadFailures > 0) {
      loadFailures--;
      throw StateError('simulated read failure');
    }
    return savedProfile ?? profile;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    saveCalls++;
    if (saveError != null) throw saveError!;
    if (saveCompleter != null) await saveCompleter!.future;
    savedProfile = profile;
  }

  @override
  Future<void> deleteProfile() async {}
}
