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

  @override
  void initState() {
    super.initState();
    _carregarDocumentos();
  }

  void _carregarDocumentos() {
    _documentosFuturo = widget.repositorio.buscarDocumentos();
  }

  Future<void> _atualizar() async {
    setState(() {
      _carregarDocumentos();
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TelaEnergia(
              repositorio: RepositorioApiEnergia(),
              emailMembro: widget.emailMembro,
              aoPerfilAtualizado: widget.aoPerfilAtualizado,
              repositorioPerfil: widget.repositorioPerfil,
            ),
          ),
        );
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
    if (relatorio.arquivoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este documento ainda não está disponível.')),
      );
      return;
    }

    final uri = Uri.parse('${RepositorioApiEnergia.urlPadrao}${relatorio.arquivoUrl}');
    final podeAbrir = await canLaunchUrl(uri);
    if (!mounted) return;

    if (!podeAbrir) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o documento no momento.')),
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: FutureBuilder<List<RelatorioDocumento>>(
        future: _documentosFuturo,
        builder: (context, snapshot) {
          final documentos = snapshot.data ?? RelatorioDocumento.exemplo();

          return Scaffold(
            backgroundColor: const Color(0xFFB7B2C7),
            body: SafeArea(
              child: Center(
                child: Container(
                  width: 390,
                  height: 844,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF142340),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '9:41',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.signal_cellular_4_bar_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.wifi_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.battery_full_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Relatórios',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF7F7F9),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            children: [
                              _ResumoCards(documentos: documentos),
                              const SizedBox(height: 16),
                              Expanded(
                                child: _ListaDocumentos(
                                  documentos: documentos,
                                  onAbrir: _abrirDocumento,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 76,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                        ),
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
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
            valorExato: resumo.totalGeracaoKwh,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ResumoCard(
            titulo: 'Economia anual',
            valor: 'R\$ ${formatarNumero(resumo.economiaAnualReais)}',
            valorExato: resumo.economiaAnualReais,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ResumoCard(
            titulo: 'CO₂ evitado',
            valor: '${formatarNumero(resumo.co2EvitadoKg)} kg',
            valorExato: resumo.co2EvitadoKg,
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
    required this.valorExato,
  });

  final String titulo;
  final String valor;
  final double valorExato;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E7ED), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            valor,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF142340),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF6C7686),
              fontSize: 12,
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
    final lista = documentos.isEmpty ? RelatorioDocumento.exemplo() : documentos;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: ListView.separated(
        itemCount: lista.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final relatorio = lista[index];
          final titulo = relatorio.titulo;
          final data = relatorio.referencia;
          final tamanho = relatorio.formatacaoMb;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onAbrir(relatorio),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
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
                          titulo,
                          style: const TextStyle(
                            color: Color(0xFF1A2237),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data,
                          style: TextStyle(
                            color: const Color(0xFF7A869B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    tamanho,
                    style: TextStyle(
                      color: const Color(0xFF7A869B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 30,
                    height: 30,
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
    final corAtiva = const Color(0xFF142340);
    final corInativa = const Color(0xFF7A869B);

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
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              texto,
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
