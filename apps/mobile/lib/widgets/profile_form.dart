import 'package:flutter/material.dart';

import '../data/profile_repository.dart';
import '../models/user_profile.dart';
import '../validation/profile_validation.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key, required this.repository});

  final ProfileRepository repository;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _majorController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      final profile = await widget.repository.getProfile();
      if (!mounted) return;
      _displayNameController.text = profile.displayName;
      _majorController.text = profile.major;
      setState(() => _isLoading = false);
    } catch (error) {
      debugPrint('Gagal memuat profil: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
        _error = 'Profil gagal dimuat. Periksa koneksi, lalu coba lagi.';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.repository.saveProfile(
        UserProfile(
          displayName: _displayNameController.text.trim(),
          major: _majorController.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      debugPrint('Gagal menyimpan profil: $error');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Profil gagal disimpan. Periksa koneksi, lalu coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profil'),
      content: SizedBox(
        width: 420,
        child: _isLoading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(key: Key('profile-loading')),
                  SizedBox(height: 12),
                  Text('Memuat profil...'),
                ],
              )
            : _buildFormContent(context),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        if (!_loadFailed)
          FilledButton(
            onPressed: _isLoading || _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        key: Key('profile-submit-progress'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Menyimpan...'),
                    ],
                  )
                : const Text('Simpan profil'),
          ),
      ],
    );
  }

  Widget _buildFormContent(BuildContext context) {
    if (_loadFailed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const Key('profile-display-name'),
            controller: _displayNameController,
            maxLength: 50,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nama tampilan *'),
            validator: validateDisplayName,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('profile-major'),
            controller: _majorController,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Jurusan *'),
            validator: validateMajor,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
