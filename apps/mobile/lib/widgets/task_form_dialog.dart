import 'package:flutter/material.dart';

import '../models/tugas.dart';
import '../state/tugas_controller.dart';

class FormTugasDialog extends StatefulWidget {
  const FormTugasDialog({super.key, this.tugas, required this.controller});

  final Tugas? tugas;
  final TugasController controller;

  @override
  State<FormTugasDialog> createState() => _FormTugasDialogState();
}

class _FormTugasDialogState extends State<FormTugasDialog> {
  late final TextEditingController namaController;
  late final TextEditingController mataKuliahController;
  final _formKey = GlobalKey<FormState>();
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
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => AlertDialog(
        title: Text(widget.tugas == null ? 'Tambah tugas' : 'Edit tugas'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: namaController,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Nama tugas *',
                      ),
                      validator: (value) {
                        final nama = value?.trim() ?? '';
                        if (nama.isEmpty) return 'Nama tugas wajib diisi';
                        if (nama.length < 3) return 'Minimal 3 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: mataKuliahController,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Mata kuliah',
                      ),
                      validator: (value) => (value?.length ?? 0) > 60
                          ? 'Maksimal 60 karakter'
                          : null,
                    ),
                  ],
                ),
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
              if (widget.controller.submitError case final error?) ...[
                const SizedBox(height: 12),
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: widget.controller.isSubmitting ? null : _simpan,
            child: widget.controller.isSubmitting
                ? const SizedBox(
                    key: Key('submit-progress'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
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

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final berhasil = await widget.controller.save(
      Tugas(
        nama: namaController.text.trim(),
        mataKuliah: mataKuliahController.text.trim().isEmpty
            ? 'Tanpa mata kuliah'
            : mataKuliahController.text.trim(),
        deadline: deadline,
        prioritas: prioritas,
        status: widget.tugas?.status ?? StatusTugas.belum,
      ),
      existing: widget.tugas,
    );
    if (berhasil && mounted) Navigator.pop(context);
  }
}
