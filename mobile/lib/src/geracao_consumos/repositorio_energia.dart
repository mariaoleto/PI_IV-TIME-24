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
}

class RepositorioApiEnergia implements RepositorioEnergia {
  RepositorioApiEnergia({
    String? urlBase,
    http.Client? clienteHttp,
  })  : _urlBase = urlBase ?? urlPadrao,
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

  @override
  Future<ResumoEnergia> buscarResumo({
    int? ano,
    String? usinaId,
    String? membroId,
  }) async {
    final anoAtual = ano ?? DateTime.now().year;
    final parametros = <String, String>{
      'ano': anoAtual.toString(),
    };

    if (usinaId != null && usinaId.isNotEmpty) {
      parametros['usina_id'] = usinaId;
    }
    if (membroId != null && membroId.isNotEmpty) {
      parametros['membro_id'] = membroId;
    }

    final uri = Uri.parse('$_urlBase/energia').replace(
      queryParameters: parametros,
    );

    try {
      final resposta = await _clienteHttp.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
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
}
