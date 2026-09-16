import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'username_auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.authService});

  final UsernameAuthService authService;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;
  bool isLoading = false;
  String? errorMessage;
  bool obscurePassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    final username = usernameController.text.trim().toLowerCase();
    final password = passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Username dan password wajib diisi.');
      return;
    }
    if (!isLogin && password.length < 6) {
      setState(() => errorMessage = 'Password minimal 6 karakter.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      if (isLogin) {
        await widget.authService.login(username, password);
      } else {
        await widget.authService.register(username, password);
      }
    } on FormatException catch (error) {
      _showError(error.message);
    } on FirebaseAuthException catch (error) {
      _showError(_messageFor(error.code));
    } catch (_) {
      _showError('Tidak dapat terhubung ke Firebase. Coba lagi.');
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _showError(String message) {
    if (mounted) setState(() => errorMessage = message);
  }

  String _messageFor(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Username atau password salah.';
      case 'email-already-in-use':
        return 'Username sudah digunakan.';
      case 'weak-password':
        return 'Password minimal 6 karakter.';
      case 'operation-not-allowed':
        return 'Login password belum diaktifkan di Firebase Console.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      default:
        return 'Login gagal. Kode: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.task_alt,
                        size: 52,
                        color: Color(0xff14213d),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isLogin ? 'Masuk ke Prioritas Tugas' : 'Buat akun baru',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLogin
                            ? 'Gunakan username dan password Anda.'
                            : 'Akun ini dapat dipakai di Chrome dan HP.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xff687083)),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: usernameController,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        onSubmitted: (_) => submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: isLoading ? null : submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isLogin ? 'Masuk' : 'Daftar'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => setState(() {
                                isLogin = !isLogin;
                                errorMessage = null;
                              }),
                        child: Text(
                          isLogin
                              ? 'Belum punya akun? Daftar'
                              : 'Sudah punya akun? Masuk',
                        ),
                      ),
                      if (!isLogin)
                        const Text(
                          'Username: 3-24 karakter, hanya huruf kecil, angka, dan garis bawah.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xff687083),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
