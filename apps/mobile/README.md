# prioritas_tugas
Mobile app memakai Firebase Authentication untuk login dan Cloud Firestore
sebagai backend tugas. Data setiap akun berada pada `users/{uid}/tasks`; daftar
tugas dimuat melalui repository dan perubahan tambah, edit, status, serta hapus
diteruskan ke Firestore. SharedPreferences menjadi cache per pengguna untuk
mendukung pembacaan saat Firestore tidak tersedia.

Firestore diakses melalui Firebase SDK, bukan melalui REST API terpisah.
Repository dan model diuji dengan fake backend serta cache lokal, termasuk
pemuatan sukses, data kosong, kegagalan layanan, dan JSON cache rusak. Jalankan
verifikasi dari folder ini dengan `flutter test` dan `flutter analyze`.
