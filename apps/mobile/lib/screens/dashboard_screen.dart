import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/tugas_repository.dart';
import '../models/tugas.dart';
import 'focus_session_screen.dart';
import '../services/auth_service.dart';
import '../state/tugas_controller.dart';
import '../widgets/task_form_dialog.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({
    super.key,
    required this.repository,
    this.authService,
    this.onDeleteAccount,
  });

  final TugasRepository repository;
  final UsernameAuthService? authService;
  final Future<void> Function(String password)? onDeleteAccount;

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> with WidgetsBindingObserver {
  late final TugasController _controller;
  String filter = 'Semua';
  int _selectedTab = 0;
  final Set<String> _notifiedDeadlineIds = {};
  OverlayEntry? _deadlinePopup;
  Timer? _deadlinePopupTimer;
  Timer? _deadlineCheckTimer;

  List<Tugas> get tugas => _controller.tugas;
  bool get sedangMemuat => _controller.isLoading;
  String? get pesanError => _controller.error;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TugasController(widget.repository);
    _controller.addListener(_checkDeadlineNotifications);
    _deadlineCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkDeadlineNotifications(),
    );
    _controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deadlinePopupTimer?.cancel();
    _deadlineCheckTimer?.cancel();
    _deadlinePopup?.remove();
    _deadlinePopup?.dispose();
    _controller.removeListener(_checkDeadlineNotifications);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDeadlineNotifications();
    }
  }

  void _checkDeadlineNotifications() {
    if (!mounted || _controller.isLoading || _controller.error != null) return;
    final now = DateTime.now();
    final newlyDue = tugas.where((item) {
      final id = item.id ?? '${item.nama}-${item.deadline.toIso8601String()}';
      return item.status != StatusTugas.selesai &&
          item.deadline.isAfter(now) &&
          item.deadline.difference(now) <= const Duration(hours: 1) &&
          !_notifiedDeadlineIds.contains(id);
    }).toList()..sort((a, b) => a.deadline.compareTo(b.deadline));
    if (newlyDue.isEmpty) return;

    for (final item in newlyDue) {
      _notifiedDeadlineIds.add(
        item.id ?? '${item.nama}-${item.deadline.toIso8601String()}',
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showDeadlinePopup(newlyDue);
    });
  }

  void _showDeadlinePopup(List<Tugas> dueTasks) {
    _deadlinePopupTimer?.cancel();
    _deadlinePopup?.remove();
    _deadlinePopup?.dispose();
    final taskNames = dueTasks.take(2).map((task) => task.nama).join(', ');
    final remainingCount = dueTasks.length - 2;
    final message = remainingCount > 0
        ? '$taskNames dan $remainingCount tugas lainnya segera jatuh tempo.'
        : '$taskNames segera jatuh tempo.';
    _deadlinePopup = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 16,
        right: 16,
        child: SafeArea(
          bottom: false,
          child: Material(
            color: Colors.transparent,
            child: Card(
              key: const Key('deadline-popup'),
              margin: EdgeInsets.zero,
              color: const Color(0xfffff1d6),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      color: Color(0xffa45d00),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pengingat deadline: $message',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup pengingat',
                      onPressed: _dismissDeadlinePopup,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_deadlinePopup!);
    _deadlinePopupTimer = Timer(
      const Duration(seconds: 6),
      _dismissDeadlinePopup,
    );
  }

  void _dismissDeadlinePopup() {
    _deadlinePopupTimer?.cancel();
    _deadlinePopupTimer = null;
    _deadlinePopup?.remove();
    _deadlinePopup?.dispose();
    _deadlinePopup = null;
  }

  List<Tugas> get tugasTampil {
    final hasil = tugas.where((item) {
      if (item.status == StatusTugas.selesai) return false;
      if (filter == 'Belum dikerjakan') {
        return item.status == StatusTugas.belum;
      }
      if (filter == 'Sedang dikerjakan') {
        return item.status == StatusTugas.dikerjakan;
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
  int get jumlahBelumSelesai =>
      tugas.where((item) => item.status != StatusTugas.selesai).length;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: CustomScrollView(
                slivers: [
                  if (_selectedTab == 0) ...[
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
                                onPressed: _controller.load,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_controller.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined, size: 48),
                              SizedBox(height: 12),
                              Text('Belum ada tugas'),
                              SizedBox(height: 4),
                              Text('Tambahkan tugas pertamamu untuk memulai.'),
                            ],
                          ),
                        ),
                      )
                    else if (tugasTampil.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                jumlahSelesai > 0 && filter == 'Semua'
                                    ? 'Semua tugas aktif sudah selesai.'
                                    : 'Tidak ada tugas pada filter ini.',
                              ),
                              if (jumlahSelesai > 0 && filter == 'Semua')
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _selectedTab = 2),
                                  child: const Text('Lihat riwayat'),
                                )
                              else
                                TextButton(
                                  onPressed: () =>
                                      setState(() => filter = 'Semua'),
                                  child: const Text('Tampilkan semua'),
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
                  ] else if (_selectedTab == 1)
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: FocusSessionScreen(controller: _controller),
                    )
                  else ...[
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildHistoryHeader()),
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
                                onPressed: _controller.load,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (jumlahSelesai == 0)
                      const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history, size: 48),
                              SizedBox(height: 12),
                              Text('Riwayat masih kosong'),
                              SizedBox(height: 4),
                              Text(
                                'Tugas yang diselesaikan akan muncul di sini.',
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        sliver: SliverList.builder(
                          itemCount: _tugasSelesai.length,
                          itemBuilder: (context, index) =>
                              _buildTugasCard(_tugasSelesai[index]),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: _selectedTab == 0
            ? FloatingActionButton.extended(
                onPressed: _tambahTugas,
                backgroundColor: const Color(0xff14213d),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Tambah tugas'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: (index) =>
              setState(() => _selectedTab = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: 'Fokus',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Riwayat',
            ),
          ],
        ),
      ),
    );
  }

  List<Tugas> get _tugasSelesai =>
      tugas.where((item) => item.status == StatusTugas.selesai).toList()
        ..sort((a, b) => b.deadline.compareTo(a.deadline));

  Widget _buildHistoryHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Riwayat tugas selesai',
              style: TextStyle(
                color: Color(0xff14213d),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text('${_tugasSelesai.length} tugas'),
        ],
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
          if (widget.authService != null || widget.onDeleteAccount != null)
            PopupMenuButton<String>(
              tooltip: 'Menu akun',
              onSelected: (value) {
                if (value == 'logout') widget.authService?.logout();
                if (value == 'delete-account') _confirmDeleteAccount();
              },
              itemBuilder: (_) => [
                if (widget.authService != null)
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout),
                      title: Text('Keluar'),
                    ),
                  ),
                if (widget.onDeleteAccount != null)
                  const PopupMenuItem(
                    value: 'delete-account',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_forever, color: Colors.red),
                      title: Text(
                        'Hapus akun',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
              ],
              icon: const Icon(Icons.more_vert),
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
            'Belum selesai',
            '$jumlahBelumSelesai',
            Icons.assignment_outlined,
            const Color(0xffffe3e3),
            isAlert: true,
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

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isAlert = false,
  }) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isAlert
                      ? const Color(0xffc62828)
                      : const Color(0xff14213d),
                ),
                if (isAlert && jumlahBelumSelesai > 0)
                  Container(
                    key: const Key('unfinished-task-count'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffc62828),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$jumlahBelumSelesai',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isAlert ? Color(0xffc62828) : Color(0xff14213d),
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
        children: ['Semua', 'Belum dikerjakan', 'Sedang dikerjakan'].map((
          item,
        ) {
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
        }).toList(),
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _detailBadge(
                        'Prioritas ${_labelPrioritas(item.prioritas)}',
                        Icons.flag_outlined,
                      ),
                      _detailBadge(
                        'Kesulitan ${_labelKesulitan(item.kesulitan)}',
                        Icons.bolt_outlined,
                      ),
                    ],
                  ),
                  if (item.catatan.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.catatan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff687083),
                        fontSize: 12,
                      ),
                    ),
                  ],
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
                  onSelected: (value) async {
                    if (value == 'hapus') _hapusTugas(item);
                    if (value == 'edit') _editTugas(item);
                    if (value.startsWith('status:')) {
                      final status = StatusTugas.values.firstWhere(
                        (candidate) => candidate.name == value.substring(7),
                      );
                      if (status == StatusTugas.selesai &&
                          item.status != StatusTugas.selesai) {
                        await _ubahStatus(item);
                        return;
                      }
                      final saved = await _controller.setStatus(item, status);
                      if (!saved && mounted) _tampilkanError();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit tugas'),
                    ),
                    ...StatusTugas.values.map(
                      (status) => PopupMenuItem(
                        value: 'status:${status.name}',
                        child: Text('Tandai: ${_statusLabel(status)}'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'hapus',
                      child: Text('Hapus tugas'),
                    ),
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

  Widget _detailBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xfff0f2f7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xff687083)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xff687083)),
          ),
        ],
      ),
    );
  }

  String _labelPrioritas(int prioritas) => switch (prioritas) {
    1 => 'rendah',
    2 => 'sedang',
    3 => 'tinggi',
    _ => 'tidak diketahui',
  };

  String _labelKesulitan(int kesulitan) => switch (kesulitan) {
    1 => 'mudah',
    2 => 'sedang',
    3 => 'sulit',
    _ => 'tidak diketahui',
  };

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

  String _statusLabel(StatusTugas status) => switch (status) {
    StatusTugas.belum => 'Belum dikerjakan',
    StatusTugas.dikerjakan => 'Sedang dikerjakan',
    StatusTugas.selesai => 'Selesai',
  };

  Future<void> _tambahTugas() async {
    await showDialog<void>(
      context: context,
      builder: (_) => FormTugasDialog(controller: _controller),
    );
  }

  Future<void> _editTugas(Tugas item) async {
    await showDialog<void>(
      context: context,
      builder: (_) => FormTugasDialog(tugas: item, controller: _controller),
    );
  }

  Future<void> _ubahStatus(Tugas item) async {
    final statusBaru = item.status == StatusTugas.selesai
        ? StatusTugas.belum
        : StatusTugas.selesai;
    if (statusBaru == StatusTugas.selesai) {
      final yakin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Selesaikan tugas?'),
          content: Text(
            '"${item.nama}" akan dipindahkan dari daftar aktif ke riwayat tugas selesai.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Selesaikan'),
            ),
          ],
        ),
      );
      if (yakin != true || !mounted) return;
    }
    final tersimpan = await _controller.setStatus(item, statusBaru);
    if (!tersimpan && mounted) _tampilkanError();
  }

  Future<void> _hapusTugas(Tugas item) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('Tugas "${item.nama}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;
    final terhapus = await _controller.delete(item);
    if (!terhapus) {
      if (mounted) _tampilkanError();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tugas berhasil dihapus')));
  }

  Future<void> _confirmDeleteAccount() async {
    final deleteAccount = widget.onDeleteAccount;
    if (deleteAccount == null || _isDeletingAccount) return;
    var obscurePassword = true;
    var passwordValue = '';
    final password = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: const Text('Hapus akun secara permanen?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Akun Firebase, semua tugas di cloud, dan cache lokal akun ini akan dihapus. Tindakan ini tidak dapat dibatalkan.',
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('delete-account-password'),
                obscureText: obscurePassword,
                autofocus: true,
                onChanged: (value) => setDialogState(() {
                  passwordValue = value;
                }),
                decoration: InputDecoration(
                  labelText: 'Masukkan password untuk mengonfirmasi',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: obscurePassword
                        ? 'Tampilkan password'
                        : 'Sembunyikan password',
                    onPressed: () => setDialogState(
                      () => obscurePassword = !obscurePassword,
                    ),
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: passwordValue.isEmpty
                  ? null
                  : () => Navigator.pop(context, passwordValue),
              child: const Text('Hapus akun'),
            ),
          ],
        ),
      ),
    );
    if (password == null || !mounted) return;
    setState(() => _isDeletingAccount = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Menghapus akun dan data...')),
          ],
        ),
      ),
    );
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      await deleteAccount(password);
      if (navigator.canPop()) navigator.pop();
      if (mounted) setState(() => _isDeletingAccount = false);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      if (navigator.canPop()) navigator.pop();
      setState(() => _isDeletingAccount = false);
      final message = switch (error.code) {
        'wrong-password' ||
        'invalid-credential' => 'Password salah. Akun belum dihapus.',
        'requires-recent-login' =>
          'Sesi login sudah lama. Keluar, masuk kembali, lalu coba hapus akun.',
        'network-request-failed' => 'Tidak ada koneksi. Penghapusan akun tidak selesai; sebagian data mungkin sudah terhapus.',
        _ =>
          'Penghapusan akun gagal (${error.code}); sebagian data mungkin sudah terhapus.',
      };
      _showAccountDeletionError(message);
    } catch (error) {
      if (!mounted) return;
      if (navigator.canPop()) navigator.pop();
      setState(() => _isDeletingAccount = false);
      debugPrint('Gagal menghapus akun: $error');
      _showAccountDeletionError(
        'Penghapusan tidak selesai. Sebagian tugas mungkin sudah terhapus, tetapi akun mungkin masih aktif. Detail: $error',
      );
    }
  }

  void _showAccountDeletionError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  void _tampilkanError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gagal menyimpan data ke Firebase')),
    );
  }
}
