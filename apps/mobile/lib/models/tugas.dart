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
    return Tugas(
      id: id,
      nama: map['nama'] as String? ?? '',
      mataKuliah: map['mataKuliah'] as String? ?? 'Tanpa mata kuliah',
      deadline: (map['deadline'] as dynamic).toDate(),
      prioritas: (map['prioritas'] as num?)?.toInt() ?? 2,
      status: StatusTugas.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => StatusTugas.belum,
      ),
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
