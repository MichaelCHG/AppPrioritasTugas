import 'package:flutter/material.dart';

import '../data/tugas_repository.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

class AppRoutes {
  static const home = '/';

  static Map<String, WidgetBuilder> routes(UsernameAuthService authService) => {
    home: (_) => AuthGate(authService: authService),
  };
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
          final repository = CachedTugasRepository(
            remote: FirestoreTugasRepository(),
            cache: SharedPreferencesTugasRepository(userId: snapshot.data!.uid),
          );
          return BerandaPage(
            repository: repository,
            authService: authService,
            onDeleteAccount: (password) => authService.deleteAccount(
              password: password,
              deleteUserData: repository.deleteAll,
            ),
          );
        }
        return AuthPage(authService: authService);
      },
    );
  }
}
