import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'services/auth_service.dart';

class PrioritasTugasApp extends StatelessWidget {
  PrioritasTugasApp({super.key}) : authService = UsernameAuthService();

  final UsernameAuthService authService;

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
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes(authService),
    );
  }
}
