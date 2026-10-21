import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusTugas { belum, dikerjakan, selesai }

class Tugas {
  Tugas({
    this.id,
    required this.nama,
    required this.mataKuliah,
    required this.deadline,
    required this.prioritas,
    this.status = StatusTugas.belum,
  });

  String? id;
  String nama;
  String mataKuliah;
  DateTime deadline;
  int prioritas;
  StatusTugas status;

  factory Tugas.fromMap(String id, Map<String, dynamic> map) {
    final nama = map['nama'];
    if (nama is! String || nama.trim().isEmpty) {
      throw const FormatException('Nama tugas tidak valid.');
    }

    final rawMataKuliah = map['mataKuliah'];
    if (rawMataKuliah != null && rawMataKuliah is! String) {
      throw const FormatException('Mata kuliah tidak valid.');
    }

    final rawDeadline = map['deadline'];
    final deadline = switch (rawDeadline) {
      DateTime value => value,
      String value => DateTime.parse(value),
      Timestamp value => value.toDate(),
      _ => throw const FormatException('Deadline tugas tidak valid.'),
    };
    final rawPrioritas = map['prioritas'];
    if (rawPrioritas is! int || rawPrioritas < 1 || rawPrioritas > 3) {
      throw const FormatException('Prioritas tugas tidak valid.');
    }
    final rawStatus = map['status'];
    final matchingStatuses = StatusTugas.values
        .where((item) => item.name == rawStatus);
    if (rawStatus != null && matchingStatuses.isEmpty) {
      throw const FormatException('Status tugas tidak valid.');
    }
    final status = rawStatus == null
        ? StatusTugas.belum
        : matchingStatuses.first;

    return Tugas(
      id: id,
      nama: nama,
      mataKuliah: rawMataKuliah as String? ?? 'Tanpa mata kuliah',
      deadline: deadline,
      prioritas: rawPrioritas,
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'mataKuliah': mataKuliah,
      'deadline': deadline,
      'prioritas': prioritas,
      'status': status.name,
    };
  }
}
