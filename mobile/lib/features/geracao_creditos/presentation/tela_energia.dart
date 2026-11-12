// autora: Maria Júlia Lazarini Oleto
// RA: 25006031

// significado do arquivo: tela dos gráficos de geração e consumo (membro)

import 'dart:math' as matematica;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth/data/sessao_auth.dart';
import '../../painel_membro/domain/repositorio_painel_membro.dart';
import '../../painel_membro/presentation/tela_painel_membro.dart';
import '../../perfil/domain/repositorio_perfil.dart';
import '../../perfil/presentation/tela_perfil.dart';
import '../../relatorios/domain/repositorio_relatorios.dart';
import '../../relatorios/presentation/tela_relatorios.dart';
import '../domain/repositorio_energia.dart';

class TelaEnergia extends StatefulWidget {
  const TelaEnergia({
    super.key,
    required this.repositorio,
    this.emailMembro,
    this.membroId,
    this.aoPerfilAtualizado,
    this.repositorioPerfil,
  });

  final RepositorioEnergia repositorio;

  // dados do membro logado: usados para consultar energia/consumo e manter as abas sincronizadas
  final String? emailMembro;
  final String? membroId;
  final ValueChanged<PerfilMembro>? aoPerfilAtualizado;
  final RepositorioPerfil? repositorioPerfil; // permite trocar o repositório (útil nos testes)

  @override
  State<TelaEnergia> createState() => _EstadoTelaEnergia();
}

class _EstadoTelaEnergia extends State<TelaEnergia> {
  late Future<ResumoEnergia> _resumoFuturo;
  int _abaSelecionada = 0;

  String? get _emailEfetivo {
    final email = widget.emailMembro ?? SessaoAuth.instancia.usuario?.email;
    return (email != null && email.trim().isNotEmpty) ? email.trim() : null;
  }

  String? get _membroIdEfetivo {
    final id = widget.membroId ?? SessaoAuth.instancia.usuario?.id;
    return (id != null && id.trim().isNotEmpty) ? id.trim() : null;
  }

