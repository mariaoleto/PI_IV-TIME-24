import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/data/sessao_auth.dart';
import '../../geracao_creditos/domain/repositorio_energia.dart';
import '../data/modelos_relatorios.dart';

export '../data/modelos_relatorios.dart';

class ErroApiRelatorios implements Exception {
  ErroApiRelatorios(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

enum TipoRelatorioDocumento {
  relatorioMensal,
  extratoCreditos,
  demonstrativoAnual,
}

extension TipoRelatorioDocumentoExtensao on TipoRelatorioDocumento {
  String get valorApi {
    switch (this) {
      case TipoRelatorioDocumento.relatorioMensal:
        return 'relatorio_mensal';
      case TipoRelatorioDocumento.extratoCreditos:
        return 'extrato_creditos';
      case TipoRelatorioDocumento.demonstrativoAnual:
        return 'demonstrativo_anual';
    }
  }

  /// Segmento exato de rota exposto em `relatorios_routes.ts`.
  String get caminhoApi {
    switch (this) {
      case TipoRelatorioDocumento.relatorioMensal:
        return 'mensal';
      case TipoRelatorioDocumento.extratoCreditos:
        return 'extrato-creditos';
      case TipoRelatorioDocumento.demonstrativoAnual:
        return 'demonstrativo-anual';
    }
  }

  String get rotulo {
    switch (this) {
      case TipoRelatorioDocumento.relatorioMensal:
        return 'Relatório mensal';
      case TipoRelatorioDocumento.extratoCreditos:
        return 'Extrato de créditos';
      case TipoRelatorioDocumento.demonstrativoAnual:
        return 'Demonstrativo anual';
    }
  }
}

abstract class RepositorioRelatorios {
  Future<List<RelatorioDocumento>> buscarDocumentos();

  Future<bool> gerar({
    required TipoRelatorioDocumento tipo,
    String? referencia,
    int? ano,
  });

  Uri urlDownload(String relatorioId);

  Future<Uri> resolverUrlDownload(RelatorioDocumento relatorio) async {
    if (relatorio.arquivoUrl.startsWith('http://') ||
        relatorio.arquivoUrl.startsWith('https://')) {
      return Uri.parse(relatorio.arquivoUrl);
    }
    return urlDownload(relatorio.id);
  }

  Future<TelemetriaTcpRelatorios?> consultarTelemetriaTcp() async => null;
}

class RepositorioApiRelatorios extends RepositorioRelatorios {
  RepositorioApiRelatorios({String? urlBase, http.Client? clienteHttp})
    : _urlBase = urlBase ?? RepositorioApiEnergia.urlPadrao,
      _clienteHttp = clienteHttp ?? http.Client();

  final String _urlBase;
  final http.Client _clienteHttp;

  Map<String, String> get _cabecalhos => {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
    if (SessaoAuth.instancia.token != null)
      'Authorization': 'Bearer ${SessaoAuth.instancia.token}',
  };

  String _extrairMensagemErro(http.Response resposta, String padrao) {
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) {
        final msg = corpo['mensagem'] ?? corpo['message'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
    } catch (_) {}
    return padrao;
  }

  @override
  Future<List<RelatorioDocumento>> buscarDocumentos() async {
    final uri = Uri.parse('$_urlBase/relatorios');

    try {
      final resposta = await _clienteHttp
          .get(uri, headers: _cabecalhos)
          .timeout(const Duration(seconds: 8));
      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
        if (corpo is List) {
          return corpo
              .whereType<Map<String, dynamic>>()
              .map(RelatorioDocumento.deJson)
              .toList(growable: false);
        }
        throw ErroApiRelatorios('Formato inesperado na resposta de relatórios.');
      }

      throw ErroApiRelatorios(
        _extrairMensagemErro(
          resposta,
          'Não foi possível carregar os relatórios (${resposta.statusCode}).',
        ),
      );
    } on ErroApiRelatorios {
      rethrow;
    } catch (_) {
      throw ErroApiRelatorios(
        'Não foi possível conectar ao servidor para buscar os relatórios.',
      );
    }
  }

  @override
  Future<bool> gerar({
    required TipoRelatorioDocumento tipo,
    String? referencia,
    int? ano,
  }) async {
    final rota = '$_urlBase/relatorios/${tipo.caminhoApi}';

    try {
      final resposta = await _clienteHttp
          .post(
            Uri.parse(rota),
            headers: _cabecalhos,
            body: jsonEncode({
              if (referencia != null && referencia.isNotEmpty)
                'referencia': referencia,
              if (ano != null) 'ano': ano.toString(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        return true;
      }

      throw ErroApiRelatorios(
        _extrairMensagemErro(
          resposta,
          'Não foi possível gerar o relatório (${resposta.statusCode}).',
        ),
      );
    } on ErroApiRelatorios {
      rethrow;
    } catch (_) {
      throw ErroApiRelatorios(
        'Falha de conexão ao gerar relatório no servidor.',
      );
    }
  }

  @override
  Future<Uri> resolverUrlDownload(RelatorioDocumento relatorio) async {
    if (relatorio.arquivoUrl.startsWith('http://') ||
        relatorio.arquivoUrl.startsWith('https://')) {
      return Uri.parse(relatorio.arquivoUrl);
    }
    if (relatorio.id.isEmpty) {
      throw ErroApiRelatorios('Este documento ainda não está disponível.');
    }

    final uriTicket = Uri.parse('$_urlBase/relatorios/${relatorio.id}/ticket');
    try {
      final resposta = await _clienteHttp
          .get(uriTicket, headers: _cabecalhos)
          .timeout(const Duration(seconds: 8));
      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        final mapa = jsonDecode(utf8.decode(resposta.bodyBytes));
        if (mapa is Map<String, dynamic>) {
          final downloadUrl = mapa['download_url']?.toString();
          if (downloadUrl != null && downloadUrl.isNotEmpty) {
            return Uri.parse('$_urlBase$downloadUrl');
          }
        }
      }
      throw ErroApiRelatorios(
        _extrairMensagemErro(
          resposta,
          'Não foi possível autorizar o download do PDF (${resposta.statusCode}).',
        ),
      );
    } on ErroApiRelatorios {
      rethrow;
    } catch (_) {
      throw ErroApiRelatorios(
        'Falha de conexão ao solicitar download do relatório.',
      );
    }
  }

  @override
  Future<TelemetriaTcpRelatorios?> consultarTelemetriaTcp() async {
    try {
      final uri = Uri.parse('$_urlBase/energia/telemetria-tcp');
      final resposta = await _clienteHttp
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 3));
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) {
        return TelemetriaTcpRelatorios.deJson(corpo);
      }
    } catch (_) {}
    return const TelemetriaTcpRelatorios(online: false);
  }

  @override
  Uri urlDownload(String relatorioId) =>
      Uri.parse('$_urlBase/relatorios/$relatorioId/download');
}
