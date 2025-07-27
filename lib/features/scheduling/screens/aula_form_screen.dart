import 'package:flutter/material.dart';
import '../widgets/aula_form_widget.dart'; // Importa nosso formulário

class AulaFormScreen extends StatelessWidget {
  // Receberá a data pré-selecionada do calendário
  final DateTime? initialDate;

  const AulaFormScreen({super.key, this.initialDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Nova Aula'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: const AulaFormWidget(), // Usa nosso widget de formulário
    );
  }
}