import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../auth/services/auth_service.dart';
// Importando os widgets que vamos reutilizar
import '../../dashboard/screens/dashboard_screen.dart' show AulaEvent;
import '../../dashboard/widgets/aula_card.dart';

class AulaListScreen extends StatefulWidget {
  const AulaListScreen({super.key});

  @override
  State<AulaListScreen> createState() => _AulaListScreenState();
}

class _AulaListScreenState extends State<AulaListScreen> {
  late Future<List<AulaEvent>> _aulasFuture;

  @override
  void initState() {
    super.initState();
    _aulasFuture = _fetchAulas();
  }

  Future<List<AulaEvent>> _fetchAulas() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token == null) throw Exception('Usuário não autenticado.');

    const String baseUrl = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
    final url = Uri.parse('$baseUrl/api/v1/aulas/');

    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<AulaEvent> aulas = [];
      for (var aula in data['results']) {
        final dataHora = DateTime.parse(aula['data_hora']);
        final alunos = (aula['alunos'] as List).map((a) => a['nome_completo']).join(', ');
        final title = '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')} - $alunos';

        aulas.add(AulaEvent(
          id: aula['id'],
          title: title,
          status: aula['status'],
        ));
      }
      return aulas;
    } else {
      throw Exception('Falha ao carregar aulas.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Aulas'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // AQUI VAMOS ABRIR O PAINEL DE FILTROS NO FUTURO
              print('Abrir filtros');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<AulaEvent>>(
        future: _aulasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma aula encontrada.'));
          }

          final aulas = snapshot.data!;
          return ListView.builder(
            itemCount: aulas.length,
            itemBuilder: (context, index) {
              return AulaCard(event: aulas[index]);
            },
          );
        },
      ),
    );
  }
}