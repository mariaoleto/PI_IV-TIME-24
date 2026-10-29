// significado do arquivo: interface e implementação HTTP do painel administrativo

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../geracao_creditos/domain/repositorio_energia.dart';
import '../data/modelos_painel_admin.dart';
export '../data/modelos_painel_admin.dart';

abstract class RepositorioPainelAdmin {
  // lança [Exception] com mensagem amigável se o painel não puder ser carregado
  Future<PainelAdmin> buscarPainel({String? usinaId});
}

class RepositorioApiPainelAdmin implements RepositorioPainelAdmin {
  RepositorioApiPainelAdmin({String? urlBase, http.Client? clienteHttp})
    : _urlBase = urlBase ?? RepositorioApiEnergia.urlPadrao,
      _clienteHttp = clienteHttp ?? http.Client();

  final String _urlBase;
  final http.Client _clienteHttp;

  @override
  Future<PainelAdmin> buscarPainel({String? usinaId}) async {
    final uri = Uri.parse('$_urlBase/admin/painel').replace(
      queryParameters: usinaId != null && usinaId.isNotEmpty
          ? {'usina_id': usinaId}
          : null,
    );

    final http.Response resposta;
    try {
      resposta = await _clienteHttp
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw Exception(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }

    if (resposta.statusCode == 404) {
      throw Exception('Nenhuma usina cadastrada ainda.');
    }
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw Exception('O servidor não conseguiu carregar o painel.');
    }

    try {
      final mapa = jsonDecode(utf8.decode(resposta.bodyBytes));
      return PainelAdmin.deJson(mapa as Map<String, dynamic>);
    } catch (_) {
      throw Exception('Resposta inesperada do servidor.');
    }
  }
}
