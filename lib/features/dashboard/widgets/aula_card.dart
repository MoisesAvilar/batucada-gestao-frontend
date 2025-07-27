import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart'; // Importa a classe AulaEvent

class AulaCard extends StatelessWidget {
  final AulaEvent event;

  const AulaCard({super.key, required this.event});

  // Função para decidir a cor do card com base no status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Realizada':
        return Colors.green.shade100;
      case 'Cancelada':
        return Colors.red.shade100;
      case 'Aluno Ausente':
        return Colors.orange.shade100;
      case 'Agendada':
      default:
        return Colors.blue.shade100;
    }
  }

  // Função para decidir a cor do texto com base no status
  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Realizada':
        return Colors.green.shade800;
      case 'Cancelada':
        return Colors.red.shade800;
      case 'Aluno Ausente':
        return Colors.orange.shade800;
      case 'Agendada':
      default:
        return Colors.blue.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      color: _getStatusColor(event.status), // Cor de fundo dinâmica
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        title: Text(
          event.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getStatusTextColor(event.status),
          ),
        ),
        trailing: Chip(
          label: Text(
            event.status,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          side: BorderSide(color: _getStatusTextColor(event.status)),
        ),
        onTap: () {
          // No futuro, isso pode navegar para a tela de detalhes da aula
          print('Clicou na aula ID: ${event.id}');
        },
      ),
    );
  }
}