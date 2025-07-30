// lib/features/scheduling/screens/aula_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';
import '../../dashboard/screens/dashboard_screen.dart' show AulaEvent;
import '../widgets/aula_filter_panel.dart';
import '../../dashboard/widgets/aula_card.dart';
import '../../../core/api/api_config.dart'; // <-- USA A NOSSA CONFIG CENTRAL

class AulaListScreen extends StatefulWidget {
  const AulaListScreen({super.key});

  @override
  State<AulaListScreen> createState() => _AulaListScreenState();
}

class _AulaListScreenState extends State<AulaListScreen> {
  late Future<List<AulaEvent>> _aulasFuture;
  Map<String, String> _currentFilters = {};

  @override
  void initState() {
    super.initState();
    // Inicia a busca de dados diretamente, garantindo que o FutureBuilder
    // tenha um future para trabalhar desde o início.
    _aulasFuture = _fetchAulas();
  }

  Future<List<AulaEvent>> _fetchAulas() async {
    // Garante que o contexto esteja pronto para o Provider antes de usá-lo.
    await Future.delayed(Duration.zero);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token == null) throw Exception('Usuário não autenticado.');

    // USA A CONFIGURAÇÃO CENTRALIZADA DA API
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/aulas/').replace(
      queryParameters: _currentFilters.isNotEmpty ? _currentFilters : null,
    );

    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> results = data['results'];
      final List<AulaEvent> aulas = [];
      for (var aula in results) {
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
    final selectedFilters = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AulaFilterPanel(),
    );

    if (selectedFilters != null) {
      setState(() {
        _currentFilters = selectedFilters;
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
            onPressed: _openFilterPanel,
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