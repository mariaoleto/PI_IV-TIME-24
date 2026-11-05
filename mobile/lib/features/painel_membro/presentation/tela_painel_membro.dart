// autora: Maria Júlia Lazarini Oleto
// RA: 25006031

// significado do arquivo:
// tela inicial do painel administrativo do membro (dashboard principal com créditos, métricas e geração)

import 'dart:convert';
import 'dart:math' as matematica;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../geracao_creditos/domain/repositorio_energia.dart';
import '../../geracao_creditos/presentation/tela_energia.dart';
import '../../perfil/domain/repositorio_perfil.dart';
import '../../perfil/presentation/tela_perfil.dart';
import '../domain/repositorio_painel_membro.dart';

class TelaPainelMembro extends StatefulWidget {
  const TelaPainelMembro({
    super.key,
    required this.repositorio,
    this.emailMembro,
  });

  final RepositorioPainelMembro repositorio;
  final String? emailMembro;

  @override
  State<TelaPainelMembro> createState() => _EstadoTelaPainelMembro();
}

class _EstadoTelaPainelMembro extends State<TelaPainelMembro> {
  late Future<DadosPainelMembro> _dashboardFuturo;

  // e-mail do membro logado; muda se ele editar o e-mail na tela de Perfil
  String? _emailMembro;

  @override
  void initState() {
    super.initState();
    _emailMembro = widget.emailMembro;
    _carregarDashboard();
  }

  void _carregarDashboard() {
    _dashboardFuturo = widget.repositorio.buscarDashboard(
      email: _emailMembro,
      ano: 2026,
    );
  }

  Future<void> _atualizar() async {
    setState(() {
      _carregarDashboard();
    });
    await _dashboardFuturo;
  }

  // se o e-mail foi alterado no Perfil, o painel passa a buscar os dados pelo e-mail novo
  void _aoPerfilAtualizado(PerfilMembro perfil) {
    setState(() {
      _emailMembro = perfil.email;
      _carregarDashboard();
    });
  }

  void _aoSelecionarAba(int indice) {
    if (indice == 1) {
      // Navega para a tela de Energia (que também tem a aba Perfil, por isso recebe os mesmos dados)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TelaEnergia(
            repositorio: RepositorioApiEnergia(),
            emailMembro: _emailMembro,
            aoPerfilAtualizado: _aoPerfilAtualizado,
          ),
        ),
      );
    }
    if (indice == 3) {
      abrirTelaPerfil(
        context,
        email: _emailMembro,
        aoPerfilAtualizado: _aoPerfilAtualizado,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: FutureBuilder<DadosPainelMembro>(
        future: _dashboardFuturo,
        builder: (context, estado) {
          final dados = estado.data ?? DadosPainelMembro.exemplo();

          return Scaffold(
            backgroundColor: const Color(0xFFF6F8FB),
            body: RefreshIndicator(
              onRefresh: _atualizar,
              color: const Color(0xFF142340),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _SecaoCabecalho(dados: dados)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const _CartaoTelemetriaTcp(),
                        const SizedBox(height: 14),
                        _GridMetricas(dados: dados),
                        const SizedBox(height: 16),
                        _CartaoGeracaoMensal(dados: dados),
                        const SizedBox(height: 16),
                        _CartaoUltimosLancamentos(dados: dados),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _BarraNavegacaoMembro(
              indiceSelecionado: 0,
              aoMudarAba: _aoSelecionarAba,
            ),
          );
        },
      ),
    );
  }
}

// Cabeçalho escuro superior com saudação, avatar e cartão principal de créditos
class _SecaoCabecalho extends StatelessWidget {
  const _SecaoCabecalho({required this.dados});

  final DadosPainelMembro dados;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1E36),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha com Saudação, Nome e Avatar circular
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dados.saudacao,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dados.nomeMembro,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4A12B),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dados.inicialMembro,
                      style: const TextStyle(
                        color: Color(0xFF142340),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Chip com percentual da cota
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4A12B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cota: ${dados.cotaPercentual.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Color(0xFFF4A12B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Cartão principal de créditos disponíveis
              _CartaoCreditos(dados: dados),
            ],
          ),
        ),
      ),
    );
  }
}

// Cartão interno escuro de créditos disponíveis e barra de utilização
class _CartaoCreditos extends StatelessWidget {
  const _CartaoCreditos({required this.dados});

  final DadosPainelMembro dados;

