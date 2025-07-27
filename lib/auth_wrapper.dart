import 'package:batucada_gestao_frontend/main_screeen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // FutureBuilder espera o resultado de uma operação assíncrona (como ler o token)
    return FutureBuilder(
      future: authService.getToken(),
      builder: (context, snapshot) {
        // Enquanto espera, mostra uma tela de carregamento
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Se o snapshot tem um token (não é nulo), mostra o Dashboard
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }

        // Caso contrário, mostra a tela de Login
        return const LoginPage();
      },
    );
  }
}