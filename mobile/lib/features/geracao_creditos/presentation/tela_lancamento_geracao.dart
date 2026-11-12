// autora: Maria Júlia Lazarini Oleto
// RA: 25006031

// significado do arquivo: tela do registro de geração (admin)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/repositorio_energia.dart';
import '../../gestao/data/modelos_usina.dart';
import '../../gestao/data/repositorio_usina.dart';
import '../../gestao/presentation/usina_page.dart';
import '../../painel_admin/domain/repositorio_painel_admin.dart';
import '../../painel_admin/presentation/barra_navegacao_admin.dart';
import '../../perfil/domain/repositorio_perfil.dart';

class TelaLancamentoGeracao extends StatefulWidget {
  const TelaLancamentoGeracao({
    super.key,
    required this.repositorio,
    this.usinaId,
    this.nomeAdmin,
    this.repositorioPainel,
    this.repositorioUsina,
    this.repositorioPerfil,
    this.aoSincronizarPainel,
  });

  final RepositorioEnergia repositorio;
  final String? usinaId;
  final String? nomeAdmin;
  final RepositorioPainelAdmin? repositorioPainel;
  final RepositorioUsina? repositorioUsina;
  final RepositorioPerfil? repositorioPerfil;
  final ValueChanged<String?>? aoSincronizarPainel;

  @override
  State<TelaLancamentoGeracao> createState() => _EstadoTelaLancamentoGeracao();
}

class _EstadoTelaLancamentoGeracao extends State<TelaLancamentoGeracao> {
  late final TextEditingController _geracaoController;
  DateTime _periodoSelecionado = DateTime(2026, 10); // Outubro de 2026

  List<Usina> _usinas = const [];
  String? _usinaSelecionadaId;
  List<CotaMembro> _cotas = const [];
  bool _carregandoCotas = true;
  bool _erroCarregamentoCotas = false;
  bool _salvando = false;
  bool _mostrarSucesso = false;
  String? _mensagemErro;

  bool get _deveListarUsinas =>
      widget.repositorioUsina != null ||
      widget.repositorio is RepositorioApiEnergia;

