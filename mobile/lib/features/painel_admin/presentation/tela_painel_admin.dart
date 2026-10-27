// significado do arquivo:
// tela inicial do administrador: saudação, card da usina ativa,
// menu de gerenciamento, alertas ativos e próximo lançamento pendente

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../geracao_creditos/domain/repositorio_energia.dart';
import '../../geracao_creditos/presentation/tela_lancamento_geracao.dart';
import '../domain/repositorio_painel_admin.dart';

const Color _corFundoEscuro = Color(0xFF0B1830);
const Color _corPrimaria = Color(0xFF142340);
const Color _corDestaque = Color(0xFFF4A12B);
const Color _corTextoSecundario = Color(0xFF5B6472);

class TelaPainelAdmin extends StatefulWidget {
  const TelaPainelAdmin({
    super.key,
    required this.repositorio,
    required this.repositorioEnergia,
    this.nomeAdmin,
    this.usinaId,
    this.aoAbrirCadastroUsina,
    this.aoAbrirCadastroCotas,
    this.agora = DateTime.now,
  });

  final RepositorioPainelAdmin repositorio;
  final RepositorioEnergia repositorioEnergia;

  // nome exibido na saudação; quando ausente, mostra apenas "Administrador"
  final String? nomeAdmin;
  final String? usinaId;

  // telas de cadastro pertencem a outros módulos; enquanto não forem ligadas,
  // o item do menu avisa que ainda não está disponível
  final VoidCallback? aoAbrirCadastroUsina;
  final VoidCallback? aoAbrirCadastroCotas;

  // permite fixar o horário nos testes
  final DateTime Function() agora;

  @override
  State<TelaPainelAdmin> createState() => _EstadoTelaPainelAdmin();
}

