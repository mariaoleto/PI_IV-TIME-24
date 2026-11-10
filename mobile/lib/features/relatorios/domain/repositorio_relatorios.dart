import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/data/sessao_auth.dart';
import '../../geracao_creditos/domain/repositorio_energia.dart';
import '../data/modelos_relatorios.dart';

export '../data/modelos_relatorios.dart';

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
}

class RepositorioApiRelatorios implements RepositorioRelatorios {
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

  @override
  Future<List<RelatorioDocumento>> buscarDocumentos() async {
    final uri = Uri.parse('$_urlBase/relatorios');

    try {
      final resposta = await _clienteHttp.get(uri, headers: _cabecalhos);
      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
        if (corpo is List) {
          return corpo
              .whereType<Map<String, dynamic>>()
              .map(RelatorioDocumento.deJson)
              .toList(growable: false);
        }
      }

      debugPrint('Aviso Relatórios: status ${resposta.statusCode}');
      return RelatorioDocumento.exemplo();
    } catch (erro) {
      debugPrint('Falha ao buscar relatórios: $erro');
      return RelatorioDocumento.exemplo();
    }
  }

  @override
  Future<bool> gerar({
    required TipoRelatorioDocumento tipo,
    String? referencia,
    int? ano,
  }) async {
    final rota = '$_urlBase/relatorios/${tipo.valorApi}';

    try {
      final resposta = await _clienteHttp.post(
        Uri.parse(rota),
        headers: _cabecalhos,
        body: jsonEncode({
          if (referencia != null && referencia.isNotEmpty) 'referencia': referencia,
          if (ano != null) 'ano': ano.toString(),
        }),
      );

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        return true;
      }

      debugPrint('Erro ao gerar relatório ${tipo.valorApi}: ${resposta.statusCode}');
      return false;
    } catch (erro) {
      debugPrint('Falha ao gerar relatório ${tipo.valorApi}: $erro');
      return false;
    }
  }

  @override
  Uri urlDownload(String relatorioId) =>
      Uri.parse('$_urlBase/relatorios/$relatorioId/download');
}