  static const List<String> _nomesMeses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _usinaSelecionadaId = widget.usinaId;
    _geracaoController = TextEditingController();
    _geracaoController.addListener(() => setState(() {}));
    _inicializar();
  }

  @override
  void dispose() {
    _geracaoController.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    if (_deveListarUsinas) {
      try {
        final usinas = await (widget.repositorioUsina ?? RepositorioApiUsina())
            .listar();
        if (!mounted) return;
        setState(() {
          _usinas = usinas;
          if (usinas.isNotEmpty &&
              (_usinaSelecionadaId == null ||
                  !usinas.any((u) => u.id == _usinaSelecionadaId))) {
            _usinaSelecionadaId = usinas.first.id;
          }
        });
      } catch (_) {
        // segue para buscar as cotas com o usinaId já selecionado
      }
    }
    await _carregarCotas();
  }

  // busca a lista de cotas reais da usina no backend
  Future<void> _carregarCotas() async {
    setState(() {
      _carregandoCotas = true;
      _erroCarregamentoCotas = false;
      _mensagemErro = null;
    });

    try {
      final cotas = await widget.repositorio.buscarCotasDistribuicao(
        usinaId: _usinaSelecionadaId,
      );

      if (!mounted) return;
      setState(() {
        _cotas = cotas;
        _erroCarregamentoCotas = false;
        _carregandoCotas = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cotas = const [];
        _erroCarregamentoCotas = true;
        _carregandoCotas = false;
        _mensagemErro = 'Não foi possível carregar as cotas desta usina.';
      });
    }
  }

  void _selecionarUsina(String? novoId) {
    if (novoId == null || novoId.isEmpty || novoId == _usinaSelecionadaId) {
      return;
    }
    setState(() {
      _usinaSelecionadaId = novoId;
      _mostrarSucesso = false;
    });
    _carregarCotas();
  }

  Future<void> _abrirCadastroCotas() async {
    final retorno = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => UsinaPage(
          repositorio: widget.repositorioUsina ?? RepositorioApiUsina(),
          telaInicial: 2,
          usinaIdInicial: _usinaSelecionadaId,
          nomeAdmin: widget.nomeAdmin,
          repositorioPainel: widget.repositorioPainel,
          repositorioEnergia: widget.repositorio,
          repositorioPerfil: widget.repositorioPerfil,
          aoSincronizarPainel: widget.aoSincronizarPainel,
        ),
      ),
    );
    if (!mounted) return;
    if (retorno != null && retorno.isNotEmpty) {
      _usinaSelecionadaId = retorno;
    }
    await _inicializar();
  }

  // formata a data para a API (ex: 2026-10)
  String get _mesReferenciaApi {
    final mes = _periodoSelecionado.month.toString().padLeft(2, '0');
    return '${_periodoSelecionado.year}-$mes';
  }

  // formata a data para o campo da tela (ex: outubro de 2026)
  String get _periodoFormatado {
    final nomeMes = _nomesMeses[_periodoSelecionado.month - 1];
    return '$nomeMes de ${_periodoSelecionado.year}';
  }

  double get _geracaoInformada {
    final texto = _geracaoController.text.trim().replaceAll(',', '.');
    return double.tryParse(texto) ?? 0.0;
  }

  bool get _podeDistribuir =>
      _geracaoInformada > 0 &&
      !_salvando &&
      !_carregandoCotas &&
      _cotas.isNotEmpty &&
      !_erroCarregamentoCotas;

  // modal para seleção do mês e ano de referência
  Future<void> _abrirSeletorPeriodo() async {
    final resultado = await showDatePicker(
      context: context,
      initialDate: _periodoSelecionado,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Selecione o período de referência',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF142340),
              onPrimary: Colors.white,
              onSurface: Color(0xFF001231),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (resultado != null) {
      setState(() {
        _periodoSelecionado = DateTime(resultado.year, resultado.month);
        _mostrarSucesso = false;
      });
    }
  }

  // submete os dados e distribui os créditos no banco
  Future<void> _confirmarEDistribuir() async {
    if (!_podeDistribuir) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _salvando = true;
      _mostrarSucesso = false;
      _mensagemErro = null;
    });

    final sucesso = await widget.repositorio.salvarLancamentoMensal(
      mesReferencia: _mesReferenciaApi,
      geracaoKwh: _geracaoInformada,
      usinaId: _usinaSelecionadaId,
    );

    if (!mounted) return;

    if (sucesso) {
      widget.aoSincronizarPainel?.call(_usinaSelecionadaId);
      setState(() {
        _salvando = false;
        _mostrarSucesso = true;
        _geracaoController
            .clear(); // limpa o input após lançamento bem-sucedido
      });
    } else {
      setState(() {
        _salvando = false;
        _mensagemErro =
            'Não foi possível salvar os dados. Verifique a conexão com o servidor.';
      });
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F7F9),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // cabeçalho azul escuro do admin
              Container(
                width: double.infinity,
                color: const Color(0xFF0B1830),
                child: SafeArea(
                  bottom: false,
                  child: _CabecalhoAdmin(
                    usinaIdSelecionada: _usinaSelecionadaId,
                  ),
                ),
              ),

              // formulário e pré-visualização rolável
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // banner de confirmação verde do protótipo
                    if (_mostrarSucesso) ...[
                      const _BannerSucesso(),
                      const SizedBox(height: 14),
                    ],

                    if (_mensagemErro != null) ...[
                      _BannerErro(mensagem: _mensagemErro!),
                      const SizedBox(height: 14),
                    ],

                    if (_usinas.isNotEmpty) ...[
                      _CardUsinaGeracao(
                        usinas: _usinas,
                        usinaSelecionadaId: _usinaSelecionadaId,
                        aoSelecionarUsina: _selecionarUsina,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // card: dados de geração
                    _CardDadosGeracao(
                      periodoFormatado: _periodoFormatado,
                      geracaoController: _geracaoController,
                      aoClicarPeriodo: _abrirSeletorPeriodo,
                      tarifaPadrao: _cotas.isNotEmpty
                          ? _cotas.first.tarifaKwh
                          : 0.69,
                    ),

                    const SizedBox(height: 16),

                    if (_carregandoCotas) ...[
                      const _CardCarregandoCotas(),
                      const SizedBox(height: 16),
                    ] else if (_cotas.isEmpty && !_erroCarregamentoCotas) ...[
                      _CardSemCotasUsina(aoCadastrarCotas: _abrirCadastroCotas),
                      const SizedBox(height: 16),
                    ] else if (_geracaoInformada > 0 && _cotas.isNotEmpty) ...[
                      // card: pré-visualização da distribuição (aparece após digitar o valor)
                      _CardPreviaDistribuicao(
                        cotas: _cotas,
                        geracaoTotalKwh: _geracaoInformada,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // botão confirmar e distribuir créditos
                    _BotaoConfirmar(
                      habilitado: _podeDistribuir,
                      carregando: _salvando,
                      aoPressionar: _confirmarEDistribuir,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // barra de navegação inferior do Administrador
          bottomNavigationBar: BarraNavegacaoAdmin(
            indiceSelecionado: 3,
            aoMudarAba: (indice) => navegarAbaAdmin(
              context,
              indiceAtual: 3,
              indiceDestino: indice,
              nomeAdmin: widget.nomeAdmin,
              usinaId: _usinaSelecionadaId,
              repositorioPainel: widget.repositorioPainel,
              repositorioEnergia: widget.repositorio,
              repositorioUsina: widget.repositorioUsina,
              repositorioPerfil: widget.repositorioPerfil,
              aoSincronizarPainel: widget.aoSincronizarPainel,
              aoRetornarComUsina: (retorno) {
                if (retorno != null && retorno.isNotEmpty) {
                  _usinaSelecionadaId = retorno;
                }
              },
              aoRetornarParaAtual: () {
                if (mounted) _inicializar();
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENTES VISUAIS DA TELA
// ==========================================

class _CabecalhoAdmin extends StatelessWidget {
  const _CabecalhoAdmin({this.usinaIdSelecionada});

  final String? usinaIdSelecionada;

  @override
  Widget build(BuildContext context) {
    final podeVoltar = Navigator.of(context).canPop();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (podeVoltar)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(usinaIdSelecionada),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          const Text(
            'Geração e Consumo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Lançamento de dados mensais',
            style: TextStyle(
              color: Color(0xFF8F9EB3),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardUsinaGeracao extends StatelessWidget {
  const _CardUsinaGeracao({
    required this.usinas,
    required this.usinaSelecionadaId,
    required this.aoSelecionarUsina,
  });

  final List<Usina> usinas;
  final String? usinaSelecionadaId;
  final ValueChanged<String?> aoSelecionarUsina;

  @override
  Widget build(BuildContext context) {
    final selecionada = usinas.firstWhere(
      (u) => u.id == usinaSelecionadaId,
      orElse: () => usinas.first,
    );
    final valorDropdown = usinas.any((u) => u.id == usinaSelecionadaId)
        ? usinaSelecionadaId
        : usinas.first.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.solar_power_outlined,
                color: Color(0xFF142340),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Usina de geração',
                style: TextStyle(
                  color: Color(0xFF5B6472),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (usinas.length > 1)
            DropdownButtonFormField<String>(
              key: const Key('seletor_usina_geracao'),
              initialValue: valorDropdown,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDCE2EC)),
                ),
              ),
              items: [
                for (final item in usinas)
                  DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(
                      item.codigo.isNotEmpty
                          ? '${item.nome} (${item.codigo})'
                          : item.nome,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF142340),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
              onChanged: aoSelecionarUsina,
            )
          else
            Text(
              selecionada.codigo.isNotEmpty
                  ? '${selecionada.nome} (${selecionada.codigo})'
                  : selecionada.nome,
              style: const TextStyle(
                color: Color(0xFF142340),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _CardCarregandoCotas extends StatelessWidget {
  const _CardCarregandoCotas();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF142340),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Carregando cotas da usina...',
              style: TextStyle(
                color: Color(0xFF5B6472),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSemCotasUsina extends StatelessWidget {
  const _CardSemCotasUsina({required this.aoCadastrarCotas});

  final VoidCallback aoCadastrarCotas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF4A12B).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFC47A13), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Esta usina ainda não possui membros com cotas cadastradas.',
                  style: TextStyle(
                    color: Color(0xFF142340),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Cadastre os membros e defina o percentual de cotas antes de distribuir créditos.',
            style: TextStyle(
              color: Color(0xFF5B6472),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: aoCadastrarCotas,
            icon: const Icon(Icons.pie_chart_outline, size: 18),
            label: const Text('Cadastrar cotas'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF142340),
              side: const BorderSide(color: Color(0xFF142340)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerSucesso extends StatelessWidget {
  const _BannerSucesso();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F1E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_box, color: Color(0xFF2E7D32), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dados lançados e créditos distribuídos!',
              style: TextStyle(
                color: Color(0xFF1B4332),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerErro extends StatelessWidget {
  const _BannerErro({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD32F2F), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDadosGeracao extends StatelessWidget {
  const _CardDadosGeracao({
    required this.periodoFormatado,
    required this.geracaoController,
    required this.aoClicarPeriodo,
    required this.tarifaPadrao,
  });

  final String periodoFormatado;
  final TextEditingController geracaoController;
  final VoidCallback aoClicarPeriodo;
  final double tarifaPadrao;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dados de geração',
            style: TextStyle(
              color: Color(0xFF001231),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),

          // campo 1: período de referência
          const Text(
            'Período de referência',
            style: TextStyle(
              color: Color(0xFF001231),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: aoClicarPeriodo,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD3D8E0), width: 1.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      periodoFormatado,
                      style: const TextStyle(
                        color: Color(0xFF001231),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 19,
                    color: Color(0xFF142340),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // campo 2: geração total da usina
          const Text(
            'Geração total da usina (kWh)',
            style: TextStyle(
              color: Color(0xFF001231),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: TextField(
              controller: geracaoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: Color(0xFF001231),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Ex: 310',
                hintStyle: const TextStyle(
                  color: Color(0xFF98A2B3),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFD3D8E0),
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFD3D8E0),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF142340),
                    width: 1.8,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // aviso: tarifa de referência
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF97316).withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tarifa de referência',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'R\$ ${tarifaPadrao.toStringAsFixed(2)} / kWh · Bandeira verde',
                  style: const TextStyle(
                    color: Color(0xFF78350F),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPreviaDistribuicao extends StatelessWidget {
  const _CardPreviaDistribuicao({
    required this.cotas,
    required this.geracaoTotalKwh,
  });

  final List<CotaMembro> cotas;
  final double geracaoTotalKwh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pré-visualização da distribuição',
            style: TextStyle(
              color: Color(0xFF001231),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),

          // lista dos membros com cálculo proporcional
          for (var i = 0; i < cotas.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 14,
                thickness: 0.7,
                color: Color(0xFFEDF1F5),
              ),
            _LinhaMembroDistribuicao(
              cota: cotas[i],
              geracaoTotalKwh: geracaoTotalKwh,
            ),
          ],
        ],
      ),
    );
  }
}

class _LinhaMembroDistribuicao extends StatelessWidget {
  const _LinhaMembroDistribuicao({
    required this.cota,
    required this.geracaoTotalKwh,
  });

  final CotaMembro cota;
  final double geracaoTotalKwh;

  @override
  Widget build(BuildContext context) {
    final kwhCalculado = cota.calcularKwh(geracaoTotalKwh);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              cota.nome,
              style: const TextStyle(
                color: Color(0xFF001231),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${cota.percentual.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Color(0xFF566373),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 75,
            child: Text(
              '${kwhCalculado.toStringAsFixed(0)} kWh',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF001231),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoConfirmar extends StatelessWidget {
  const _BotaoConfirmar({
    required this.habilitado,
    required this.carregando,
    required this.aoPressionar,
  });

  final bool habilitado;
  final bool carregando;
  final VoidCallback aoPressionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: habilitado && !carregando ? aoPressionar : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF142340),
          disabledBackgroundColor: const Color(0xFFB0B8C1),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: habilitado ? 2 : 0,
        ),
        child: carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text(
                'Confirmar e distribuir créditos',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}
