import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 'late' significa que vamos inicializar esta variável mais tarde
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    // Assim que a tela é construída, chamamos a função para buscar os dados
    _dashboardData = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();

    // Primeiro, buscamos os dados do usuário logado
    const String baseUrl = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
    var url = Uri.parse('$baseUrl/api/v1/users/me/');
    var response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao buscar dados do usuário');
    }
    
    final userData = jsonDecode(utf8.decode(response.bodyBytes));
    final userId = userData['id'];

    // Agora, buscamos os dados do dashboard do professor
    url = Uri.parse('$baseUrl/api/v1/users/professores/$userId/');
    response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // utf8.decode é importante para lidar com acentos
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Falha ao buscar dados do dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      // FutureBuilder constrói a UI com base no resultado da nossa chamada de API
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          // Cenário 1: Enquanto está carregando...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Cenário 2: Se deu erro...
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
          }

          // Cenário 3: Se os dados chegaram com sucesso!
          if (snapshot.hasData) {
            final data = snapshot.data!;
            final kpis = data['kpis'];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bem-vindo, ${data['first_name']}!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      // IMPORANTE: Adicione isso para o GridView não brigar com o SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(), 
                      children: [
                        KpiCard(
                          title: 'Aulas Realizadas',
                          value: kpis['total_realizadas'].toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        KpiCard(
                          title: 'Aulas Agendadas',
                          value: kpis['total_agendadas'].toString(),
                          icon: Icons.calendar_today,
                          color: Colors.blue,
                        ),
                        KpiCard(
                          title: 'Substituições Feitas',
                          value: kpis['total_substituicoes_feitas'].toString(),
                          icon: Icons.person_add,
                          color: Colors.orange,
                        ),
                         KpiCard(
                          title: 'Substituições Sofridas',
                          value: kpis['total_substituicoes_sofridas'].toString(),
                          icon: Icons.person_remove,
                          color: Colors.red,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('Nenhum dado encontrado.'));
        },
      ),
    );
  }
}

// Widget customizado para os cards de KPI, para reutilizar o código
class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}