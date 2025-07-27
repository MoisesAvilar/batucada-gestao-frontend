// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- 1. IMPORTE

import 'auth_wrapper.dart';
import 'features/auth/services/auth_service.dart';

// 2. TRANSFORME A MAIN EM ASYNC E CHAME A FUNÇÃO
void main() async {
  // Garante que os widgets do Flutter sejam inicializados
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa os dados de formatação para o nosso idioma
  await initializeDateFormatting('pt_BR', null);

  runApp(
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