//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// tela "Contrato do consórcio" (somente visualização):
// status, partes, condições (cota, tarifa, datas), cláusulas e observações

import 'package:flutter/material.dart';

import '../../auth/presentation/widgets_auth.dart';
import '../domain/formatadores_perfil.dart';
import '../domain/repositorio_perfil.dart';
import 'widgets_perfil.dart';

class TelaContrato extends StatefulWidget {
  const TelaContrato({
    super.key,
    required this.repositorio,
    required this.membroId,
  });

  final RepositorioPerfil repositorio;
  final String membroId;

  @override
  State<TelaContrato> createState() => _EstadoTelaContrato();
}

class _EstadoTelaContrato extends State<TelaContrato> {
  ContratoConsorcio? _contrato;
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
      final contrato = await widget.repositorio.buscarContrato(widget.membroId);
      if (!mounted) return;
      setState(() {
        _contrato = contrato;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = mensagemDeErro(erro);
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return EstruturaAuth(
      cabecalho: const Align(
        alignment: Alignment.centerLeft,
        child: CabecalhoTelaInterna(titulo: 'Contrato do consórcio'),
      ),
      conteudo: _montarConteudo(),
    );
  }

  Widget _montarConteudo() {
    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: corPrimaria)),
      );
    }
    if (_erro != null) {
      return EstadoErro(mensagem: _erro!, aoTentar: _carregar);
    }
    final contrato = _contrato;
    if (contrato == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.description_outlined, size: 42, color: Color(0xFF9AA2AF)),
            SizedBox(height: 12),
            Text(
              'Você ainda não possui um contrato registrado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
            ),
          ],
        ),
      );
    }
    return _ConteudoContrato(contrato: contrato);
  }
}

class _ConteudoContrato extends StatelessWidget {
  const _ConteudoContrato({required this.contrato});

  final ContratoConsorcio contrato;

  @override
  Widget build(BuildContext context) {
    final vigencia = contrato.vigenciaMeses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                contrato.numero != null
                    ? 'Contrato ${contrato.numero}'
                    : 'Contrato do consórcio',
                style: const TextStyle(
                  color: corPrimaria,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _SeloStatus(status: contrato.status),
          ],
        ),
        const SizedBox(height: 16),
        CartaoPerfil(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloSecao('Partes'),
              _LinhaContrato('Membro', contrato.nomeMembro),
              _LinhaContrato('E-mail', contrato.emailMembro),
              _LinhaContrato(
                'Usina',
                contrato.nomeUsina == null
                    ? '—'
                    : (contrato.localizacaoUsina == null
                          ? contrato.nomeUsina!
                          : '${contrato.nomeUsina} · ${contrato.localizacaoUsina}'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CartaoPerfil(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloSecao('Condições'),
              _LinhaContrato('Cota', formatarPercentual(contrato.cotaPercentual)),
              _LinhaContrato('Tarifa', formatarTarifa(contrato.tarifaKwh)),
              _LinhaContrato('Assinatura', formatarData(contrato.dataAssinatura)),
              _LinhaContrato('Início', formatarData(contrato.dataInicio)),
              _LinhaContrato('Término', formatarData(contrato.dataFim)),
              if (vigencia != null) _LinhaContrato('Vigência', '$vigencia meses'),
            ],
          ),
        ),
        if (contrato.clausulas.isNotEmpty) ...[
          const SizedBox(height: 14),
          CartaoPerfil(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloSecao('Cláusulas'),
                for (final clausula in contrato.clausulas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (clausula.titulo.isNotEmpty)
                          Text(
                            clausula.titulo,
                            style: const TextStyle(
                              color: corPrimaria,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (clausula.texto.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            clausula.texto,
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (contrato.observacoes != null) ...[
          const SizedBox(height: 14),
          CartaoPerfil(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloSecao('Observações'),
                Text(
                  contrato.observacoes!,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (contrato.arquivoUrl != null) ...[
          const SizedBox(height: 14),
          CartaoPerfil(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloSecao('Documento assinado'),
                SelectableText(
                  contrato.arquivoUrl!,
                  style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LinhaContrato extends StatelessWidget {
  const _LinhaContrato(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              rotulo,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                color: corPrimaria,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeloStatus extends StatelessWidget {
  const _SeloStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (rotulo, cor) = switch (status.toLowerCase()) {
      'ativo' => ('Ativo', const Color(0xFF1F8F4E)),
      'pendente' => ('Pendente', const Color(0xFFB7791F)),
      'encerrado' => ('Encerrado', const Color(0xFF6B7280)),
      'cancelado' => ('Cancelado', const Color(0xFFC53030)),
      _ => (status, const Color(0xFF6B7280)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        rotulo,
        style: TextStyle(color: cor, fontSize: 12.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}
