import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'auth/auth_page.dart';
import 'auth/username_auth_service.dart';
import 'data/tugas_repository.dart';
import 'firebase_options.dart';
import 'models/tugas.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PrioritasTugasApp());
}

class PrioritasTugasApp extends StatelessWidget {
  const PrioritasTugasApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff14213d);
    return MaterialApp(
      title: 'Prioritas Tugas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: navy),
        scaffoldBackgroundColor: const Color(0xfff7f8fb),
        fontFamily: 'Arial',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: AuthGate(authService: UsernameAuthService()),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.authService});

  final UsernameAuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return BerandaPage(
            repository: FirestoreTugasRepository(),
            authService: authService,
          );
        }
        return AuthPage(authService: authService);
      },
    );
  }
}

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key, required this.repository, this.authService});

  final TugasRepository repository;
  final UsernameAuthService? authService;

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final List<Tugas> tugas = [];
  String filter = 'Semua';
  bool sedangMemuat = true;
  String? pesanError;

  @override
  void initState() {
    super.initState();
    _muatTugas();
  }

  Future<void> _muatTugas() async {
    try {
      final hasil = await widget.repository.getAll();
      if (!mounted) return;
      setState(() {
        tugas
          ..clear()
          ..addAll(hasil);
        sedangMemuat = false;
      });
    } catch (error) {
      debugPrint('Gagal memuat tugas dari Firebase: $error');
      if (!mounted) return;
      setState(() {
        sedangMemuat = false;
        pesanError = 'Data belum dapat dimuat dari Firebase.';
      });
    }
  }

  List<Tugas> get tugasTampil {
    final hasil = tugas.where((item) {
      if (filter == 'Belum dikerjakan') {
        return item.status == StatusTugas.belum;
      }
      if (filter == 'Sedang dikerjakan') {
        return item.status == StatusTugas.dikerjakan;
      }
      if (filter == 'Selesai') {
        return item.status == StatusTugas.selesai;
      }
      return true;
    }).toList();
    hasil.sort((a, b) {
      final prioritas = b.prioritas.compareTo(a.prioritas);
      return prioritas == 0 ? a.deadline.compareTo(b.deadline) : prioritas;
    });
    return hasil;
  }

  int get jumlahSelesai =>
      tugas.where((item) => item.status == StatusTugas.selesai).length;
  int get jumlahBerjalan =>
      tugas.where((item) => item.status == StatusTugas.dikerjakan).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildRingkasan()),
                SliverToBoxAdapter(child: _buildFilter()),
                if (sedangMemuat)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (pesanError != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(pesanError!),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                sedangMemuat = true;
                                pesanError = null;
                              });
                              _muatTugas();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    sliver: SliverList.builder(
                      itemCount: tugasTampil.length,
                      itemBuilder: (context, index) =>
                          _buildTugasCard(tugasTampil[index]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahTugas,
        backgroundColor: const Color(0xff14213d),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah tugas'),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffe3e9f7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.task_alt,
              color: Color(0xff14213d),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prioritas Tugas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff14213d),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Atur langkahmu, selesaikan tepat waktu',
                  style: TextStyle(color: Color(0xff687083)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: widget.authService == null
                ? null
                : () => widget.authService!.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasan() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statCard(
            'Total tugas',
            '${tugas.length}',
            Icons.assignment_outlined,
            const Color(0xffe3e9f7),
          ),
          const SizedBox(width: 10),
          _statCard(
            'Berjalan',
            '$jumlahBerjalan',
            Icons.timelapse_rounded,
            const Color(0xffffead7),
          ),
          const SizedBox(width: 10),
          _statCard(
            'Selesai',
            '$jumlahSelesai',
            Icons.check_circle_outline,
            const Color(0xffdff4e9),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: const Color(0xff14213d)),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xff14213d),
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xff687083)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilter() {
    return SizedBox(
      height: 74,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        scrollDirection: Axis.horizontal,
        children: ['Semua', 'Belum dikerjakan', 'Sedang dikerjakan', 'Selesai']
            .map((item) {
              final aktif = filter == item;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(item),
                  selected: aktif,
                  onSelected: (_) => setState(() => filter = item),
                  selectedColor: const Color(0xff14213d),
                  labelStyle: TextStyle(
                    color: aktif ? Colors.white : const Color(0xff687083),
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                ),
              );
            })
            .toList(),
      ),
    );
  }

  Widget _buildTugasCard(Tugas item) {
    final warna = item.status == StatusTugas.selesai
        ? const Color(0xff258a54)
        : item.status == StatusTugas.dikerjakan
        ? const Color(0xffd27625)
        : const Color(0xffd34d4d);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: item.status == StatusTugas.selesai,
              onChanged: (_) => _ubahStatus(item),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nama,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration: item.status == StatusTugas.selesai
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.mataKuliah,
                    style: const TextStyle(color: Color(0xff687083)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: warna,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatTanggal(item.deadline),
                        style: TextStyle(
                          fontSize: 12,
                          color: warna,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusBadge(item, warna),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'hapus') _hapusTugas(item);
                    if (value == 'edit') _editTugas(item);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit tugas')),
                    PopupMenuItem(value: 'hapus', child: Text('Hapus tugas')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(Tugas item, Color warna) {
    final label = item.status == StatusTugas.selesai
        ? 'Selesai'
        : item.status == StatusTugas.dikerjakan
        ? 'Berjalan'
        : 'Belum';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: warna.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: warna,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatTanggal(DateTime tanggal) {
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final jam = tanggal.hour.toString().padLeft(2, '0');
    final menit = tanggal.minute.toString().padLeft(2, '0');
    return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}, $jam:$menit';
  }

  Future<void> _tambahTugas() async {
    final hasil = await showDialog<Tugas>(
      context: context,
      builder: (_) => const FormTugasDialog(),
    );
    if (hasil == null) return;
    try {
      final tersimpan = await widget.repository.add(hasil);
      if (mounted) setState(() => tugas.add(tersimpan));
    } catch (_) {
      if (mounted) _tampilkanError();
    }
  }

  Future<void> _editTugas(Tugas item) async {
    final hasil = await showDialog<Tugas>(
      context: context,
      builder: (_) => FormTugasDialog(tugas: item),
    );
    if (hasil == null) return;
    item.nama = hasil.nama;
    item.mataKuliah = hasil.mataKuliah;
    item.deadline = hasil.deadline;
    item.prioritas = hasil.prioritas;
    try {
      await widget.repository.update(item);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) _tampilkanError();
    }
  }

  Future<void> _ubahStatus(Tugas item) async {
    final statusLama = item.status;
    setState(
      () => item.status = item.status == StatusTugas.selesai
          ? StatusTugas.belum
          : StatusTugas.selesai,
    );
    try {
      await widget.repository.update(item);
    } catch (_) {
      if (mounted) {
        setState(() => item.status = statusLama);
        _tampilkanError();
      }
    }
  }

  Future<void> _hapusTugas(Tugas item) async {
    try {
      await widget.repository.delete(item);
      if (mounted) setState(() => tugas.remove(item));
    } catch (_) {
      if (mounted) _tampilkanError();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tugas berhasil dihapus')));
  }

  void _tampilkanError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gagal menyimpan data ke Firebase')),
    );
  }
}

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
