// autora: Maria Júlia Lazarini Oleto
// significado do arquivo:
// interface e implementação do repositório de dados do painel do membro

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/modelos_painel_membro.dart';
export '../data/modelos_painel_membro.dart';

// dados utilizados no painel
abstract class RepositorioPainelMembro {
  Future<DadosPainelMembro> buscarDashboard({
    String? membroId,
    String? email,
    String? usinaId,
    int? ano,
  });
}

// busca os dados do painel
class RepositorioApiPainelMembro implements RepositorioPainelMembro {
  RepositorioApiPainelMembro({String? urlBase, http.Client? clienteHttp})
    : _urlBase = urlBase ?? urlPadrao,
      _clienteHttp = clienteHttp ?? http.Client();

  final String _urlBase;
  final http.Client _clienteHttp;

  static String get urlPadrao {
    const configurada = String.fromEnvironment('SOLIS_URL_API');
    if (configurada.isNotEmpty) {
      return configurada;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  @override
  Future<DadosPainelMembro> buscarDashboard({
    String? membroId,
    String? email,
    String? usinaId,
    int? ano,
  }) async {
    final parametros = <String, String>{};
    if (ano != null) parametros['ano'] = ano.toString();
    if (membroId != null && membroId.isNotEmpty) {
      parametros['membro_id'] = membroId;
    }
    if (email != null && email.isNotEmpty) {
      parametros['email'] = email;
    }
    if (usinaId != null && usinaId.isNotEmpty) {
      parametros['usina_id'] = usinaId;
    }

    final uri = Uri.parse(
      '$_urlBase/painel-membro',
    ).replace(queryParameters: parametros.isEmpty ? null : parametros);

    try {
      final resposta = await _clienteHttp.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        final mapa = jsonDecode(utf8.decode(resposta.bodyBytes));
        return DadosPainelMembro.deJson(mapa as Map<String, dynamic>);
      }

      debugPrint('Aviso API Painel Membro: status ${resposta.statusCode}');
      return DadosPainelMembro.exemplo();
    } catch (erro) {
      debugPrint('Falha ao conectar na API do Painel ($uri): $erro');
      return DadosPainelMembro.exemplo();
    }
  }
}