class _EstadoTelaPainelAdmin extends State<TelaPainelAdmin> {
  PainelAdmin? _painel;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final painel = await widget.repositorio.buscarPainel(
        usinaId: widget.usinaId,
      );
      if (!mounted) return;
      setState(() {
        _painel = painel;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  String get _saudacao {
    final hora = widget.agora().hour;
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  void _avisarEmBreve(String nome) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nome ainda não está disponível.')),
    );
  }

  // abre o registro de geração e, ao voltar, recarrega o painel
  Future<void> _abrirRegistro() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TelaLancamentoGeracao(
          repositorio: widget.repositorioEnergia,
          usinaId: widget.usinaId ?? _painel?.usina.id,
        ),
      ),
    );
    if (mounted) _carregar();
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
            Container(
              color: _corFundoEscuro,
              child: SafeArea(
                bottom: false,
                child: _CabecalhoPainel(
                  saudacao: _saudacao,
                  nome: widget.nomeAdmin,
                ),
              ),
            ),
            Expanded(child: _corpo()),
          ],
        ),
      ),
    );
  }

  Widget _corpo() {
    final painel = _painel;
    if (painel == null) {
      if (_carregando) {
        return const Center(
          child: CircularProgressIndicator(color: _corPrimaria),
        );
      }
      return _EstadoErro(
        mensagem: _erro ?? 'Não foi possível carregar o painel.',
        aoTentarNovamente: _carregar,
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      color: _corPrimaria,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // erro ao atualizar: mantém os dados já carregados e avisa
          if (_erro != null) ...[
            _BannerAviso(mensagem: _erro!),
            const SizedBox(height: 14),
          ],
          _CartaoUsinaAtiva(painel: painel),
          const SizedBox(height: 22),
          const _TituloSecao('Gerenciamento'),
          const SizedBox(height: 10),
          _ItemMenu(
            icone: Icons.solar_power_outlined,
            titulo: 'Cadastro da Usina',
            subtitulo: 'Dados e capacidade da usina',
            aoPressionar:
                widget.aoAbrirCadastroUsina ??
                () => _avisarEmBreve('Cadastro da Usina'),
          ),
          _ItemMenu(
            icone: Icons.pie_chart_outline,
            titulo: 'Cadastro de Cotas',
            subtitulo: 'Cotas e percentuais dos membros',
            aoPressionar:
                widget.aoAbrirCadastroCotas ??
                () => _avisarEmBreve('Cadastro de Cotas'),
          ),
          _ItemMenu(
            icone: Icons.bolt_outlined,
            titulo: 'Registro de Geração e Consumo',
            subtitulo: 'Lançamento mensal e distribuição de créditos',
            aoPressionar: _abrirRegistro,
          ),
          const SizedBox(height: 22),
          _TituloSecao(
            'Alertas ativos',
            contador: painel.alertas.isEmpty ? null : painel.alertas.length,
          ),
          const SizedBox(height: 10),
          if (painel.alertas.isEmpty)
            const _SemAlertas()
          else
            for (final alerta in painel.alertas) _CartaoAlerta(alerta: alerta),
          const SizedBox(height: 22),
          const _TituloSecao('Próximo lançamento'),
          const SizedBox(height: 10),
          _CartaoProximoLancamento(
            lancamento: painel.proximoLancamento,
            aoLancar: _abrirRegistro,
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FORMATAÇÃO
// ==========================================

// 11160 -> "11.160"; 12.5 -> "12,5" (padrão brasileiro, sem depender do pacote intl)
String formatarNumeroBr(double valor, {int casas = 0}) {
  final texto = valor.abs().toStringAsFixed(casas);
  final partes = texto.split('.');
  final inteiro = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final sinal = valor < 0 && double.parse(texto) != 0 ? '-' : '';
  return casas > 0 ? '$sinal$inteiro,${partes[1]}' : '$sinal$inteiro';
}

// "2026-11-01" -> "01/11"
String _formatarDiaMes(String? dataIso) {
  final partes = dataIso?.split('-') ?? const [];
  return partes.length == 3 ? '${partes[2]}/${partes[1]}' : '';
}

// ==========================================
// COMPONENTES VISUAIS
// ==========================================

class _CabecalhoPainel extends StatelessWidget {
  const _CabecalhoPainel({required this.saudacao, this.nome});

  final String saudacao;
  final String? nome;

  @override
  Widget build(BuildContext context) {
    final temNome = nome != null && nome!.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temNome ? '$saudacao,' : saudacao,
                  style: const TextStyle(
                    color: Color(0xFF8F9EB3),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  temNome ? nome!.trim() : 'Painel administrativo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _SeloAdministrador(),
        ],
      ),
    );
  }
}

class _SeloAdministrador extends StatelessWidget {
  const _SeloAdministrador();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _corDestaque.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _corDestaque.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: _corDestaque),
          SizedBox(width: 6),
          Text(
            'Administrador',
            style: TextStyle(
              color: _corDestaque,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoUsinaAtiva extends StatelessWidget {
  const _CartaoUsinaAtiva({required this.painel});

  final PainelAdmin painel;

  @override
  Widget build(BuildContext context) {
    final usina = painel.usina;
    final mes = painel.resumoMes;
    final variacao = mes.variacaoPercentual;

    final eficiencia = mes.eficienciaPercentual;
    final baseEficiencia = switch (mes.eficienciaBase) {
      'capacidade' => 'vs. capacidade instalada',
      'historico' => 'vs. média dos meses anteriores',
      _ => null,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _corPrimaria,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _corPrimaria.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: _corDestaque),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usina.nome ?? 'Usina solar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (usina.localizacao != null &&
                        usina.localizacao!.isNotEmpty)
                      Text(
                        usina.localizacao!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8F9EB3),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              _EtiquetaStatusUsina(ativa: usina.ativa),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            mes.registrado
                ? 'Geração de ${mes.rotulo}'
                : 'Nenhum registro de geração ainda',
            style: const TextStyle(
              color: Color(0xFF8F9EB3),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mes.registrado
                    ? '${formatarNumeroBr(mes.geracaoKwh)} kWh'
                    : '—',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              if (variacao != null) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '${variacao >= 0 ? '▲' : '▼'} '
                    '${formatarNumeroBr(variacao.abs(), casas: 1)}% vs. mês anterior',
                    style: TextStyle(
                      color: variacao >= 0
                          ? const Color(0xFF7BD389)
                          : const Color(0xFFFF8A80),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Indicador(
                  icone: Icons.people_outline,
                  valor: '${painel.membros.ativos}',
                  rotulo: 'Membros ativos',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Indicador(
                  icone: Icons.speed_outlined,
                  valor: eficiencia == null
                      ? '—'
                      : '${formatarNumeroBr(eficiencia, casas: 1)}%',
                  rotulo: 'Eficiência',
                  detalhe: baseEficiencia,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EtiquetaStatusUsina extends StatelessWidget {
  const _EtiquetaStatusUsina({required this.ativa});

  final bool ativa;

  @override
  Widget build(BuildContext context) {
    final cor = ativa ? const Color(0xFF7BD389) : const Color(0xFFFF8A80);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ativa ? 'Ativa' : 'Inativa',
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.icone,
    required this.valor,
    required this.rotulo,
    this.detalhe,
  });

  final IconData icone;
  final String valor;
  final String rotulo;
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 15, color: _corDestaque),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  rotulo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8F9EB3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (detalhe != null)
            Text(
              detalhe!,
              style: const TextStyle(color: Color(0xFF8F9EB3), fontSize: 10),
            ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto, {this.contador});

  final String texto;
  final int? contador;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          texto,
          style: const TextStyle(
            color: _corPrimaria,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (contador != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _corDestaque,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$contador',
              style: const TextStyle(
                color: _corFundoEscuro,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.aoPressionar,
  });

  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback aoPressionar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: aoPressionar,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6E9EE)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _corPrimaria.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, color: _corPrimaria),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: _corPrimaria,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          color: _corTextoSecundario,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9AA2AF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoAlerta extends StatelessWidget {
  const _CartaoAlerta({required this.alerta});

  final AlertaPainel alerta;

  @override
  Widget build(BuildContext context) {
    final (fundo, borda, icone) = switch (alerta.severidade) {
      SeveridadeAlerta.erro => (
        const Color(0xFFFFECEB),
        const Color(0xFFD32F2F),
        Icons.error_outline,
      ),
      SeveridadeAlerta.aviso => (
        const Color(0xFFFFF4E0),
        const Color(0xFFE59828),
        Icons.warning_amber_rounded,
      ),
      SeveridadeAlerta.info => (
        const Color(0xFFE8F0FE),
        const Color(0xFF1A73E8),
        Icons.info_outline,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borda.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: borda, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.titulo,
                  style: const TextStyle(
                    color: _corPrimaria,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alerta.mensagem,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 12.5,
                    height: 1.3,
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

class _SemAlertas extends StatelessWidget {
  const _SemAlertas();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F1E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nenhum alerta ativo. Está tudo certo com a usina.',
              style: TextStyle(
                color: Color(0xFF1B4332),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoProximoLancamento extends StatelessWidget {
  const _CartaoProximoLancamento({
    required this.lancamento,
    required this.aoLancar,
  });

  final ProximoLancamentoPainel lancamento;
  final VoidCallback aoLancar;

  @override
  Widget build(BuildContext context) {
    final (cor, icone, descricao) = switch (lancamento.status) {
      StatusLancamento.atrasado => (
        const Color(0xFFD32F2F),
        Icons.event_busy_outlined,
        lancamento.mesesEmAtraso > 1
            ? '${lancamento.mesesEmAtraso} meses em atraso'
            : 'Lançamento em atraso',
      ),
      StatusLancamento.pendente => (
        const Color(0xFFE59828),
        Icons.event_available_outlined,
        'Pendente — já pode ser lançado',
      ),
      StatusLancamento.emDia => (
        const Color(0xFF2E7D32),
        Icons.event_repeat_outlined,
        lancamento.dataAbertura == null
            ? 'Registros em dia'
            : 'Em dia — abre em ${_formatarDiaMes(lancamento.dataAbertura)}',
      ),
    };
    final podeLancar = lancamento.status != StatusLancamento.emDia;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: cor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lancamento.rotulo,
                      style: const TextStyle(
                        color: _corPrimaria,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descricao,
                      style: TextStyle(
                        color: cor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (podeLancar) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: aoLancar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _corPrimaria,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Lançar agora',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BannerAviso extends StatelessWidget {
  const _BannerAviso({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD32F2F)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFFD32F2F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Não foi possível atualizar: $mensagem',
              style: const TextStyle(
                color: Color(0xFFB71C1C),
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

class _EstadoErro extends StatelessWidget {
  const _EstadoErro({required this.mensagem, required this.aoTentarNovamente});

  final String mensagem;
  final VoidCallback aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: Color(0xFF9AA2AF),
            ),
            const SizedBox(height: 12),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _corTextoSecundario,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: aoTentarNovamente,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
