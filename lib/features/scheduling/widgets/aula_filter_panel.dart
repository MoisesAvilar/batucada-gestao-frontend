import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar datas

class AulaFilterPanel extends StatefulWidget {
  const AulaFilterPanel({super.key});

  @override
  State<AulaFilterPanel> createState() => _AulaFilterPanelState();
}

class _AulaFilterPanelState extends State<AulaFilterPanel> {
  // Controladores para os campos de data
  final _dataInicialController = TextEditingController();
  final _dataFinalController = TextEditingController();
  String? _selectedStatus;

  final List<String> _statusOptions = [
    'Agendada',
    'Realizada',
    'Cancelada',
    'Aluno Ausente'
  ];

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _applyFilters() {
    final filters = {
      'data_inicial': _dataInicialController.text,
      'data_final': _dataFinalController.text,
      'status': _selectedStatus ?? '',
    };
    // Remove chaves com valores vazios para não enviar na URL
    filters.removeWhere((key, value) => value.isEmpty);

    // Retorna os filtros para a tela anterior
    Navigator.of(context).pop(filters);
  }

  void _clearFilters() {
    Navigator.of(context).pop({}); // Retorna um mapa de filtros vazio
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Para o painel ter a altura do conteúdo
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filtrar Aulas', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),

          // Filtro de Status
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: _statusOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedStatus = newValue;
              });
            },
          ),
          const SizedBox(height: 16),

          // Filtro de Data
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dataInicialController,
                  decoration: const InputDecoration(
                    labelText: 'Data Inicial',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context, _dataInicialController),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _dataFinalController,
                  decoration: const InputDecoration(
                    labelText: 'Data Final',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context, _dataFinalController),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Aplicar Filtros'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}