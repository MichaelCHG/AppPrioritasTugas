import 'dart:async';

import 'package:flutter/material.dart';

import '../models/tugas.dart';
import '../state/tugas_controller.dart';

class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({super.key, required this.controller});

  final TugasController controller;

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  static const _sessionDuration = Duration(minutes: 25);

  Duration _remaining = _sessionDuration;
  Timer? _timer;
  DateTime? _endsAt;
  String? _selectedTaskId;
  bool _isRunning = false;

  Tugas? get _selectedTask {
    for (final task in widget.controller.tugas) {
      if (task.id == _selectedTaskId && task.status != StatusTugas.selesai) {
        return task;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
      return;
    }
    if (_remaining == Duration.zero) _remaining = _sessionDuration;
    _endsAt = DateTime.now().add(_remaining);
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _endsAt!.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        _timer?.cancel();
        setState(() {
          _remaining = Duration.zero;
          _isRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi fokus 25 menit selesai.')),
        );
      } else {
        setState(() => _remaining = remaining);
      }
    });
  }

  void _pauseTimer() {
    final endsAt = _endsAt;
    if (endsAt != null) {
      _remaining = endsAt.difference(DateTime.now());
      if (_remaining < Duration.zero) _remaining = Duration.zero;
    }
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remaining = _sessionDuration;
      _isRunning = false;
      _endsAt = null;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final availableTasks = widget.controller.tugas
            .where(
              (task) => task.id != null && task.status != StatusTugas.selesai,
            )
            .toList();
        final selectedTask = _selectedTask;
        final progress = _remaining.inSeconds / _sessionDuration.inSeconds;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sesi fokus',
                style: TextStyle(
                  color: Color(0xff14213d),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kerjakan satu tugas selama 25 menit, lalu ambil jeda.',
                style: TextStyle(color: Color(0xff687083)),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: selectedTask?.id,
                decoration: const InputDecoration(
                  labelText: 'Fokus pada tugas (opsional)',
                  prefixIcon: Icon(Icons.assignment_outlined),
                ),
                items: availableTasks
                    .map(
                      (task) => DropdownMenuItem(
                        value: task.id!,
                        child: Text(task.nama, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _isRunning
                    ? null
                    : (value) => setState(() => _selectedTaskId = value),
              ),
              const SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: 230,
                  height: 230,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: const Color(0xffe3e9f7),
                          color: const Color(0xff14213d),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDuration(_remaining),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff14213d),
                            ),
                          ),
                          const Text(
                            'MENIT FOKUS',
                            style: TextStyle(
                              color: Color(0xff687083),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              if (selectedTask != null)
                Text(
                  'Tugas: ${selectedTask.nama}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _toggleTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? 'Jeda' : 'Mulai fokus'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Ulangi'),
                  ),
                ],
              ),
              if (availableTasks.isEmpty) ...[
                const SizedBox(height: 22),
                const Text(
                  'Belum ada tugas aktif. Tambahkan tugas atau mulai sesi fokus bebas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xff687083)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
