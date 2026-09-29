import 'package:flutter/material.dart';

import '../models/tugas.dart';

class FormTugasDialog extends StatefulWidget {
  const FormTugasDialog({super.key, this.tugas});

  final Tugas? tugas;

  @override
  State<FormTugasDialog> createState() => _FormTugasDialogState();
}

class _FormTugasDialogState extends State<FormTugasDialog> {
  late final TextEditingController namaController;
  late final TextEditingController mataKuliahController;
  late DateTime deadline;
  late int prioritas;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.tugas?.nama);
    mataKuliahController = TextEditingController(
      text: widget.tugas?.mataKuliah,
    );
    deadline =
        widget.tugas?.deadline ?? DateTime.now().add(const Duration(days: 1));
    prioritas = widget.tugas?.prioritas ?? 2;
  }

  @override
  void dispose() {
    namaController.dispose();
    mataKuliahController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tugas == null ? 'Tambah tugas' : 'Edit tugas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama tugas *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mataKuliahController,
              decoration: const InputDecoration(labelText: 'Mata kuliah'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pilihTanggal,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      '${deadline.day}/${deadline.month}/${deadline.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pilihJam,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      '${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: prioritas,
              decoration: const InputDecoration(labelText: 'Prioritas'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Rendah')),
                DropdownMenuItem(value: 2, child: Text('Sedang')),
                DropdownMenuItem(value: 3, child: Text('Tinggi')),
              ],
              onChanged: (value) => setState(() => prioritas = value ?? 2),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _simpan, child: const Text('Simpan')),
      ],
    );
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: deadline,
    );
    if (hasil != null) {
      setState(
        () => deadline = DateTime(
          hasil.year,
          hasil.month,
          hasil.day,
          deadline.hour,
          deadline.minute,
        ),
      );
    }
  }

  Future<void> _pilihJam() async {
    final hasil = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(deadline),
    );
    if (hasil != null) {
      setState(
        () => deadline = DateTime(
          deadline.year,
          deadline.month,
          deadline.day,
          hasil.hour,
          hasil.minute,
        ),
      );
    }
  }

  void _simpan() {
    if (namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama tugas wajib diisi')));
      return;
    }
    Navigator.pop(
      context,
      Tugas(
        nama: namaController.text.trim(),
        mataKuliah: mataKuliahController.text.trim().isEmpty
            ? 'Tanpa mata kuliah'
            : mataKuliahController.text.trim(),
        deadline: deadline,
        prioritas: prioritas,
        status: widget.tugas?.status ?? StatusTugas.belum,
      ),
    );
  }
}