  // barra inferior: Início volta ao painel, Relatórios e Perfil navegam mantendo a raiz limpa
  void _aoSelecionarAbaInferior(int indice) {
    final email = _emailEfetivo;
    if (indice == 0) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TelaPainelMembro(
              repositorio: RepositorioApiPainelMembro(),
              emailMembro: email,
            ),
          ),
        );
      }
    }
    if (indice == 2) {
      final rota = MaterialPageRoute(
        builder: (_) => TelaRelatorios(
          repositorio: RepositorioApiRelatorios(),
          emailMembro: email,
          aoPerfilAtualizado: widget.aoPerfilAtualizado,
          repositorioPerfil: widget.repositorioPerfil,
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pushReplacement(rota);
      } else {
        Navigator.of(context).push(rota);
      }
    }
    if (indice == 3) {
      abrirTelaPerfil(
        context,
        email: email,
        aoPerfilAtualizado: widget.aoPerfilAtualizado,
        repositorio: widget.repositorioPerfil,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  void _carregarResumo() {
    _resumoFuturo = widget.repositorio.buscarResumo(
      ano: 2026,
      membroId: _membroIdEfetivo,
      email: _emailEfetivo,
    );
  }

  Future<void> _atualizar() async {
    setState(() {
      _carregarResumo();
    });
    await _resumoFuturo;
  }

  Future<void> _abrirRegistroConsumo(ResumoEnergia resumo) async {
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoRegistrarConsumo(
        resumo: resumo,
        repositorio: widget.repositorio,
        membroId: _membroIdEfetivo,
        email: _emailEfetivo,
      ),
    );
    if (salvou == true && mounted) {
      await _atualizar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consumo mensal registrado com sucesso!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: FutureBuilder<ResumoEnergia>(
        future: _resumoFuturo,
        builder: (context, estado) {
          final resumo = estado.data ?? ResumoEnergia.exemplo();

          return Scaffold(
            backgroundColor: const Color(0xFFF6F7F9),
            body: Column(
              children: [
                Container(
                  color: const Color(0xFF0B1830),
                  child: SafeArea(
                    bottom: false,
                    child: _Cabecalho(ano: resumo.ano),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _atualizar,
                    color: const Color(0xFF142340),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _ControleSegmentado(
                          indiceSelecionado: _abaSelecionada,
                          aoAlterar: (indice) =>
                              setState(() => _abaSelecionada = indice),
                        ),
                        const SizedBox(height: 14),
                        if (_abaSelecionada == 0)
                          _ConteudoGeracao(resumo: resumo)
                        else
                          _ConteudoConsumo(
                            resumo: resumo,
                            onRegistrarConsumo: () =>
                                _abrirRegistroConsumo(resumo),
                          ),
                        const SizedBox(height: 14),
                        _CartaoSaldo(resumo: resumo),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _NavegacaoInferior(
              aoSelecionar: _aoSelecionarAbaInferior,
            ),
          );
        },
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.ano});

  final int ano;

  @override
  Widget build(BuildContext context) {
    final podeVoltar = Navigator.of(context).canPop();

    return Padding(
      padding: EdgeInsets.fromLTRB(podeVoltar ? 12 : 22, 14, 22, 18),
      child: Row(
        children: [
          if (podeVoltar) ...[
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Voltar ao início',
            ),
            const SizedBox(width: 4),
          ],
          const Expanded(
            child: Text(
              'Energia',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Text(
            '$ano',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControleSegmentado extends StatelessWidget {
  const _ControleSegmentado({
    required this.indiceSelecionado,
    required this.aoAlterar,
  });

  final int indiceSelecionado;
  final ValueChanged<int> aoAlterar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _BotaoSegmento(
            rotulo: 'Geração',
            selecionado: indiceSelecionado == 0,
            aoPressionar: () => aoAlterar(0),
          ),
          _BotaoSegmento(
            rotulo: 'Consumo',
            selecionado: indiceSelecionado == 1,
            aoPressionar: () => aoAlterar(1),
          ),
        ],
      ),
    );
  }
}

class _BotaoSegmento extends StatelessWidget {
  const _BotaoSegmento({
    required this.rotulo,
    required this.selecionado,
    required this.aoPressionar,
  });

  final String rotulo;
  final bool selecionado;
  final VoidCallback aoPressionar;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox.expand(
        child: TextButton(
          onPressed: aoPressionar,
          style: TextButton.styleFrom(
            foregroundColor: selecionado
                ? Colors.white
                : const Color(0xFF566373),
            backgroundColor: selecionado
                ? const Color(0xFF182642)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          child: Text(rotulo),
        ),
      ),
    );
  }
}

class _ConteudoGeracao extends StatelessWidget {
  const _ConteudoGeracao({required this.resumo});

  final ResumoEnergia resumo;

  @override
  Widget build(BuildContext context) {
    final mesesAtivos = resumo.meses
        .where((mes) => mes.geracaoKwh > 0)
        .toList();
    final maiorKwh = mesesAtivos.fold<double>(
      1,
      (maior, mes) => matematica.max(maior, mes.geracaoKwh),
    );

    return Column(
      children: [
        _Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Geração solar por mês',
                      style: TextStyle(
                        color: Color(0xFF001231),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '${resumo.totalGeracaoKwh.toStringAsFixed(0)} kWh',
                    style: const TextStyle(
                      color: Color(0xFF001231),
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 126,
                child: _GraficoBarrasMensais(
                  meses: mesesAtivos,
                  ehConsumo: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalhamento mensal',
                style: TextStyle(
                  color: Color(0xFF001231),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < mesesAtivos.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 0.8,
                    color: Color(0xFFEDF1F5),
                  ),
                _LinhaProgressoMes(
                  rotulo: mesesAtivos[i].rotulo,
                  valor: mesesAtivos[i].geracaoKwh,
                  maiorValor: maiorKwh,
                  corBarra: const Color(0xFF182642),
                  corFundo: const Color(0xFFE5EAF0),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ConteudoConsumo extends StatelessWidget {
  const _ConteudoConsumo({
    required this.resumo,
    required this.onRegistrarConsumo,
  });

  final ResumoEnergia resumo;
  final VoidCallback onRegistrarConsumo;

  @override
  Widget build(BuildContext context) {
    final mesesAtivos = resumo.meses
        .where((mes) => mes.consumoKwh > 0)
        .toList();
    final maiorKwh = mesesAtivos.fold<double>(
      1,
      (maior, mes) => matematica.max(maior, mes.consumoKwh),
    );

    return Column(
      children: [
        _Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Consumo por mês',
                      style: TextStyle(
                        color: Color(0xFF001231),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '${resumo.totalConsumoKwh.toStringAsFixed(0)} kWh',
                    style: const TextStyle(
                      color: Color(0xFFE59828),
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onRegistrarConsumo,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Registrar consumo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF182642),
                    side: const BorderSide(color: Color(0xFFD6DEE8)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (mesesAtivos.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5EAF0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.bolt_outlined,
                        color: Color(0xFFE59828),
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nenhum consumo registrado ainda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF182642),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Informe o consumo em kWh da sua fatura para acompanhar seu saldo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6C7686),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: onRegistrarConsumo,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Informar consumo mensal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF182642),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 126,
                  child: _GraficoBarrasMensais(
                    meses: mesesAtivos,
                    ehConsumo: true,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalhamento mensal',
                style: TextStyle(
                  color: Color(0xFF001231),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              if (mesesAtivos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Adicione seu consumo mensal acima para ver o histórico mês a mês.',
                    style: TextStyle(
                      color: Color(0xFF7A8795),
                      fontSize: 13,
                    ),
                  ),
                )
              else
                for (var i = 0; i < mesesAtivos.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      color: Color(0xFFEDF1F5),
                    ),
                  _LinhaProgressoMes(
                    rotulo: mesesAtivos[i].rotulo,
                    valor: mesesAtivos[i].consumoKwh,
                    maiorValor: maiorKwh,
                    corBarra: const Color(0xFFE59828),
                    corFundo: const Color(0xFFFDECD4),
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Painel extends StatelessWidget {
  const _Painel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GraficoBarrasMensais extends StatelessWidget {
  const _GraficoBarrasMensais({required this.meses, required this.ehConsumo});

  final List<MesEnergia> meses;
  final bool ehConsumo;

  @override
  Widget build(BuildContext context) {
    if (meses.isEmpty) return const SizedBox.shrink();

    final maiorKwh = meses.fold<double>(
      1,
      (maior, mes) =>
          matematica.max(maior, ehConsumo ? mes.consumoKwh : mes.geracaoKwh),
    );
    final ultimoIndice = meses.length - 1;

    final corDestaque = ehConsumo
        ? const Color(0xFFE59828)
        : const Color(0xFF182642);
    final corInativa = ehConsumo
        ? const Color(0xFFFBD6A4)
        : const Color(0xFF9FA8B4);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(meses.length, (indice) {
        final mes = meses[indice];
        final valor = ehConsumo ? mes.consumoKwh : mes.geracaoKwh;
        final fatorAltura = valor <= 0 ? 0.08 : valor / maiorKwh;
        final selecionado = indice == ultimoIndice;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (selecionado)
                  Text(
                    valor.toStringAsFixed(0),
                    style: TextStyle(
                      color: corDestaque,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                else
                  const SizedBox(height: 12),
                const SizedBox(height: 4),
                Flexible(
                  child: FractionallySizedBox(
                    heightFactor: fatorAltura.clamp(0.08, 1).toDouble(),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 22,
                      decoration: BoxDecoration(
                        color: selecionado ? corDestaque : corInativa,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mes.rotulo,
                  maxLines: 1,
                  style: TextStyle(
                    color: selecionado
                        ? const Color(0xFF182642)
                        : const Color(0xFF7A8795),
                    fontSize: 10,
                    fontWeight: selecionado ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _LinhaProgressoMes extends StatelessWidget {
  const _LinhaProgressoMes({
    required this.rotulo,
    required this.valor,
    required this.maiorValor,
    required this.corBarra,
    required this.corFundo,
  });

  final String rotulo;
  final double valor;
  final double maiorValor;
  final Color corBarra;
  final Color corFundo;

  @override
  Widget build(BuildContext context) {
    final fator = maiorValor > 0 ? (valor / maiorValor).clamp(0.02, 1.0) : 0.02;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              rotulo,
              style: const TextStyle(
                color: Color(0xFF566373),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: fator.toDouble(),
                backgroundColor: corFundo,
                valueColor: AlwaysStoppedAnimation(corBarra),
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valor.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Color(0xFF001231),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    height: 1.1,
                  ),
                ),
                const Text(
                  'kWh',
                  style: TextStyle(
                    color: Color(0xFF001231),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    height: 1.1,
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

class _CartaoSaldo extends StatelessWidget {
  const _CartaoSaldo({required this.resumo});

  final ResumoEnergia resumo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE59828),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE59828).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo acumulado',
            style: TextStyle(
              color: const Color(0xFF001231).withValues(alpha: 0.65),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            resumo.saldoAcumuladoKwh >= 0
                ? '+${resumo.saldoAcumuladoKwh.toStringAsFixed(0)} kWh'
                : '${resumo.saldoAcumuladoKwh.toStringAsFixed(0)} kWh',
            style: const TextStyle(
              color: Color(0xFF001231),
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Equivale a R\$ ${resumo.economiaEstimadaReais.toStringAsFixed(2)} em desconto na conta',
            style: TextStyle(
              color: const Color(0xFF001231).withValues(alpha: 0.65),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavegacaoInferior extends StatelessWidget {
  const _NavegacaoInferior({required this.aoSelecionar});

  final ValueChanged<int> aoSelecionar;

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
      selectedIndex: 1,
      onDestinationSelected: aoSelecionar,
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
              color: i == 1 ? const Color(0xFF142340) : const Color(0xFF7A8795),
            ),
            selectedIcon: Icon(itens[i].$1, color: const Color(0xFF142340)),
            label: itens[i].$2,
          ),
      ],
    );
  }
}

class _DialogoRegistrarConsumo extends StatefulWidget {
  const _DialogoRegistrarConsumo({
    required this.resumo,
    required this.repositorio,
    this.membroId,
    this.email,
  });

  final ResumoEnergia resumo;
  final RepositorioEnergia repositorio;
  final String? membroId;
  final String? email;

  @override
  State<_DialogoRegistrarConsumo> createState() =>
      _EstadoDialogoRegistrarConsumo();
}

class _EstadoDialogoRegistrarConsumo extends State<_DialogoRegistrarConsumo> {
  final _formulario = GlobalKey<FormState>();
  final _consumoController = TextEditingController();
  late String _mesReferencia;
  bool _salvando = false;
  String? _erro;

  List<MesEnergia> get _opcoesMeses {
    if (widget.resumo.meses.isNotEmpty) {
      return widget.resumo.meses;
    }
    const rotulos = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return List.generate(
      12,
      (i) => MesEnergia(
        rotulo: rotulos[i],
        referencia:
            '${widget.resumo.ano}-${(i + 1).toString().padLeft(2, '0')}',
        geracaoKwh: 0,
        creditosLiquidosKwh: 0,
        consumoKwh: 0,
        saldoMesKwh: 0,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final opcoes = _opcoesMeses;
    final agora = DateTime.now();
    final referenciaAtual =
        '${widget.resumo.ano}-${agora.month.toString().padLeft(2, '0')}';
    final mesEncontrado = opcoes.firstWhere(
      (m) => m.referencia == referenciaAtual,
      orElse: () => opcoes.lastWhere(
        (m) => m.geracaoKwh > 0 || m.creditosLiquidosKwh > 0,
        orElse: () => opcoes.first,
      ),
    );
    _mesReferencia = mesEncontrado.referencia;
    _preencherConsumoDoMes(_mesReferencia);
  }

  void _preencherConsumoDoMes(String referencia) {
    final mes = _opcoesMeses.cast<MesEnergia?>().firstWhere(
      (m) => m?.referencia == referencia,
      orElse: () => null,
    );
    if (mes != null && mes.consumoKwh > 0) {
      _consumoController.text = mes.consumoKwh == mes.consumoKwh.roundToDouble()
          ? mes.consumoKwh.toStringAsFixed(0)
          : mes.consumoKwh.toString();
    } else {
      _consumoController.clear();
    }
  }

  @override
  void dispose() {
    _consumoController.dispose();
    super.dispose();
  }

  double? _lerConsumo(String texto) {
    final normalizado = texto.trim().replaceAll(',', '.');
    return double.tryParse(normalizado);
  }

  Future<void> _salvar() async {
    if (!_formulario.currentState!.validate()) return;
    final valor = _lerConsumo(_consumoController.text);
    if (valor == null) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final ok = await widget.repositorio.salvarConsumoMensal(
      mesReferencia: _mesReferencia,
      consumoKwh: valor,
      membroId: widget.membroId,
      email: widget.email,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _salvando = false;
        _erro =
            'Não foi possível salvar o consumo. Verifique sua conexão e conta.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final opcoes = _opcoesMeses;
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Registrar consumo mensal',
        style: TextStyle(
          color: Color(0xFF001231),
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      content: Form(
        key: _formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _mesReferencia,
              decoration: const InputDecoration(
                labelText: 'Mês de referência',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final mes in opcoes)
                  DropdownMenuItem(
                    value: mes.referencia,
                    child: Text('${mes.rotulo}/${widget.resumo.ano}'),
                  ),
              ],
              onChanged: _salvando
                  ? null
                  : (novo) {
                      if (novo == null) return;
                      setState(() {
                        _mesReferencia = novo;
                        _preencherConsumoDoMes(novo);
                      });
                    },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _consumoController,
              enabled: !_salvando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Consumo (kWh)',
                hintText: 'Ex.: 210',
                suffixText: 'kWh',
                border: OutlineInputBorder(),
              ),
              validator: (texto) {
                final v = _lerConsumo(texto ?? '');
                if (v == null || v < 0) {
                  return 'Informe um valor válido em kWh';
                }
                return null;
              },
            ),
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(
                _erro!,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF182642),
            foregroundColor: Colors.white,
          ),
          child: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
