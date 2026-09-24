# Struktur Kode Flutter Prioritas Tugas

Dokumen ini menjelaskan lokasi kode utama aplikasi Flutter Prioritas Tugas di
folder `apps/mobile/lib`.

## Konsep Pengembangan

### Prototype UI/UX

Prototype adalah rancangan awal halaman dan alur aplikasi. Prototype dapat
dibuat di Figma atau langsung menggunakan mock UI Flutter.

Halaman utama yang direncanakan untuk aplikasi ini:

- Login dan registrasi pengguna
- Dashboard atau daftar prioritas tugas
- Form tambah dan edit tugas
- Detail tugas
- Profile atau pengaturan pengguna

Saat ini halaman login berada di `auth/auth_page.dart`, sedangkan halaman utama
aplikasi dibuat dari alur yang dipanggil melalui `main.dart`.

### Struktur Proyek

```text
apps/mobile/lib/
├── main.dart                    # Bootstrap aplikasi dan AuthGate
├── firebase_options.dart        # Konfigurasi Firebase per platform
├── auth/
│   ├── auth_page.dart           # UI login dan registrasi
│   └── username_auth_service.dart # Service autentikasi Firebase
├── data/
│   └── tugas_repository.dart    # Kontrak dan implementasi akses data tugas
└── models/
    └── tugas.dart               # Model domain tugas
```

Struktur ini memisahkan tampilan autentikasi, service, akses data, dan model
sehingga setiap bagian lebih mudah dirawat dan diuji.

## Routing

Routing mengatur perpindahan antarhalaman. Saat ini alur navigasi awal dikontrol
oleh `AuthGate` di `main.dart` berdasarkan status login Firebase:

```text
main.dart
└── AuthGate
    ├── belum login  -> auth/auth_page.dart
    └── sudah login  -> halaman utama daftar tugas
```

Jika jumlah halaman bertambah, routing dapat dipisahkan menjadi:

```text
lib/routes/app_routes.dart
```

File tersebut dapat berisi nama route dan konfigurasi `MaterialApp.routes` atau
`onGenerateRoute`.

## Reusable Component atau Widget

Widget yang digunakan berulang sebaiknya dipindahkan ke folder khusus agar UI
konsisten dan tidak menyalin kode yang sama:

```text
lib/widgets/
├── primary_button.dart          # Tombol aksi utama
├── app_text_field.dart          # Input field dengan gaya aplikasi
├── task_card.dart               # Ringkasan satu tugas
└── app_app_bar.dart             # App bar bersama
```

Folder `widgets` dapat ditambahkan ketika komponen reusable mulai digunakan di
lebih dari satu halaman.

## Pengembangan Struktur Berikutnya

Jika halaman aplikasi bertambah, struktur yang disarankan adalah:

```text
lib/
├── main.dart
├── app.dart
├── routes/
│   └── app_routes.dart
├── screens/
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── task_detail_screen.dart
│   └── profile_screen.dart
├── widgets/
├── models/
├── services/
└── data/
```

Pembagian tanggung jawabnya:

- `screens/`: halaman penuh yang dirender oleh route.
- `widgets/`: komponen UI reusable.
- `models/`: struktur data domain seperti `Tugas`.
- `services/`: integrasi eksternal seperti Firebase Authentication.
- `data/`: repository dan sumber penyimpanan data.
- `routes/`: definisi navigasi antarhalaman.

## Perintah Menjalankan Aplikasi

Jalankan perintah berikut dari folder `apps/mobile`:

```bash
flutter pub get
flutter run
```

Untuk menjalankan pemeriksaan kode dan test:

```bash
flutter analyze
flutter test
```