  @override
  Widget build(BuildContext context) {
    final progresso = (dados.percentualUtilizado / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF17284A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Créditos disponíveis · ${dados.mesReferencia}',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                dados.creditosDisponiveisKwh.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'kWh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Utilizado este mês',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${dados.percentualUtilizado}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barra de progresso linear
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6.5,
              width: double.infinity,
              color: const Color(0xFF263D6B),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progresso,
                child: Container(color: const Color(0xFFF4A12B)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Gerado: ${dados.geradoMesKwh.toStringAsFixed(0)} kWh',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Consumido: ${dados.consumidoMesKwh.toStringAsFixed(0)} kWh',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Grid 2x2 com os 4 cartões de métricas (CO2 evitado, Economia, Média diária, Pico consumo)
class _GridMetricas extends StatelessWidget {
  const _GridMetricas({required this.dados});

  final DadosPainelMembro dados;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CartaoMetricaItem(
                icone: Icons.eco_outlined,
                corFundoIcone: const Color(0xFFE8F2F8),
                corIcone: const Color(0xFF142340),
                valor: '${dados.co2EvitadoKg.toStringAsFixed(0)} kg',
                titulo: 'CO₂ evitado',
                subtitulo: 'este mês',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CartaoMetricaItem(
                icone: Icons.credit_card_outlined,
                corFundoIcone: const Color(0xFFFEF3E2),
                corIcone: const Color(0xFFB45309),
                valor: 'R\$ ${dados.economiaReais.toStringAsFixed(0)}',
                titulo: 'Economia',
                subtitulo: dados.mesEconomia,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CartaoMetricaItem(
                icone: Icons.calendar_today_outlined,
                corFundoIcone: const Color(0xFFEFF6FF),
                corIcone: const Color(0xFF475569),
                valor:
                    '${dados.mediaDiariaKwh.toStringAsFixed(1).replaceAll('.', ',')} kWh',
                titulo: 'Média diária',
                subtitulo: 'últimos 30d',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CartaoMetricaItem(
                icone: Icons.trending_up,
                corFundoIcone: const Color(0xFFFEF2F2),
                corIcone: const Color(0xFFEF4444),
                valor:
                    '${dados.picoConsumoKwh.toStringAsFixed(1).replaceAll('.', ',')} kWh',
                titulo: 'Pico consumo',
                subtitulo: dados.picoConsumoData,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CartaoMetricaItem extends StatelessWidget {
  const _CartaoMetricaItem({
    required this.icone,
    required this.corFundoIcone,
    required this.corIcone,
    required this.valor,
    required this.titulo,
    required this.subtitulo,
  });

  final IconData icone;
  final Color corFundoIcone;
  final Color corIcone;
  final String valor;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: corFundoIcone,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icone, size: 20, color: corIcone),
          ),
          const SizedBox(height: 14),
          Text(
            valor,
            style: const TextStyle(
              color: Color(0xFF142340),
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitulo,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Cartão do gráfico de barras para geração mensal
class _CartaoGeracaoMensal extends StatelessWidget {
  const _CartaoGeracaoMensal({required this.dados});

  final DadosPainelMembro dados;

  @override
  Widget build(BuildContext context) {
    final itens = dados.geracaoMensal;
    final maiorValor = itens.fold<double>(
      1.0,
      (max, item) => matematica.max(max, item.valorKwh),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Geração mensal',
                style: TextStyle(
                  color: Color(0xFF142340),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '2026',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Área das barras do gráfico
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final item in itens)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final alturaMaxima = constraints.maxHeight;
                                  final proporcao = maiorValor > 0
                                      ? (item.valorKwh / maiorValor)
                                      : 0.1;
                                  final alturaBarra = (alturaMaxima * proporcao)
                                      .clamp(12.0, alturaMaxima);

                                  return Container(
                                    height: alturaBarra,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: item.mesAtual
                                          ? const Color(0xFFF4A12B)
                                          : const Color(0xFF8E9CAE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.mes,
                            style: TextStyle(
                              color: item.mesAtual
                                  ? const Color(0xFF142340)
                                  : const Color(0xFF8E9CAE),
                              fontSize: 12,
                              fontWeight: item.mesAtual
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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

// Cartão com a lista dos últimos lançamentos de geração, consumo e crédito
class _CartaoUltimosLancamentos extends StatelessWidget {
  const _CartaoUltimosLancamentos({required this.dados});

  final DadosPainelMembro dados;

  @override
  Widget build(BuildContext context) {
    final lancamentos = dados.ultimosLancamentos;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimos lançamentos',
            style: TextStyle(
              color: Color(0xFF142340),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          // Cabeçalho da tabela
          Row(
            children: const [
              Expanded(
                flex: 4,
                child: Text(
                  'Mês',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Gerado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Consumo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Crédito',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          // Linhas dos lançamentos
          for (var i = 0; i < lancamentos.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      lancamentos[i].mesRotulo,
                      style: const TextStyle(
                        color: Color(0xFF142340),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      lancamentos[i].geradoKwh.toStringAsFixed(0),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      lancamentos[i].consumoKwh.toStringAsFixed(0),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: lancamentos[i].positivo
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          lancamentos[i].positivo
                              ? '+${lancamentos[i].creditoKwh.toStringAsFixed(0)} kWh'
                              : '${lancamentos[i].creditoKwh.toStringAsFixed(0)} kWh',
                          style: TextStyle(
                            color: lancamentos[i].positivo
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < lancamentos.length - 1)
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }
}

// Barra de navegação inferior sem a aba de alertas (Início, Energia, Relatórios, Perfil)
class _BarraNavegacaoMembro extends StatelessWidget {
  const _BarraNavegacaoMembro({
    required this.indiceSelecionado,
    required this.aoMudarAba,
  });

  final int indiceSelecionado;
  final ValueChanged<int> aoMudarAba;

  @override
  Widget build(BuildContext context) {
    const itens = [
      (Icons.home_outlined, 'Início'),
      (Icons.bolt_outlined, 'Energia'),
      (Icons.description_outlined, 'Relatórios'),
      (Icons.person_outline, 'Perfil'),
    ];

    return NavigationBar(
      height: 64,
      selectedIndex: indiceSelecionado,
      onDestinationSelected: aoMudarAba,
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
              color: i == indiceSelecionado
                  ? const Color(0xFF142340)
                  : const Color(0xFF7A8795),
            ),
            selectedIcon: Icon(itens[i].$1, color: const Color(0xFF142340)),
            label: itens[i].$2,
          ),
      ],
    );
  }
}

// Card compacto e elegante de status da telemetria do servidor Java TCP
class _CartaoTelemetriaTcp extends StatefulWidget {
  const _CartaoTelemetriaTcp();

  @override
  State<_CartaoTelemetriaTcp> createState() => _EstadoCartaoTelemetriaTcp();
}

class _EstadoCartaoTelemetriaTcp extends State<_CartaoTelemetriaTcp> {
  bool _carregando = true;
  bool _online = false;
  String _potencia = '14.2 kW';
  String _tensao = '220V';

  @override
  void initState() {
    super.initState();
    _buscarTelemetria();
  }

  Future<void> _buscarTelemetria() async {
    try {
      final uri = Uri.parse(
        '${RepositorioApiPainelMembro.urlPadrao}/energia/telemetria-tcp',
      );
      final resposta = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 3));

      if (resposta.statusCode == 200) {
        final mapa = jsonDecode(utf8.decode(resposta.bodyBytes));
        final telemetria = mapa['telemetria']?.toString() ?? '';

        String pot = '14.2 kW';
        String tens = '220V';

        final matchPot = RegExp(
          r'GERACAO_ATUAL=([^\s]+)',
        ).firstMatch(telemetria);
        if (matchPot != null) {
          pot = matchPot.group(1) ?? pot;
        }

        final matchTens = RegExp(r'TENSAO=([^\s]+)').firstMatch(telemetria);
        if (matchTens != null) {
          tens = matchTens.group(1) ?? tens;
        }

        if (mounted) {
          setState(() {
            _online = mapa['status_servidor_tcp'] == 'online';
            _potencia = pot;
            _tensao = tens;
            _carregando = false;
          });
        }
        return;
      }
    } catch (_) {
      // Se falhar ou o servidor estiver desligado
    }

    if (mounted) {
      setState(() {
        _online = false;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mini ícone solar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFFF4A12B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Informações de texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Telemetria TCP · Usina Solis 1',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _online
                      ? '$_potencia · $_tensao'
                      : (_carregando
                            ? 'Consultando inversor...'
                            : 'Inversor em espera'),
                  style: const TextStyle(
                    color: Color(0xFF142340),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Chip discreto com o status da conexão
          InkWell(
            onTap: _buscarTelemetria,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _online
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _online
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _online ? 'Java TCP' : 'Offline',
                    style: TextStyle(
                      color: _online
                          ? const Color(0xFF047857)
                          : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
