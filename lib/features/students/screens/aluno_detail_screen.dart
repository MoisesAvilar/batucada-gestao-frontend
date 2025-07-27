import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../auth/services/auth_service.dart';
import '../../dashboard/widgets/kpi_card.dart'; // Importa nosso novo KpiCard!

class AlunoDetailScreen extends StatefulWidget {
  final int alunoId;

  const AlunoDetailScreen({super.key, required this.alunoId});

  @override
  State<AlunoDetailScreen> createState() => _AlunoDetailScreenState();
}

class _AlunoDetailScreenState extends State<AlunoDetailScreen> {
  late Future<Map<String, dynamic>> _alunoDetailsFuture;

  @override
  void initState() {
    super.initState();
    _alunoDetailsFuture = _fetchAlunoDetails();
  }

  Future<Map<String, dynamic>> _fetchAlunoDetails() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token == null) throw Exception('Usuário não autenticado.');

    const String baseUrl = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
    final url = Uri.parse('$baseUrl/api/v1/alunos/${widget.alunoId}/');

    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Falha ao carregar detalhes do aluno.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Aluno'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _alunoDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Nenhum dado encontrado.'));
          }

          final alunoData = snapshot.data!;
          final kpis = alunoData['kpis'];
          final taxaPresenca = alunoData['taxa_presenca'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alunoData['nome_completo'],
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  alunoData['email'] ?? 'Sem e-mail',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 24),
                
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            '$taxaPresenca%',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Taxa de Presença'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    KpiCard(
                      title: 'Aulas Realizadas',
                      value: kpis['total_realizadas'].toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    KpiCard(
                      title: 'Ausências',
                      value: kpis['total_ausencias'].toString(),
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                    KpiCard(
                      title: 'Aulas Agendadas',
                      value: kpis['total_agendadas'].toString(),
                      icon: Icons.calendar_today,
                      color: Colors.blue,
                    ),
                    KpiCard(
                      title: 'Aulas Canceladas',
                      value: kpis['total_canceladas'].toString(),
                      icon: Icons.block,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
