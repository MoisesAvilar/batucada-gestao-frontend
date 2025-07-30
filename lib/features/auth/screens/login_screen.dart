import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/auth_service.dart';
import '../../../core/api/api_config.dart';
import '../../../main_screeen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Função para o login manual (com usuário e senha)
  Future<void> _login() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/token/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        await authService.saveToken(data['access']);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // Futuramente, mostraremos este erro em um pop-up
        final errorData = jsonDecode(response.body);
        print('Erro no login: ${errorData['detail']}');
      }
    } catch (e) {
      print('Erro de conexão: $e');
    }
  }

  // Função para o login com Google
  Future<void> _googleLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final googleSignIn = GoogleSignIn();

    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // Usuário cancelou

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      if (accessToken == null) return;

      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/google/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'access_token': accessToken}),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        // A resposta do dj-rest-auth pode ter a chave 'key' ou 'access_token'
        // Verifique na sua API qual é a correta.
        final apiToken = data['access'];

        if (apiToken != null) {
          await authService.saveToken(apiToken);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
            print('Erro: A chave do token não foi encontrada na resposta da API.');
        }
      } else {
        print('Erro no login com Google: ${response.body}');
      }
    } catch (error) {
      print('Erro durante o login com Google: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batucada Gestão - Login'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Garante que a tela role em celulares menores
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // --- Formulário de Login Manual ---
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Usuário', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
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
                onPressed: () { /* Navegar para tela de cadastro */ },
                child: const Text('Não tem uma conta? Cadastre-se'),
              ),

              // --- Divisor "OU" ---
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('OU'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),

              // --- Botão de Login com Google ---
              ElevatedButton.icon(
                icon: const FaIcon(FontAwesomeIcons.google),
                label: const Text('Entrar com Google'),
                onPressed: _googleLogin,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}