# Prioritas Tugas

Aplikasi Flutter untuk mencatat tugas kuliah, mengatur deadline, prioritas,
kesulitan, catatan, dan status pengerjaan.

## Alur demo

1. Daftar dengan username (3-24 karakter: huruf kecil, angka, atau `_`) dan
   password minimal 6 karakter, lalu masuk.
2. Tambah atau edit tugas dengan mata kuliah, deadline, prioritas, kesulitan,
   dan catatan. Tugas baru harus memiliki deadline di masa depan.
3. Gunakan filter status dan menu tiap tugas untuk memperbarui status menjadi
   belum dikerjakan atau sedang dikerjakan. Saat tugas dicentang selesai,
   setujui dialog konfirmasi untuk memindahkannya dari daftar aktif ke tab
   **Riwayat**. Riwayat mempertahankan data tugas; tindakan ini tidak menghapus
   dokumen secara permanen.
4. Beranda menampilkan popup pengingat di bagian atas selama beberapa detik jika
   tugas belum selesai akan jatuh tempo dalam satu jam. Kotak **Belum selesai**
   berwarna merah menampilkan jumlah tugas aktif. Pengingat hanya muncul saat
   aplikasi terbuka/aktif kembali, bukan notifikasi sistem.
5. Tab **Fokus** menyediakan timer Pomodoro 25 menit yang dapat dikaitkan dengan
   tugas, dijeda, atau diulang.

## Cara mengecek autentikasi dan form

1. Pastikan koneksi internet tersedia dan Firebase Authentication provider
   **Email/Password** aktif di Firebase Console proyek.
2. Jalankan aplikasi dari `apps/mobile` dengan `flutter run` (atau jalankan
   aplikasi yang sama dari VS Code).
3. Pada layar masuk, tekan **Belum punya akun? Daftar**. Masukkan username
   3-24 karakter (huruf kecil, angka, atau `_`) dan password minimal 6
   karakter. Tekan **Daftar**; setelah berhasil aplikasi masuk ke beranda.
   Username dipetakan ke email internal Firebase, jadi tidak perlu email pribadi.
4. Tekan **Keluar**, lalu masukkan username dan password yang sama untuk menguji
   login. Username yang belum terdaftar atau password salah akan menampilkan
   pesan error.
5. Tekan **Tambah tugas**, isi nama tugas, mata kuliah, pilih deadline masa
   depan, prioritas, kesulitan, dan catatan opsional. Tekan **Simpan** lalu
   pastikan tugas terlihat di daftar. Nama kosong/kurang dari 3 karakter dan
   deadline yang sudah lewat akan ditolak.
6. Untuk mencoba batal, buka kembali form lalu tekan **Batal**, atau tutup
   pemilih tanggal/jam tanpa memilih. Untuk menguji penyuntingan dan penghapusan,
   gunakan menu titik tiga pada kartu tugas; penghapusan meminta konfirmasi.
7. Centang tugas aktif, pilih **Selesaikan** pada dialog, lalu buka **Riwayat**
   untuk memastikan tugas berpindah dan masih tersimpan. Pilih **Batal** pada
   dialog untuk memastikan tugas tidak berubah.
8. Untuk menguji penghapusan akun, buka menu **⋮ > Hapus akun**, baca peringatan,
   masukkan password akun, lalu konfirmasi. Firebase meminta verifikasi password
   terbaru; jika password salah, akun tetap ada. Jika berhasil, dokumen tugas
   cloud, cache lokal, dan akun Firebase dihapus permanen.

Jika login gagal dengan pesan provider belum aktif, aktifkan Email/Password di
Firebase Console > Authentication > Sign-in method. Data akun dan tugas demo
akan tersimpan pada proyek Firebase yang dikonfigurasi untuk aplikasi.

## Implementasi lanjutan

- **Autentikasi:** Firebase Authentication memakai username yang dipetakan ke
  email internal aplikasi; tidak memerlukan alamat email pribadi.
- **Pengingat deadline:** popup sementara di bagian atas beranda dan penghitung
  tugas aktif berwarna merah, tanpa meminta izin notifikasi sistem.
- **Sesi fokus:** timer Pomodoro untuk membantu mahasiswa mengerjakan satu tugas
  dalam blok fokus dan mengelola jeda.
- **Penyimpanan:** Firestore menyimpan data per pengguna di
  `users/{uid}/tasks`; SharedPreferences menjadi cache baca per akun saat
  Firestore tidak tersedia.
- **Hapus akun:** meminta password untuk autentikasi ulang, menghapus tugas
  Firestore dan cache pengguna, kemudian menghapus akun Firebase. Karena
  penghapusan data cloud dan akun bukan satu transaksi, gangguan koneksi di
  tengah proses dapat membuat sebagian tugas terhapus sebelum akun selesai
  dihapus; aplikasi menampilkan error agar pengguna dapat mencoba lagi.

Firestore diakses melalui Firebase SDK, bukan REST API terpisah. Jalankan
verifikasi dari folder ini dengan `flutter test` dan `flutter analyze`.
