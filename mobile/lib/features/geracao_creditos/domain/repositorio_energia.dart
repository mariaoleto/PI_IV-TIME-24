// autora: Maria Júlia Lazarini Oleto
// RA: 25006031

// significado do arquivo: interface que define as operações de energia

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/data/sessao_auth.dart';
import '../data/modelos_energia.dart';
export '../data/modelos_energia.dart';

abstract class RepositorioEnergia {
  Future<ResumoEnergia> buscarResumo({
    int? ano,
    String? usinaId,
    String? membroId,
    String? email,
  });

  Future<List<CotaMembro>> buscarCotasDistribuicao({String? usinaId});

  Future<bool> salvarLancamentoMensal({
    required String mesReferencia,
    required double geracaoKwh,
    String? usinaId,
  });

  Future<bool> salvarConsumoMensal({
    required String mesReferencia,
    required double consumoKwh,
    String? membroId,
    String? email,
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

  Map<String, String> get _cabecalhos => {
    'Accept': 'application/json',
    if (SessaoAuth.instancia.token != null)
      'Authorization': 'Bearer ${SessaoAuth.instancia.token}',
  };

  // busca os dados mensais de geracao, consumo, saldo e economia
  // para os gráficos e exibição na tela de resumo
  @override
  Future<ResumoEnergia> buscarResumo({
    int? ano,
    String? usinaId,
    String? membroId,
    String? email,
  }) async {
    final anoAtual = ano ?? DateTime.now().year;
    final parametros = <String, String>{'ano': anoAtual.toString()};

    final membroEfetivo =
        (membroId != null && membroId.isNotEmpty)
            ? membroId
            : SessaoAuth.instancia.usuario?.id;
    final emailEfetivo =
        (email != null && email.isNotEmpty)
            ? email
            : SessaoAuth.instancia.usuario?.email;

    if (usinaId != null && usinaId.isNotEmpty) {
      parametros['usina_id'] = usinaId;
    }
    if (membroEfetivo != null && membroEfetivo.isNotEmpty) {
      parametros['membro_id'] = membroEfetivo;
    }
    if (emailEfetivo != null && emailEfetivo.isNotEmpty) {
      parametros['email'] = emailEfetivo;
    }

    final uri = Uri.parse(
      '$_urlBase/energia',
    ).replace(queryParameters: parametros);

    try {
      final resposta = await _clienteHttp.get(
        uri,
        headers: _cabecalhos,
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
          ..._cabecalhos,
          'Content-Type': 'application/json',
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

  // envia o consumo mensal do membro para cálculo de saldo e economia
  @override
  Future<bool> salvarConsumoMensal({
    required String mesReferencia,
    required double consumoKwh,
    String? membroId,
    String? email,
    String? usinaId,
  }) async {
    final uri = Uri.parse('$_urlBase/energia/consumo');
    final membroEfetivo =
        (membroId != null && membroId.isNotEmpty)
            ? membroId
            : SessaoAuth.instancia.usuario?.id;
    final emailEfetivo =
        (email != null && email.isNotEmpty)
            ? email
            : SessaoAuth.instancia.usuario?.email;

    try {
      final resposta = await _clienteHttp.post(
        uri,
        headers: {
          ..._cabecalhos,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'mes_referencia': mesReferencia,
          'consumo_kwh': consumoKwh,
          if (membroEfetivo != null && membroEfetivo.isNotEmpty)
            'membro_id': membroEfetivo,
          if (emailEfetivo != null && emailEfetivo.isNotEmpty)
            'email': emailEfetivo,
          if (usinaId != null && usinaId.isNotEmpty) 'usina_id': usinaId,
        }),
      );
      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        return true;
      }
      debugPrint(
        'Erro ao salvar consumo: status ${resposta.statusCode} - ${resposta.body}',
      );
      return false;
    } catch (erro) {
      debugPrint('Falha na requisição de consumo ($uri): $erro');
      return false;
    }
  }
}
