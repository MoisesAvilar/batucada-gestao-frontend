import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:multi_dropdown/multiselect_dropdown.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/api/api_config.dart';

// Modelos de dados simples para os nossos dropdowns
class Modalidade {
  final int id;
  final String nome;
  Modalidade({required this.id, required this.nome});
}

class Selecionavel { // Classe genérica para Alunos e Professores
  final int id;
  final String nome;
  Selecionavel({required this.id, required this.nome});
}

class AulaFormWidget extends StatefulWidget {
  final DateTime? initialDate;
  const AulaFormWidget({super.key, this.initialDate});

  @override
  State<AulaFormWidget> createState() => _AulaFormWidgetState();
}

class _AulaFormWidgetState extends State<AulaFormWidget> {
  final _formKey = GlobalKey<FormState>();

  // Estado para os dados do formulário
  bool _isSaving = false; // Controla o estado de "salvando"

  bool _isLoading = true;
  String? _error;
  List<Modalidade> _modalidades = [];
  List<Selecionavel> _alunos = [];
  List<Selecionavel> _professores = [];
  int? _selectedModalidadeId;
  final MultiSelectController<int> _alunosController = MultiSelectController();
  final MultiSelectController<int> _professoresController = MultiSelectController();
  final _dataHoraController = TextEditingController();
  bool _isRecorrente = false;

  @override
  void initState() {
    super.initState();
    _fetchFormData();
    if (widget.initialDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(widget.initialDate!);
      _dataHoraController.text = formattedDate;
    }
  }

  Future<void> _fetchFormData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token == null) {
      setState(() { _error = 'Não autenticado'; _isLoading = false; });
      return;
    }

    try {
      final fetchedModalidades = await _fetchGenericList('modalidades', token, (json) => Modalidade(id: json['id'], nome: json['nome']));
      final fetchedAlunos = await _fetchGenericList('alunos', token, (json) => Selecionavel(id: json['id'], nome: json['nome_completo']));
      final fetchedProfessores = await _fetchGenericList('users/professores', token, (json) => Selecionavel(id: json['id'], nome: json['username']));

      setState(() {
        _modalidades = fetchedModalidades;
        _alunos = fetchedAlunos;
        _professores = fetchedProfessores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<List<T>> _fetchGenericList<T>(String path, String token, T Function(Map<String, dynamic>) fromJson) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/$path/?page_size=100');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return (data['results'] as List).map((item) => fromJson(item)).toList();
    } else {
      throw Exception('Falha ao carregar $path');
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final fullDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );
        setState(() {
          _dataHoraController.text = DateFormat('yyyy-MM-dd HH:mm').format(fullDateTime);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Inicia o estado de "salvando"
    setState(() { _isSaving = true; });

    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/aulas/');

    final payload = {
      'modalidade_id': _selectedModalidadeId,
      'data_hora': DateFormat('yyyy-MM-dd HH:mm').parse(_dataHoraController.text).toIso8601String(),
      'status': 'Agendada',
      'aluno_ids': _alunosController.selectedOptions.map((v) => v.value).toList(),
      'professor_ids': _professoresController.selectedOptions.map((v) => v.value).toList(),
      'recorrente_mensal': _isRecorrente,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(payload),
      );

      if (!mounted) return; // Garante que a tela ainda existe

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aula(s) agendada(s) com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Volta para a tela anterior
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['errors']?.join(', ') ?? 'Erro desconhecido.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao agendar: $errorMessage'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e'), backgroundColor: Colors.red),
      );
    } finally {
      // 2. Finaliza o estado de "salvando", não importa se deu certo ou erro
      setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Erro ao carregar dados: $_error'));
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedModalidadeId,
              items: _modalidades.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nome))).toList(),
              onChanged: (value) => setState(() => _selectedModalidadeId = value),
              decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
              validator: (v) => v == null ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dataHoraController,
              decoration: const InputDecoration(labelText: 'Data e Horário', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
              readOnly: true,
              onTap: _selectDateTime,
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            
            MultiSelectDropDown(
              controller: _alunosController,
              onOptionSelected: (options) {},
              options: _alunos.map((a) => ValueItem(label: a.nome, value: a.id)).toList(),
              selectionType: SelectionType.multi,
              chipConfig: const ChipConfig(wrapType: WrapType.wrap),
              dropdownHeight: 300,
              optionTextStyle: const TextStyle(fontSize: 16),
              selectedOptionIcon: const Icon(Icons.check_circle),
              hint: 'Selecione os Alunos',
            ),
            const SizedBox(height: 16),
            
            MultiSelectDropDown(
              controller: _professoresController,
              onOptionSelected: (options) {},
              options: _professores.map((p) => ValueItem(label: p.nome, value: p.id)).toList(),
              selectionType: SelectionType.multi,
              chipConfig: const ChipConfig(wrapType: WrapType.wrap),
              dropdownHeight: 300,
              optionTextStyle: const TextStyle(fontSize: 16),
              selectedOptionIcon: const Icon(Icons.check_circle),
              hint: 'Selecione os Professores',
            ),
            const SizedBox(height: 24),

            // O checkbox de recorrência ainda não tem lógica na API, mas a UI está aqui
            CheckboxListTile(
              title: const Text('Agendar recorrentemente no mês'),
              value: _isRecorrente,
              onChanged: (newValue) => setState(() => _isRecorrente = newValue ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              // Se estiver salvando, onPressed é null (desabilitado), senão chama _submitForm
              onPressed: _isSaving ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              // Se estiver salvando, mostra um indicador de progresso, senão mostra o texto
              child: _isSaving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Text('Salvar Agendamento'),
            ),
          ],
        ),
      ),
    );
  }
}