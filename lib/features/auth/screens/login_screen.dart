import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    const String baseUrl = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
    final url = Uri.parse('$baseUrl/api/v1/users/token/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access'];

        await authService.saveToken(token);

        // A navegação só acontece em um contexto válido, o que é garantido aqui.
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else { // <-- BLOCO ELSE RESTAURADO
        // Se a API retornou um erro (ex: senha incorreta)
        final errorData = jsonDecode(response.body);
        print('Erro no login: ${response.statusCode}');
        print('Detalhe: ${errorData['detail']}');
        // AQUI, NO FUTURO, VAMOS MOSTRAR UM ALERTA DE ERRO PARA O USUÁRIO
      }
    } catch (e) { // <-- BLOCO CATCH CORRIGIDO
      // Se houve um erro de rede (ex: API desligada)
      print('Erro de conexão: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // A UI (build) continua a mesma
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batucada Gestão - Login'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuário',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Entrar'),
            ),
            const SizedBox(height: 16.0),
            TextButton(
              onPressed: () {},
              child: const Text('Não tem uma conta? Cadastre-se'),
            ),
          ],
        ),
      ),
    );
  }
}