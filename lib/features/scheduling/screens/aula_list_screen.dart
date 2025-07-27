import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../auth/services/auth_service.dart';
import '../../dashboard/screens/dashboard_screen.dart' show AulaEvent;
import '../widgets/aula_filter_panel.dart'; // Importa nosso novo painel
import '../../dashboard/widgets/aula_card.dart';

class AulaListScreen extends StatefulWidget {
  const AulaListScreen({super.key});

  @override
  State<AulaListScreen> createState() => _AulaListScreenState();
}

class _AulaListScreenState extends State<AulaListScreen> {
  Future<List<AulaEvent>>? _aulasFuture;
  // Guarda o estado atual dos filtros
  Map<String, String> _currentFilters = {};

  @override
  void initState() {
    super.initState();
    // Atrasamos a primeira chamada para garantir que o 'context' esteja pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aulasFuture = _fetchAulas();
    });
  }

  // A função agora usa os filtros guardados no estado
  Future<List<AulaEvent>> _fetchAulas() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token == null) throw Exception('Usuário não autenticado.');

    const String baseUrl = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
    // Adiciona os filtros como query parameters na URL
    final url = Uri.parse('$baseUrl/api/v1/aulas/').replace(
      queryParameters: _currentFilters,
    );

    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<AulaEvent> aulas = [];
      for (var aula in data['results']) {
        final dataHora = DateTime.parse(aula['data_hora']);
        final alunos = (aula['alunos'] as List).map((a) => a['nome_completo']).join(', ');
        final title = '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')} - $alunos';
        aulas.add(AulaEvent(id: aula['id'], title: title, status: aula['status']));
      }
      return aulas;
    } else {
      throw Exception('Falha ao carregar aulas.');
    }
  }

  void _openFilterPanel() async {
    // Mostra o painel de filtros e espera o resultado
    final selectedFilters = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true, // Permite que o painel cresça
      builder: (context) => const AulaFilterPanel(),
    );

    // Se o usuário aplicou ou limpou os filtros
    if (selectedFilters != null) {
      setState(() {
        _currentFilters = selectedFilters;
        // Dispara uma nova busca na API com os novos filtros
        _aulasFuture = _fetchAulas();
      });
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
            onPressed: _openFilterPanel, // Chama nossa função
          ),
        ],
      ),
      // FutureBuilder é perfeito, pois podemos recriá-lo facilmente
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
            padding: const EdgeInsets.all(8.0),
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