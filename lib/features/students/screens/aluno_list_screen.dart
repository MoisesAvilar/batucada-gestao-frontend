import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'aluno_detail_screen.dart'; // Importa a tela de detalhes

import '../../auth/services/auth_service.dart';

// Modelo de dados para o Aluno
class Aluno {
  final int id;
  final String nomeCompleto;
  final String? email;

  Aluno({required this.id, required this.nomeCompleto, this.email});

  factory Aluno.fromJson(Map<String, dynamic> json) {
    return Aluno(
      id: json['id'],
      nomeCompleto: json['nome_completo'],
      email: json['email'],
    );
  }
}

class AlunoListScreen extends StatefulWidget {
  const AlunoListScreen({super.key});

  @override
  State<AlunoListScreen> createState() => _AlunoListScreenState();
}

class _AlunoListScreenState extends State<AlunoListScreen> {
  List<Aluno> _alunos = [];
  bool _isLoading = true;
  String? _error;
  
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchAlunos();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchAlunos(query: _searchController.text);
    });
  }

  Future<void> _fetchAlunos({String query = ''}) async {
    // A lógica de busca de dados continua a mesma, está perfeita.
    setState(() { _isLoading = true; _error = null; });

    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token == null) {
      setState(() { _error = 'Usuário não autenticado.'; _isLoading = false; });
      return;
    }

    const String baseUrl = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
    final url = Uri.parse('$baseUrl/api/v1/alunos/').replace(
      queryParameters: query.isNotEmpty ? {'search': query} : null
    );
    
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = data['results'];
        setState(() {
          _alunos = results.map((json) => Aluno.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar alunos.');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Erro: $_error'));
    }
    if (_alunos.isEmpty) {
      return const Center(child: Text('Nenhum aluno encontrado.'));
    }

    return ListView.builder(
      itemCount: _alunos.length,
      itemBuilder: (context, index) {
        final aluno = _alunos[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(aluno.nomeCompleto[0].toUpperCase()),
          ),
          title: Text(aluno.nomeCompleto),
          subtitle: Text(aluno.email ?? 'Sem e-mail'),
          // --- AQUI ESTÁ A CORREÇÃO ---
          onTap: () {
            // Em vez de só imprimir, agora navegamos para a tela de detalhes
            Navigator.of(context).push(
              MaterialPageRoute(
                // Passamos o ID do aluno clicado para a próxima tela
                builder: (context) => AlunoDetailScreen(alunoId: aluno.id),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Buscar aluno...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }
}