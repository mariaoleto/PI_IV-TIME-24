import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../geracao_creditos/domain/repositorio_energia.dart';
import '../../geracao_creditos/presentation/tela_energia.dart';
import '../../painel_membro/domain/repositorio_painel_membro.dart';
import '../../painel_membro/presentation/tela_painel_membro.dart';
import '../../perfil/domain/repositorio_perfil.dart';
import '../../perfil/presentation/tela_perfil.dart';
import '../domain/repositorio_relatorios.dart';

class TelaRelatorios extends StatefulWidget {
  const TelaRelatorios({
    super.key,
    required this.repositorio,
    this.emailMembro,
    this.aoPerfilAtualizado,
    this.repositorioPerfil,
  });

  final RepositorioRelatorios repositorio;
  final String? emailMembro;
  final ValueChanged<PerfilMembro>? aoPerfilAtualizado;
  final RepositorioPerfil? repositorioPerfil;

  @override
  State<TelaRelatorios> createState() => _EstadoTelaRelatorios();
}

class _EstadoTelaRelatorios extends State<TelaRelatorios> {
  late Future<List<RelatorioDocumento>> _documentosFuturo;
  TelemetriaTcpRelatorios? _telemetriaTcp;
  bool _carregandoTelemetria = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    _documentosFuturo = widget.repositorio.buscarDocumentos();
    _carregarTelemetria();
  }

  Future<void> _carregarTelemetria() async {
    if (mounted) {
      setState(() => _carregandoTelemetria = true);
    }
    final telemetria = await widget.repositorio.consultarTelemetriaTcp();
    if (!mounted) return;
    setState(() {
      _telemetriaTcp = telemetria;
      _carregandoTelemetria = false;
    });
  }

  Future<void> _atualizar() async {
    setState(() {
      _carregarDados();
    });
    await _documentosFuturo;
  }

  void _aoSelecionarAbaInferior(int indice) {
    switch (indice) {
      case 0:
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TelaPainelMembro(
                repositorio: RepositorioApiPainelMembro(),
                emailMembro: widget.emailMembro,
              ),
            ),
          );
        }
        return;
      case 1:
        final rota = MaterialPageRoute(
          builder: (_) => TelaEnergia(
            repositorio: RepositorioApiEnergia(),
            emailMembro: widget.emailMembro,
            aoPerfilAtualizado: widget.aoPerfilAtualizado,
            repositorioPerfil: widget.repositorioPerfil,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pushReplacement(rota);
        } else {
          Navigator.of(context).push(rota);
        }
        return;
      case 3:
        abrirTelaPerfil(
          context,
          email: widget.emailMembro,
          aoPerfilAtualizado: widget.aoPerfilAtualizado,
          repositorio: widget.repositorioPerfil,
        );
        return;
      default:
        break;
    }
  }

  Future<void> _abrirDocumento(RelatorioDocumento relatorio) async {
    if (relatorio.arquivoUrl.isEmpty && relatorio.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este documento ainda não está disponível.')),
      );
      return;
    }

    try {
      final uri = await widget.repositorio.resolverUrlDownload(relatorio);
      final podeAbrir = await canLaunchUrl(uri);
      if (!mounted) return;

      if (!podeAbrir) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o documento no momento.'),
          ),
        );
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on ErroApiRelatorios catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.mensagem)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao preparar o download do relatório.'),
        ),
      );
    }
  }

  Future<void> _abrirDialogoGerarRelatorio() async {
    final gerou = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoGerarRelatorio(repositorio: widget.repositorio),
    );
    if (gerou == true && mounted) {
      await _atualizar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Relatório gerado com sucesso!'),
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
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F9),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF142340),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Relatórios',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF4A12B),
                          foregroundColor: const Color(0xFF142340),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onPressed: _abrirDialogoGerarRelatorio,
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        label: const Text(
                          'Gerar PDF',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<RelatorioDocumento>>(
                future: _documentosFuturo,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF142340),
                      ),
                    );
                  }

                  final documentos = snapshot.data ?? const <RelatorioDocumento>[];
                  final erro = snapshot.error;

                  return RefreshIndicator(
                    onRefresh: _atualizar,
                    color: const Color(0xFF142340),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _CartaoTelemetriaRelatorios(
                          telemetria: _telemetriaTcp,
                          carregando: _carregandoTelemetria,
                          onAtualizar: _carregarTelemetria,
                        ),
                        const SizedBox(height: 12),
                        if (erro != null)
                          _EstadoErroRelatorios(
                            mensagem: erro.toString(),
                            onTentarNovamente: _atualizar,
                          )
                        else ...[
                          _ResumoCards(documentos: documentos),
                          const SizedBox(height: 16),
                          if (documentos.isEmpty)
                            _EstadoVazioRelatorios(
                              onGerar: _abrirDialogoGerarRelatorio,
                            )
                          else
                            _ListaDocumentos(
                              documentos: documentos,
                              onAbrir: _abrirDocumento,
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ItemNavegacao(
                        icon: Icons.home_outlined,
                        texto: 'Início',
                        ativo: false,
                        onTap: () => _aoSelecionarAbaInferior(0),
                      ),
                      _ItemNavegacao(
                        icon: Icons.bolt_outlined,
                        texto: 'Energia',
                        ativo: false,
                        onTap: () => _aoSelecionarAbaInferior(1),
                      ),
                      _ItemNavegacao(
                        icon: Icons.description_outlined,
                        texto: 'Relatórios',
                        ativo: true,
                        onTap: () => _aoSelecionarAbaInferior(2),
                      ),
                      _ItemNavegacao(
                        icon: Icons.person_outline,
                        texto: 'Perfil',
                        ativo: false,
                        onTap: () => _aoSelecionarAbaInferior(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoTelemetriaRelatorios extends StatelessWidget {
  const _CartaoTelemetriaRelatorios({
    required this.telemetria,
    required this.carregando,
    required this.onAtualizar,
  });

  final TelemetriaTcpRelatorios? telemetria;
  final bool carregando;
  final VoidCallback onAtualizar;

  @override
  Widget build(BuildContext context) {
    final online = telemetria?.online ?? false;
    final detalhes = online
        ? [
            telemetria?.usina ?? 'Solis_1',
            if (telemetria?.geracaoAtual != null) telemetria!.geracaoAtual!,
            if (telemetria?.tensao != null) telemetria!.tensao!,
          ].join(' · ')
        : (carregando
              ? 'Consultando servidor TCP Java...'
              : 'Servidor TCP Java indisponível (porta 5050)');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E7ED)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sensors_rounded,
            size: 20,
            color: online ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dados via Servidor TCP',
                  style: TextStyle(
                    color: Color(0xFF6C7686),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detalhes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF142340),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Atualizar telemetria TCP',
            onPressed: onAtualizar,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: Color(0xFF142340),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoVazioRelatorios extends StatelessWidget {
  const _EstadoVazioRelatorios({required this.onGerar});

  final VoidCallback onGerar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E7ED)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 40,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum relatório gerado ainda',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF142340),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gere seu relatório mensal, extrato de créditos ou demonstrativo anual com os cálculos e telemetria do servidor TCP.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6C7686), fontSize: 13),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onGerar,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Gerar primeiro relatório'),
          ),
        ],
      ),
    );
  }
}

