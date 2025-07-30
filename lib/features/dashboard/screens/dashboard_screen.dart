import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:table_calendar/table_calendar.dart';
import '../widgets/aula_card.dart';

import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../../core/api/api_config.dart';

// Modelo simples para representar uma aula na UI
class AulaEvent {
  final String title;
  final String status;
  final int id;
  AulaEvent({required this.title, required this.status, required this.id});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Variáveis de estado
  late Future<Map<String, dynamic>> _dashboardData;
  late final ValueNotifier<List<AulaEvent>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<AulaEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    
    // Inicia as duas buscas de dados quando a tela é criada
    _dashboardData = _fetchDashboardData();
    _fetchEventsForMonth(_focusedDay);
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<AulaEvent> _getEventsForDay(DateTime day) {
    // Retorna os eventos para um determinado dia
    final key = DateTime.utc(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token == null) throw Exception('Usuário não autenticado.');

    const String baseUrl = kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
    var url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/');
    var response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) throw Exception('Falha ao buscar dados do usuário');
    
    final userData = jsonDecode(utf8.decode(response.bodyBytes));
    final userId = userData['id'];

    url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/professores/$userId/');
    response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Falha ao buscar dados do dashboard');
    }
  }

  Future<void> _fetchEventsForMonth(DateTime month) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token == null) return;

    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/aulas/?data_inicial=${firstDay.toIso8601String().substring(0, 10)}&data_final=${lastDay.toIso8601String().substring(0, 10)}'
      );
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final Map<DateTime, List<AulaEvent>> newEvents = {};

      for (var aula in data['results']) {
        final dataHora = DateTime.parse(aula['data_hora']);
        final dayKey = DateTime.utc(dataHora.year, dataHora.month, dataHora.day);
        
        final alunos = (aula['alunos'] as List).map((a) => a['nome_completo']).join(', ');
        final title = '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')} - $alunos';
        
        final aulaEvent = AulaEvent(
          id: aula['id'],
          title: title,
          status: aula['status'],
        );

        if (newEvents[dayKey] == null) newEvents[dayKey] = [];
        newEvents[dayKey]!.add(aulaEvent);
      }
      
      setState(() {
        _events = newEvents;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    } else {
      print('Falha ao buscar eventos: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
          }
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
                    ),
                    const SizedBox(height: 24),
                    TableCalendar<AulaEvent>(
                      locale: 'pt_BR', // Para deixar o calendário em português
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: _onDaySelected,
                      eventLoader: _getEventsForDay,
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _fetchEventsForMonth(focusedDay);
                      },
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.indigo,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    SizedBox(
                      height: 200,
                      child: ValueListenableBuilder<List<AulaEvent>>(
                        valueListenable: _selectedEvents,
                        builder: (context, value, _) {
                          if (value.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Sem aulas agendadas para este dia.'),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: value.length,
                            itemBuilder: (context, index) {
                              return AulaCard(event: value[index]);
                            },
                          );
                        },
                      ),
                    ),
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

// Widget customizado para os cards de KPI
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