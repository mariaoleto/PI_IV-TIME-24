// Autora: Marina Hehnes Espósito.
// Propósito: tela de gestão da usina, cadastro de cotas e contrato.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../geracao_creditos/domain/repositorio_energia.dart';
import '../../painel_admin/domain/repositorio_painel_admin.dart';
import '../../painel_admin/presentation/barra_navegacao_admin.dart';
import '../../perfil/domain/repositorio_perfil.dart';
import '../data/modelos_usina.dart';
import '../data/repositorio_usina.dart';

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
  const UsinaPage({
    super.key,
    this.repositorio,
    this.telaInicial = 0,
    this.usinaIdInicial,
    this.nomeAdmin,
    this.repositorioPainel,
    this.repositorioEnergia,
    this.repositorioPerfil,
    this.aoSincronizarPainel,
  });

  final RepositorioUsina? repositorio;
  final int telaInicial;
  final String? usinaIdInicial;
  final String? nomeAdmin;
  final RepositorioPainelAdmin? repositorioPainel;
  final RepositorioEnergia? repositorioEnergia;
  final RepositorioPerfil? repositorioPerfil;
  final ValueChanged<String?>? aoSincronizarPainel;

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
  late int _screen;
  bool _carregando = false;
  bool _salvando = false;
  String? _erroCarregamento;
  String? _usinaSelecionadaId;
  ContratoUsina? _contratoAtual;

  final List<Map<String, dynamic>> _usinas = [];
  final List<Map<String, dynamic>> _membros = [];

  final _nomeController = TextEditingController();
  final _potenciaController = TextEditingController();
  final _localController = TextEditingController();
  String _distribuidora = 'Enel';
  String _documento = 'Nenhum contrato enviado';
  int? _editingIndex;

  bool get _usaApi => widget.repositorio != null;

  double get _totalCotas =>
      _membros.fold(0.0, (total, membro) => total + (membro['cota'] as double));

  @override
  void initState() {
    super.initState();
    _screen = widget.telaInicial.clamp(0, 3);
    if (_usaApi) {
      _carregarDadosReais(preencherCadastroInicial: _screen == 1);
    } else {
      _carregarDadosDemonstracao();
    }
  }

  void _carregarDadosDemonstracao() {
    _usinas.addAll([
      {
        'id': 'usina-demo-1',
        'nome': 'Solis SP-Norte-01',
        'potencia': '42',
        'distribuidora': 'Enel',
        'status': 'Operacional',
        'codigo': 'USIN-2024-001',
        'local': 'São Paulo, SP',
      },
      {
        'id': 'usina-demo-2',
        'nome': 'Solis Interior-02',
        'potencia': '28',
        'distribuidora': 'CPFL',
        'status': 'Ativo',
        'codigo': 'USIN-2024-002',
        'local': 'Campinas, SP',
      },
    ]);
    _membros.addAll([
      {
        'nome': 'João Oliveira',
        'id': 'membro_id_mock-001',
        'email': 'joao@solis.app',
        'iniciais': 'JO',
        'cota': 25.0,
        'status': 'Ativo',
      },
      {
        'nome': 'Maria Santos',
        'id': 'membro_id_mock-002',
        'email': 'maria@solis.app',
        'iniciais': 'MS',
        'cota': 20.0,
        'status': 'Ativo',
      },
      {
        'nome': 'Carlos Nunes',
        'id': 'membro_id_mock-003',
        'email': 'carlos@solis.app',
        'iniciais': 'CN',
        'cota': 15.0,
        'status': 'Pendente',
      },
      {
        'nome': 'Ana Ferreira',
        'id': 'membro_id_mock-004',
        'email': 'ana@solis.app',
        'iniciais': 'AF',
        'cota': 15.0,
        'status': 'Ativo',
      },
    ]);
    _usinaSelecionadaId = 'usina-demo-1';
    _nomeController.text = 'Solis SP-Norte-01';
    _potenciaController.text = '42';
    _localController.text = 'São Paulo, SP';
    _documento = 'contrato-consorcio-solis.pdf';
  }

  Map<String, dynamic> _mapearUsina(Usina u) {
    final potencia = u.potencia % 1 == 0
        ? u.potencia.toStringAsFixed(0)
        : u.potencia.toString();
    return {
      'id': u.id,
      'nome': u.nome,
      'potencia': potencia,
      'distribuidora': u.distribuidora,
      'status': 'Operacional',
      'codigo': u.codigo,
      'local': (u.local != null && u.local!.trim().isNotEmpty)
          ? u.local!
          : 'Não informado',
    };
  }

  Map<String, dynamic> _mapearMembro(MembroUsina m) {
    final partes = m.nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2);
    final iniciais = partes.map((p) => p[0]).join().toUpperCase();
    return {
      'id': m.id,
      'nome': m.nome,
      'email': m.email,
      'iniciais': iniciais.isEmpty ? '?' : iniciais,
      'cota': m.cota,
      'status': m.status,
    };
  }

  Future<void> _carregarDadosReais({
    bool preencherCadastroInicial = false,
  }) async {
    final repo = widget.repositorio;
    if (repo == null) return;

    setState(() {
      _carregando = true;
      _erroCarregamento = null;
    });

    try {
      final usinas = await repo.listar();
      if (!mounted) return;

      final listaMapeada = usinas.map(_mapearUsina).toList();
      String? idSelecionada = _usinaSelecionadaId ?? widget.usinaIdInicial;
      if (idSelecionada == null ||
          !listaMapeada.any((u) => u['id'] == idSelecionada)) {
        idSelecionada = listaMapeada.isNotEmpty
            ? listaMapeada.first['id'] as String
            : null;
      }

      List<MembroUsina> membrosApi = const [];
      ContratoUsina? contratoApi;
      if (idSelecionada != null) {
        final resultados = await Future.wait([
          repo.listarMembros(idSelecionada),
          repo.buscarContrato(idSelecionada),
        ]);
        if (!mounted) return;
        membrosApi = resultados[0] as List<MembroUsina>;
        contratoApi = resultados[1] as ContratoUsina?;
      }

      setState(() {
        _usinas
          ..clear()
          ..addAll(listaMapeada);
        _usinaSelecionadaId = idSelecionada;
        _membros
          ..clear()
          ..addAll(membrosApi.map(_mapearMembro));
        _contratoAtual = contratoApi;
        _documento = contratoApi?.nomeArquivo ?? 'Nenhum contrato enviado';
        _carregando = false;

        if (preencherCadastroInicial) {
          if (_usinas.isNotEmpty && idSelecionada != null) {
            final idx = _usinas.indexWhere((u) => u['id'] == idSelecionada);
            if (idx >= 0) {
              _preencherFormulario(idx);
            }
          } else {
            _limparFormulario();
          }
        }
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erroCarregamento = erro.toString();
      });
    }
  }

  Future<void> _selecionarUsina(String? usinaId) async {
    if (usinaId == null || usinaId == _usinaSelecionadaId) return;
    setState(() => _usinaSelecionadaId = usinaId);
    final repo = widget.repositorio;
    if (repo == null) return;

    try {
      final resultados = await Future.wait([
        repo.listarMembros(usinaId),
        repo.buscarContrato(usinaId),
      ]);
      if (!mounted) return;
      final membrosApi = resultados[0] as List<MembroUsina>;
      final contratoApi = resultados[1] as ContratoUsina?;
      setState(() {
        _membros
          ..clear()
          ..addAll(membrosApi.map(_mapearMembro));
        _contratoAtual = contratoApi;
        _documento = contratoApi?.nomeArquivo ?? 'Nenhum contrato enviado';
      });
    } catch (erro) {
      if (mounted) _mensagem(erro.toString());
    }
  }

  void _preencherFormulario(int index) {
    final usina = _usinas[index];
    _editingIndex = index;
    _nomeController.text = usina['nome'] as String;
    _potenciaController.text = usina['potencia'] as String;
    _localController.text =
        usina['local'] == 'Não informado' ? '' : (usina['local'] as String);
    _distribuidora = usina['distribuidora'] as String;
  }

  void _limparFormulario() {
    _editingIndex = null;
    _nomeController.clear();
    _potenciaController.clear();
    _localController.clear();
    _distribuidora = 'Enel';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _potenciaController.dispose();
    _localController.dispose();
    super.dispose();
  }

  void _abrirCadastro({int? index}) {
    setState(() {
      if (index != null) {
        _preencherFormulario(index);
      } else {
        _limparFormulario();
      }
      _screen = 1;
    });
  }

  Future<void> _abrirCotas() async {
    setState(() => _screen = 2);
    if (_usaApi && _usinaSelecionadaId != null) {
      await _carregarDadosReais();
    }
  }

  Future<void> _abrirContrato() async {
    setState(() => _screen = 3);
    if (_usaApi && _usinaSelecionadaId != null) {
      await _carregarDadosReais();
    }
  }

  Future<void> _salvarUsina() async {
    final nome = _nomeController.text.trim();
    final potenciaTexto = _potenciaController.text.trim().replaceAll(',', '.');
    final potenciaVal = double.tryParse(potenciaTexto);
    if (nome.isEmpty || potenciaVal == null || potenciaVal <= 0) {
      _mensagem('Preencha o nome e uma potência instalada válida.');
      return;
    }

    final localTexto = _localController.text.trim();
    final repo = widget.repositorio;

    if (repo == null) {
      final usina = {
        'id': _editingIndex == null
            ? 'usina-demo-${_usinas.length + 1}'
            : _usinas[_editingIndex!]['id'],
        'nome': nome,
        'potencia': _potenciaController.text.trim(),
        'distribuidora': _distribuidora,
        'status': 'Operacional',
        'codigo': _editingIndex == null
            ? 'USIN-${DateTime.now().year}-${(_usinas.length + 1).toString().padLeft(3, '0')}'
            : _usinas[_editingIndex!]['codigo'],
        'local': localTexto.isEmpty ? 'São Paulo, SP' : localTexto,
      };
      setState(() {
        if (_editingIndex == null) {
          _usinas.add(usina);
          _editingIndex = _usinas.length - 1;
        } else {
          _usinas[_editingIndex!] = usina;
        }
        _screen = 2;
      });
      return;
    }

    setState(() => _salvando = true);
    try {
      final emEdicao = _editingIndex != null ? _usinas[_editingIndex!] : null;
      final entrada = Usina(
        id: emEdicao?['id'] as String? ?? '',
        nome: nome,
        potencia: potenciaVal,
        distribuidora: _distribuidora,
        codigo: emEdicao?['codigo'] as String? ?? '',
        local: localTexto.isEmpty ? null : localTexto,
      );

      final salva = emEdicao != null
          ? await repo.atualizar(entrada)
          : await repo.criar(entrada);
      if (!mounted) return;

      _usinaSelecionadaId = salva.id;
      await _carregarDadosReais();
      if (!mounted) return;

      widget.aoSincronizarPainel?.call(salva.id);
      setState(() {
        _salvando = false;
        _editingIndex = _usinas.indexWhere((u) => u['id'] == salva.id);
        _screen = 2;
      });
      _mensagem('Usina salva com sucesso.');
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _mensagem(erro.toString());
    }
  }

  Future<void> _excluirUsina(int index) async {
    final repo = widget.repositorio;
    if (repo == null) {
      setState(() => _usinas.removeAt(index));
      return;
    }

    final id = _usinas[index]['id'] as String;
    setState(() => _salvando = true);
    try {
      await repo.excluir(id);
      if (!mounted) return;
      if (_usinaSelecionadaId == id) {
        _usinaSelecionadaId = null;
      }
      if (_editingIndex == index) {
        _limparFormulario();
      }
      await _carregarDadosReais();
      if (!mounted) return;
      widget.aoSincronizarPainel?.call(_usinaSelecionadaId);
      setState(() => _salvando = false);
      _mensagem('Usina excluída com sucesso.');
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _mensagem(erro.toString());
    }
  }

  Future<void> _salvarCotas() async {
    if (_totalCotas > 100.001) {
      _mensagem('A soma das cotas não pode ultrapassar 100%.');
      return;
    }

    final repo = widget.repositorio;
    if (repo == null) {
      setState(() => _screen = 3);
      return;
    }

    final usinaId = _usinaSelecionadaId;
    if (usinaId == null || usinaId.isEmpty) {
      _mensagem('Cadastre ou selecione uma usina antes de salvar as cotas.');
      return;
    }

    setState(() => _salvando = true);
    try {
      final atualizados = await repo.atualizarCotas(
        usinaId,
        _membros
            .map(
              (m) => CotaAtualizacao(
                membroId: m['id'] as String,
                percentual: (m['cota'] as num).toDouble(),
              ),
            )
            .toList(),
      );
      if (!mounted) return;
      setState(() {
        _membros
          ..clear()
          ..addAll(atualizados.map(_mapearMembro));
        _salvando = false;
        if (widget.telaInicial != 2) {
          _screen = 3;
        }
      });
      widget.aoSincronizarPainel?.call(usinaId);
      _mensagem(
        widget.telaInicial == 2
            ? 'Cotas atualizadas com sucesso.'
            : 'Cotas salvas com sucesso.',
      );
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _mensagem(erro.toString());
    }
  }

  Future<void> _substituirContrato() async {
    final nomeController = TextEditingController(
      text: _contratoAtual?.nomeArquivo ?? 'contrato-consorcio-solis.pdf',
    );
    final nomeEscolhido = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar contrato da usina'),
        content: TextField(
          controller: nomeController,
          decoration: const InputDecoration(
            labelText: 'Nome do arquivo PDF',
            hintText: 'Ex.: contrato-consorcio-2026.pdf',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final limpo = nomeController.text.trim();
              if (limpo.isEmpty) return;
              Navigator.pop(
                context,
                limpo.toLowerCase().endsWith('.pdf') ? limpo : '$limpo.pdf',
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    nomeController.dispose();

    if (nomeEscolhido == null) return;

    final repo = widget.repositorio;
    if (repo == null) {
      setState(() => _documento = nomeEscolhido);
      _mensagem('Documento atualizado (demonstração).');
      return;
    }

    final usinaId = _usinaSelecionadaId;
    if (usinaId == null || usinaId.isEmpty) {
      _mensagem('Selecione uma usina antes de enviar o contrato.');
      return;
    }

    setState(() => _salvando = true);
    try {
      final bytesPdf = Uint8List.fromList(
        utf8.encode('%PDF-1.4\n% Contrato Solis: $nomeEscolhido\n%%EOF\n'),
      );
      final salvo = await repo.salvarContrato(usinaId, nomeEscolhido, bytesPdf);
      if (!mounted) return;
      setState(() {
        _contratoAtual = salvo;
        _documento = salvo.nomeArquivo;
        _salvando = false;
      });
      _mensagem('Contrato enviado com sucesso.');
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _mensagem(erro.toString());
    }
  }

  Future<void> _removerContrato() async {
    final repo = widget.repositorio;
    if (repo == null) {
      setState(() => _documento = 'Nenhum documento selecionado');
      return;
    }
    final usinaId = _usinaSelecionadaId;
    if (usinaId == null || _contratoAtual == null) return;

    setState(() => _salvando = true);
    try {
      await repo.excluirContrato(usinaId);
      if (!mounted) return;
      setState(() {
        _contratoAtual = null;
        _documento = 'Nenhum contrato enviado';
        _salvando = false;
      });
      _mensagem('Contrato removido com sucesso.');
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _mensagem(erro.toString());
    }
  }

  Future<void> _concluirContrato() async {
    if (_usaApi && _contratoAtual == null && _usinaSelecionadaId != null) {
      await _substituirContrato();
      if (!mounted || _contratoAtual == null) return;
    }
    setState(() => _screen = 0);
    _mensagem('Contrato salvo com sucesso.');
  }

  void _mensagem(String texto) {
    final margemInferior = (_screen >= 1 && _screen <= 3) ? 76.0 : 12.0;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, margemInferior),
        ),
      );
  }

  Future<void> _adicionarMembro() async {
    final repo = widget.repositorio;
    if (repo != null && (_usinaSelecionadaId == null || _usinaSelecionadaId!.isEmpty)) {
      _mensagem('Cadastre uma usina antes de vincular membros.');
      return;
    }

    final nome = TextEditingController();
    final email = TextEditingController();
    final cota = TextEditingController(text: '0');
    String? erroDialog;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, atualizarDialog) => AlertDialog(
          title: const Text('Adicionar membro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nome,
                  decoration: const InputDecoration(labelText: 'Nome do membro'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail do membro',
                  ),
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
                if (erroDialog != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    erroDialog!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nomeTxt = nome.text.trim();
                final emailTxt = email.text.trim();
                final valor =
                    double.tryParse(cota.text.replaceAll(',', '.')) ?? -1;

                if (nomeTxt.length < 2) {
                  atualizarDialog(() => erroDialog = 'Informe o nome completo.');
                  return;
                }
                if (repo != null &&
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(emailTxt)) {
                  atualizarDialog(() => erroDialog = 'Informe um e-mail válido.');
                  return;
                }
                if (valor < 0 || valor > 100) {
                  atualizarDialog(
                    () => erroDialog = 'A cota deve estar entre 0% e 100%.',
                  );
                  return;
                }

                Navigator.pop(context, {
                  'nome': nomeTxt,
                  'email': emailTxt,
                  'cota': valor,
                });
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
    nome.dispose();
    email.dispose();
    cota.dispose();

    if (resultado == null) return;

    final nomeNovo = resultado['nome'] as String;
    final emailNovo = resultado['email'] as String;
    final cotaNova = resultado['cota'] as double;

    if (repo == null) {
      final partes = nomeNovo.split(' ').where((e) => e.isNotEmpty).take(2);
      setState(() {
        _membros.add({
          'nome': nomeNovo,
          'email': emailNovo,
          'id':
              'membro_id_mock-${(_membros.length + 1).toString().padLeft(3, '0')}',
          'iniciais': partes.map((e) => e[0]).join().toUpperCase(),
          'cota': cotaNova,
          'status': cotaNova > 0 ? 'Ativo' : 'Pendente',
        });
      });
      return;
    }

    setState(() => _salvando = true);
    try {
      final usinaId = _usinaSelecionadaId!;
      final adicionado = await repo.adicionarMembro(
        usinaId: usinaId,
        nome: nomeNovo,
        email: emailNovo,
      );
      if (!mounted) return;

      await _carregarDadosReais();
      if (!mounted) return;

      if (cotaNova > 0 && (_totalCotas + cotaNova) <= 100.001) {
        final cotasAtualizar = _membros
            .map(
              (m) => CotaAtualizacao(
                membroId: m['id'] as String,
                percentual: m['id'] == adicionado.id
                    ? cotaNova
                    : (m['cota'] as num).toDouble(),
              ),
            )
            .toList();
        final atualizados = await repo.atualizarCotas(usinaId, cotasAtualizar);
        if (!mounted) return;
        setState(() {
          _membros
            ..clear()
            ..addAll(atualizados.map(_mapearMembro));
        });
      }

      widget.aoSincronizarPainel?.call(usinaId);
      setState(() => _salvando = false);
      _mensagem('Membro vinculado à usina.');
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _mensagem(erro.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<String>(
      onPopInvokedWithResult: (didPop, resultado) {
        if (didPop) {
          widget.aoSincronizarPainel?.call(resultado ?? _usinaSelecionadaId);
        }
      },
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          bottom: _screen != 0 && _screen != 2,
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
        bottomNavigationBar:
            (_screen == 0 || _screen == 2) ? _navegacaoInferior() : null,
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
