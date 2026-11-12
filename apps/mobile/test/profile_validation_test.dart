import 'package:flutter_test/flutter_test.dart';
import 'package:prioritas_tugas/validation/profile_validation.dart';

void main() {
  group('validateDisplayName', () {
    test('menolak nama kosong atau terlalu pendek', () {
      expect(validateDisplayName('  '), 'Nama tampilan wajib diisi');
      expect(validateDisplayName('A'), 'Nama tampilan minimal 2 karakter');
    });

    test('menerima nama tampilan valid dan memangkas spasi', () {
      expect(validateDisplayName('  Alya  '), isNull);
    });

    test('menolak nama yang melebihi batas', () {
      expect(
        validateDisplayName('A' * 51),
        'Nama tampilan maksimal 50 karakter',
      );
    });
  });

  group('validateMajor', () {
    test('menolak jurusan kosong atau terlalu pendek', () {
      expect(validateMajor(''), 'Jurusan wajib diisi');
      expect(validateMajor('X'), 'Jurusan minimal 2 karakter');
    });

    test('menerima jurusan valid', () {
      expect(validateMajor('  Teknik Informatika  '), isNull);
    });

    test('menolak jurusan yang melebihi batas', () {
      expect(validateMajor('J' * 81), 'Jurusan maksimal 80 karakter');
    });
  });
}
