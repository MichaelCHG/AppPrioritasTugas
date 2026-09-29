import 'package:firebase_auth/firebase_auth.dart';

class UsernameAuthService {
  UsernameAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  static const _emailDomain = 'prioritastugas.app';

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> register(String username, String password) async {
    final email = _emailFor(username);
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> login(String username, String password) async {
    final email = _emailFor(username);
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() => _auth.signOut();

  String _emailFor(String username) {
    final normalized = username.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(normalized)) {
      throw const FormatException(
        'Username harus 3-24 karakter: huruf kecil, angka, atau garis bawah.',
      );
    }
    return '$normalized@$_emailDomain';
  }
}
