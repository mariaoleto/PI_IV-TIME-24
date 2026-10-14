// autora: Maria Júlia Lazarini Oleto

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'modelos_energia.dart';

abstract class RepositorioEnergia {
  Future<ResumoEnergia> buscarResumo({
    int? ano,
    String? usinaId,
    String? membroId,
  });

  Future<List<CotaMembro>> buscarCotasDistribuicao({String? usinaId});

  Future<bool> salvarLancamentoMensal({
    required String mesReferencia,
    required double geracaoKwh,
    String? usinaId,
  });
}

class RepositorioApiEnergia implements RepositorioEnergia {
  RepositorioApiEnergia({String? urlBase, http.Client? clienteHttp})
    : _urlBase = urlBase ?? urlPadrao,
      _clienteHttp = clienteHttp ?? http.Client();

  final String _urlBase;
  final http.Client _clienteHttp;

  static String get urlPadrao {
    const configurada = String.fromEnvironment('SOLIS_URL_API');
    if (configurada.isNotEmpty) {
      return configurada;
    }

    // No emulador Android, o localhost do computador hospedeiro é 10.0.2.2
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    // No navegador Web (Chrome/Edge), desktop ou simulador iOS
    return 'http://localhost:3000';
  }

  // busca os dados mensais de geracao, consumo, saldo e economia
  // para os gráficos e exibição na tela de resumo
  @override
  Future<ResumoEnergia> buscarResumo({
    int? ano,
    String? usinaId,
    String? membroId,
  }) async {
    final anoAtual = ano ?? DateTime.now().year;
    final parametros = <String, String>{'ano': anoAtual.toString()};

    if (usinaId != null && usinaId.isNotEmpty) {
      parametros['usina_id'] = usinaId;
    }
    if (membroId != null && membroId.isNotEmpty) {
      parametros['membro_id'] = membroId;
    }

    final uri = Uri.parse(
      '$_urlBase/energia',
    ).replace(queryParameters: parametros);

    try {
      final resposta = await _clienteHttp.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        final mapa = jsonDecode(utf8.decode(resposta.bodyBytes));
        return ResumoEnergia.deJson(mapa as Map<String, dynamic>);
      }

      debugPrint('Aviso API Solis: status ${resposta.statusCode}');
      return ResumoEnergia.exemplo();
    } catch (erro) {
      debugPrint('Falha ao conectar na API Solis ($uri): $erro');
      return ResumoEnergia.exemplo();
    }
  }

  // busca as cotas da usina com os nomes dos membros para a prévia
  @override
  Future<List<CotaMembro>> buscarCotasDistribuicao({String? usinaId}) async {
    final parametros = <String, String>{};
    if (usinaId != null && usinaId.isNotEmpty) {
      parametros['usina_id'] = usinaId;
    }
    final uri = Uri.parse(
      '$_urlBase/energia/cotas',
    ).replace(queryParameters: parametros.isEmpty ? null : parametros);
    try {
      final resposta = await _clienteHttp.get(
        uri,
        headers: {'Accept': 'application/json'},
      );
      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        final lista = jsonDecode(utf8.decode(resposta.bodyBytes));
        if (lista is List) {
          return lista
              .whereType<Map<String, dynamic>>()
              .map(CotaMembro.deJson)
              .toList(growable: false);
        }
      }
      debugPrint('Aviso API Cotas: status ${resposta.statusCode}');
      return const [];
    } catch (erro) {
      debugPrint('Falha ao buscar cotas na API Solis ($uri): $erro');
      return const [];
    }
  }

  // envia os dados para salvar a geração e distribuir os créditos
  @override
  Future<bool> salvarLancamentoMensal({
    required String mesReferencia,
    required double geracaoKwh,
    String? usinaId,
  }) async {
    final uri = Uri.parse('$_urlBase/energia/lancamento');
    try {
      final resposta = await _clienteHttp.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'mes_referencia': mesReferencia,
          'geracao_kwh': geracaoKwh,
          if (usinaId != null && usinaId.isNotEmpty) 'usina_id': usinaId,
        }),
      );
      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        return true;
      }
      debugPrint(
        'Erro ao salvar lançamento: status ${resposta.statusCode} - ${resposta.body}',
      );
      return false;
    } catch (erro) {
      debugPrint('Falha na requisição de lançamento ($uri): $erro');
      return false;
    }
  }
}
