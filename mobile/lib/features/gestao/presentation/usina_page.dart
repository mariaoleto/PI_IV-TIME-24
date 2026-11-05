// Autora: Marina Hehnes Espósito.
// Propósito: tela de gestão da usina, cadastro de cotas e contrato.
import 'package:flutter/material.dart';

part 'usina_page_inicio.dart';
part 'usina_page_cadastro.dart';
part 'usina_page_cotas.dart';
part 'usina_page_contrato.dart';
part 'usina_page_componentes.dart';

const Color navy = Color(0xFF142542);
const Color orange = Color(0xFFF5A116);
const Color background = Color(0xFFF4F6FA);
const Color muted = Color(0xFF788397);

class UsinaPage extends StatefulWidget {
  const UsinaPage({super.key});

  @override
  State<UsinaPage> createState() => _UsinaPageState();
}

class _UsinaPageState extends _UsinaPageStateBase
    with
        _UsinaPageInicio,
        _UsinaPageCadastro,
        _UsinaPageCotas,
        _UsinaPageContrato,
        _UsinaPageComponentes {}

abstract class _UsinaPageStateBase extends State<UsinaPage> {
  int _screen = 0;
  final List<Map<String, dynamic>> _usinas = [
    {
      'nome': 'Solis SP-Norte-01',
      'potencia': '42',
      'distribuidora': 'Enel',
      'status': 'Operacional',
      'codigo': 'USIN-2024-001',
      'local': 'São Paulo, SP',
    },
    {
      'nome': 'Solis Interior-02',
      'potencia': '28',
      'distribuidora': 'CPFL',
      'status': 'Ativo',
      'codigo': 'USIN-2024-002',
      'local': 'Campinas, SP',
    },
  ];

  final List<Map<String, dynamic>> _membros = [
    {
      'nome': 'João Oliveira',
      'id': 'membro_id_mock-001',
      'iniciais': 'JO',
      'cota': 25.0,
      'status': 'Ativo',
    },
    {
      'nome': 'Maria Santos',
      'id': 'membro_id_mock-002',
      'iniciais': 'MS',
      'cota': 20.0,
      'status': 'Ativo',
    },
    {
      'nome': 'Carlos Nunes',
      'id': 'membro_id_mock-003',
      'iniciais': 'CN',
      'cota': 15.0,
      'status': 'Pendente',
    },
    {
      'nome': 'Ana Ferreira',
      'id': 'membro_id_mock-004',
      'iniciais': 'AF',
      'cota': 15.0,
      'status': 'Ativo',
    },
  ];

  final _nomeController = TextEditingController(text: 'Solis SP-Norte-01');
  final _potenciaController = TextEditingController(text: '42');
  final _contratoController = TextEditingController();
  String _distribuidora = 'Enel';
  String _documento = 'contrato-consorcio-solis.pdf';
  int? _editingIndex;

  double get _totalCotas =>
      _membros.fold(0.0, (total, membro) => total + (membro['cota'] as double));

  @override
  void dispose() {
    _nomeController.dispose();
    _potenciaController.dispose();
    _contratoController.dispose();
    super.dispose();
  }

  void _abrirCadastro({int? index}) {
    setState(() {
      _editingIndex = index;
      if (index != null) {
        final usina = _usinas[index];
        _nomeController.text = usina['nome'];
        _potenciaController.text = usina['potencia'];
        _distribuidora = usina['distribuidora'];
      } else {
        _nomeController.clear();
        _potenciaController.clear();
        _distribuidora = 'Enel';
      }
      _screen = 1;
    });
  }

  void _salvarUsina() {
    if (_nomeController.text.trim().isEmpty ||
        _potenciaController.text.trim().isEmpty) {
      _mensagem('Preencha o nome e a potência instalada.');
      return;
    }

    final usina = {
      'nome': _nomeController.text.trim(),
      'potencia': _potenciaController.text.trim(),
      'distribuidora': _distribuidora,
      'status': 'Operacional',
      'codigo': _editingIndex == null
          ? 'USIN-${DateTime.now().year}-${(_usinas.length + 1).toString().padLeft(3, '0')}'
          : _usinas[_editingIndex!]['codigo'],
      'local': 'São Paulo, SP',
    };

    setState(() {
      if (_editingIndex == null) {
        _usinas.add(usina);
      } else {
        _usinas[_editingIndex!] = usina;
      }
      _editingIndex = _editingIndex == null
          ? _usinas.length - 1
          : _editingIndex;
      _screen = 2;
    });
  }

  void _salvarCotas() {
    if (_totalCotas > 100) {
      _mensagem('A soma das cotas não pode ultrapassar 100%.');
      return;
    }
    setState(() => _screen = 3);
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _adicionarMembro() async {
    final nome = TextEditingController();
    final cota = TextEditingController(text: '0');
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar membro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nome,
              decoration: const InputDecoration(labelText: 'Nome do membro'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cota,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Percentual da cota (%)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final valor = double.tryParse(cota.text.replaceAll(',', '.'));
              if (nome.text.trim().isEmpty || valor == null || valor < 0)
                return;
              Navigator.pop(context, {
                'nome': nome.text.trim(),
                'id':
                    'membro_id_mock-${(_membros.length + 1).toString().padLeft(3, '0')}',
                'iniciais': nome.text
                    .trim()
                    .split(' ')
                    .take(2)
                    .map((e) => e[0])
                    .join()
                    .toUpperCase(),
                'cota': valor,
                'status': 'Pendente',
              });
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    nome.dispose();
    cota.dispose();
    if (resultado != null) {
      setState(() => _membros.add(resultado));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _screen,
                children: [
                  _telaInicial(),
                  _telaCadastro(),
                  _telaCotas(),
                  _telaContrato(),
                ],
              ),
            ),
            if (_screen == 0) _navegacaoInferior(),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho(String titulo, String subtitulo);
  Widget _telaInicial();
  Widget _cartaoResumo(Map<String, dynamic> usina);
  // ignore: unused_element
  Widget _dadoResumo(String titulo, String valor);
  Widget _telaCadastro();
  Widget _telaCotas();
  // ignore: unused_element
  Widget _cartaoMembro(int index);
  Widget _telaContrato();
  Widget _navegacaoInferior();
  Widget _botaoInferior(String texto, VoidCallback acao);
  Widget _cartao({required Widget child});
  Widget _icone(IconData icon, Color fundo, Color cor);
  Widget _rotulo(String texto);
  InputDecoration _decoracao({String? hint, String? sufixo});
  Widget _status(String texto);
}
