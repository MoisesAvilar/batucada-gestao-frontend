import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'auth_wrapper.dart';

void main() {
  runApp(
    // Envolve nosso app com o ChangeNotifierProvider
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Batucada Gestão',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}