class _EstadoErroRelatorios extends StatelessWidget {
  const _EstadoErroRelatorios({
    required this.mensagem,
    required this.onTentarNovamente,
  });

  final String mensagem;
  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 36,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 10),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF142340),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142340),
              foregroundColor: Colors.white,
            ),
            onPressed: onTentarNovamente,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _ResumoCards extends StatelessWidget {
  const _ResumoCards({required this.documentos});

  final List<RelatorioDocumento> documentos;

  @override
  Widget build(BuildContext context) {
    final resumo = RelatorioResumo.fromLista(documentos);

    return Row(
      children: [
        Expanded(
          child: _ResumoCard(
            titulo: 'Geração total',
            valor: '${formatarNumero(resumo.totalGeracaoKwh)} kWh',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ResumoCard(
            titulo: 'Economia anual',
            valor: 'R\$ ${formatarNumero(resumo.economiaAnualReais)}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ResumoCard(
            titulo: 'CO₂ evitado',
            valor: '${formatarNumero(resumo.co2EvitadoKg)} kg',
          ),
        ),
      ],
    );
  }
}

class _ResumoCard extends StatelessWidget {
  const _ResumoCard({
    required this.titulo,
    required this.valor,
  });

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E7ED), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF142340),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            titulo,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6C7686),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaDocumentos extends StatelessWidget {
  const _ListaDocumentos({
    required this.documentos,
    required this.onAbrir,
  });

  final List<RelatorioDocumento> documentos;
  final Future<void> Function(RelatorioDocumento) onAbrir;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E7ED)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: documentos.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          indent: 14,
          endIndent: 14,
          color: Color(0xFFF1F5F9),
        ),
        itemBuilder: (context, index) {
          final relatorio = documentos[index];
          final usouTcp =
              relatorio.origemDadosTcp.contains('TCP') ||
              (relatorio.telemetriaTcp?.online ?? false);

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onAbrir(relatorio),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Color(0xFF6C7686),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          relatorio.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1A2237),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          usouTcp
                              ? '${relatorio.referencia} · via TCP Java'
                              : relatorio.referencia,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7A869B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    relatorio.formatacaoMb,
                    style: const TextStyle(
                      color: Color(0xFF7A869B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: Color(0xFF1E3A5F),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ItemNavegacao extends StatelessWidget {
  const _ItemNavegacao({
    required this.icon,
    required this.texto,
    required this.ativo,
    required this.onTap,
  });

  final IconData icon;
  final String texto;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const corAtiva = Color(0xFF142340);
    const corInativa = Color(0xFF7A869B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: ativo ? corAtiva : corInativa,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ativo ? corAtiva : corInativa,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogoGerarRelatorio extends StatefulWidget {
  const _DialogoGerarRelatorio({required this.repositorio});

  final RepositorioRelatorios repositorio;

  @override
  State<_DialogoGerarRelatorio> createState() => _EstadoDialogoGerarRelatorio();
}

class _EstadoDialogoGerarRelatorio extends State<_DialogoGerarRelatorio> {
  late final TextEditingController _controladorPeriodo;
  TipoRelatorioDocumento _tipoSelecionado =
      TipoRelatorioDocumento.relatorioMensal;
  bool _gerando = false;
  String? _erroFormulario;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _controladorPeriodo = TextEditingController(
      text: '${agora.year}-${agora.month.toString().padLeft(2, '0')}',
    );
  }

  @override
  void dispose() {
    _controladorPeriodo.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    final ehAnual =
        _tipoSelecionado == TipoRelatorioDocumento.demonstrativoAnual;
    final valor = _controladorPeriodo.text.trim();

    if (ehAnual && !RegExp(r'^\d{4}$').hasMatch(valor)) {
      setState(() => _erroFormulario = 'Informe o ano com 4 dígitos.');
      return;
    }
    if (!ehAnual && !RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(valor)) {
      setState(() => _erroFormulario = 'Use o formato AAAA-MM.');
      return;
    }

    setState(() {
      _gerando = true;
      _erroFormulario = null;
    });

    try {
      await widget.repositorio.gerar(
        tipo: _tipoSelecionado,
        referencia: ehAnual ? null : valor,
        ano: ehAnual ? int.parse(valor) : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ErroApiRelatorios catch (erro) {
      if (!mounted) return;
      setState(() {
        _gerando = false;
        _erroFormulario = erro.mensagem;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gerando = false;
        _erroFormulario = 'Não foi possível gerar o relatório.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final ehAnual =
        _tipoSelecionado == TipoRelatorioDocumento.demonstrativoAnual;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: const Text(
        'Gerar relatório PDF',
        style: TextStyle(
          color: Color(0xFF142340),
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Os créditos e a telemetria da usina são consultados no servidor TCP Java.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TipoRelatorioDocumento>(
              initialValue: _tipoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Tipo de relatório',
                border: OutlineInputBorder(),
              ),
              items: TipoRelatorioDocumento.values
                  .map(
                    (tipo) => DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo.rotulo),
                    ),
                  )
                  .toList(),
              onChanged: _gerando
                  ? null
                  : (novoTipo) {
                      if (novoTipo == null) return;
                      setState(() {
                        _tipoSelecionado = novoTipo;
                        _erroFormulario = null;
                        if (novoTipo ==
                            TipoRelatorioDocumento.demonstrativoAnual) {
                          _controladorPeriodo.text = '${agora.year}';
                        } else if (!RegExp(r'^\d{4}-\d{2}$')
                            .hasMatch(_controladorPeriodo.text)) {
                          _controladorPeriodo.text =
                              '${agora.year}-${agora.month.toString().padLeft(2, '0')}';
                        }
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controladorPeriodo,
              enabled: !_gerando,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: ehAnual
                    ? 'Ano (AAAA)'
                    : 'Mês de referência (AAAA-MM)',
                hintText: ehAnual ? '2026' : '2026-09',
                errorText: _erroFormulario,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _gerando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF142340),
            foregroundColor: Colors.white,
          ),
          onPressed: _gerando ? null : _submeter,
          child: Text(_gerando ? 'Gerando...' : 'Gerar PDF'),
        ),
      ],
    );
  }
}
