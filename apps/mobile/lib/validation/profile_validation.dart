String? validateDisplayName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Nama tampilan wajib diisi';
  if (name.length < 2) return 'Nama tampilan minimal 2 karakter';
  if (name.length > 50) return 'Nama tampilan maksimal 50 karakter';
  return null;
}

String? validateMajor(String? value) {
  final major = value?.trim() ?? '';
  if (major.isEmpty) return 'Jurusan wajib diisi';
  if (major.length < 2) return 'Jurusan minimal 2 karakter';
  if (major.length > 80) return 'Jurusan maksimal 80 karakter';
  return null;
}
