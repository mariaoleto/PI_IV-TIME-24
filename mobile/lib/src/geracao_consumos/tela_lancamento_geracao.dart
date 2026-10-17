// autora: Maria Júlia Lazarini Oleto

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'modelos_energia.dart';
import 'repositorio_energia.dart';

class TelaLancamentoGeracao extends StatefulWidget {
  const TelaLancamentoGeracao({
    super.key,
    required this.repositorio,
    this.usinaId,
  });

  final RepositorioEnergia repositorio;
  final String? usinaId;

  @override
  State<TelaLancamentoGeracao> createState() => _EstadoTelaLancamentoGeracao();
}

class _EstadoTelaLancamentoGeracao extends State<TelaLancamentoGeracao> {
  late final TextEditingController _geracaoController;
  DateTime _periodoSelecionado = DateTime(2026, 10); // Outubro de 2026

  List<CotaMembro> _cotas = [];
  bool _carregandoCotas = true;
  bool _salvando = false;
  bool _mostrarSucesso = false;
  String? _mensagemErro;

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
    _geracaoController = TextEditingController();
    _geracaoController.addListener(() => setState(() {}));
    _carregarCotas();
  }

  @override
  void dispose() {
    _geracaoController.dispose();
    super.dispose();
  }

  // busca a lista de cotas da usina no backend
  Future<void> _carregarCotas() async {
    setState(() {
      _carregandoCotas = true;
      _mensagemErro = null;
    });

    try {
      final cotas = await widget.repositorio.buscarCotasDistribuicao(
        usinaId: widget.usinaId,
      );

      if (mounted) {
        setState(() {
          // caso a API retorne vazia, usa a lista de cooperados padrão
          _cotas = cotas.isNotEmpty ? cotas : _cotasExemplo();
          _carregandoCotas = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cotas = _cotasExemplo();
          _carregandoCotas = false;
        });
      }
    }
  }

  // lista de membros para exibição visual caso a conexão oscile
  List<CotaMembro> _cotasExemplo() {
    return const [
      CotaMembro(
        cotaId: '1',
        membroId: '65',
        nome: 'João Oliveira',
        percentual: 25,
        tarifaKwh: 0.69,
      ),
      CotaMembro(
        cotaId: '2',
        membroId: '66',
        nome: 'Maria Santos',
        percentual: 18,
        tarifaKwh: 0.69,
      ),
      CotaMembro(
        cotaId: '3',
        membroId: '67',
        nome: 'Carlos Nunes',
        percentual: 15,
        tarifaKwh: 0.69,
      ),
      CotaMembro(
        cotaId: '4',
        membroId: '68',
        nome: 'Ana Ferreira',
        percentual: 12,
        tarifaKwh: 0.69,
      ),
      CotaMembro(
        cotaId: '5',
        membroId: '69',
        nome: 'Lucas Pereira',
        percentual: 10,
        tarifaKwh: 0.69,
      ),
      CotaMembro(
        cotaId: '6',
        membroId: '70',
        nome: 'Sofia Alves',
        percentual: 8,
        tarifaKwh: 0.69,
      ),
      CotaMembro(
        cotaId: '7',
        membroId: '71',
        nome: 'Pedro Costa',
        percentual: 7,
        tarifaKwh: 0.69,
      ),
      CotaMembro(
        cotaId: '8',
        membroId: '72',
        nome: 'Juliana Lima',
        percentual: 5,
        tarifaKwh: 0.69,
      ),
    ];
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

  bool get _podeDistribuir => _geracaoInformada > 0 && !_salvando;

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
      usinaId: widget.usinaId,
    );

    if (!mounted) return;

    if (sucesso) {
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
              child: const SafeArea(bottom: false, child: _CabecalhoAdmin()),
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

                  // card: pré-visualização da distribuição (aparece após digitar o valor)
                  if (_geracaoInformada > 0 && !_carregandoCotas) ...[
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
        bottomNavigationBar: const _NavegacaoInferiorAdmin(),
      ),
    );
  }
}

// ==========================================
// COMPONENTES VISUAIS DA TELA
// ==========================================

class _CabecalhoAdmin extends StatelessWidget {
  const _CabecalhoAdmin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Geração e Consumo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 5),
          Text(
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

class _NavegacaoInferiorAdmin extends StatelessWidget {
  const _NavegacaoInferiorAdmin();

  @override
  Widget build(BuildContext context) {
    const itens = [
      (Icons.home_outlined, 'Início'),
      (Icons.desktop_windows_outlined, 'Usina'),
      (Icons.people_outline, 'Membros'),
      (Icons.bar_chart_outlined, 'Relatórios'),
      (Icons.person_outline, 'Perfil'),
    ];

    return NavigationBar(
      height: 64,
      selectedIndex: 3, // "Relatórios" selecionado conforme protótipo
      backgroundColor: Colors.white,
      indicatorColor: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black12,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        for (var i = 0; i < itens.length; i++)
          NavigationDestination(
            icon: Icon(
              itens[i].$1,
              color: i == 3 ? const Color(0xFF142340) : const Color(0xFF7A8795),
            ),
            selectedIcon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE59828),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 3),
                Icon(itens[i].$1, color: const Color(0xFF142340)),
              ],
            ),
            label: itens[i].$2,
          ),
      ],
    );
  }
}
