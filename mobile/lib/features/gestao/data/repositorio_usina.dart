// Autora: Marina Hehnes Espósito.
// Propósito: define e implementa as chamadas HTTP da gestão de usinas.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'modelos_usina.dart';

abstract interface class RepositorioUsina {
  Future<List<Usina>> listar();

  Future<Usina> criar(Usina usina);

  Future<Usina> atualizar(Usina usina);

  Future<void> excluir(String usinaId);

  Future<List<MembroUsina>> listarMembros(String usinaId);

  Future<MembroUsina> adicionarMembro({
    required String usinaId,
    required String nome,
    required String email,
  });

  Future<List<MembroUsina>> atualizarCotas(
    String usinaId,
    List<CotaAtualizacao> cotas,
  );

  Future<ContratoUsina?> buscarContrato(String usinaId);

  Future<ContratoUsina> salvarContrato(
    String usinaId,
    String nomeArquivo,
    Uint8List conteudo,
  );

  Future<void> excluirContrato(String usinaId);
}

class RepositorioApiUsina implements RepositorioUsina {
  RepositorioApiUsina({String? urlBase, http.Client? clienteHttp})
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
  Future<List<Usina>> listar() async {
    final resposta = await _requisicao(
      _clienteHttp.get(Uri.parse('$_urlBase/gestao/usinas')),
    );
    final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (dados is! List) {
      throw const RepositorioUsinaException(
        'A API retornou uma lista de usinas inválida.',
      );
    }
    return dados
        .whereType<Map<String, dynamic>>()
        .map(Usina.fromJson)
        .toList(growable: true);
  }

  @override
  Future<Usina> criar(Usina usina) async {
    final resposta = await _requisicao(
      _clienteHttp.post(
        Uri.parse('$_urlBase/gestao/usinas'),
        headers: _headersJson,
        body: jsonEncode(usina.toJson()),
      ),
    );
    return Usina.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }

  @override
  Future<Usina> atualizar(Usina usina) async {
    final resposta = await _requisicao(
      _clienteHttp.put(
        Uri.parse('$_urlBase/gestao/usinas/${usina.id}'),
        headers: _headersJson,
        body: jsonEncode(usina.toJson()),
      ),
    );
    return Usina.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> excluir(String usinaId) async {
    await _requisicao(
      _clienteHttp.delete(Uri.parse('$_urlBase/gestao/usinas/$usinaId')),
      codigosEsperados: const {204},
    );
  }

  @override
  Future<List<MembroUsina>> listarMembros(String usinaId) async {
    final resposta = await _requisicao(
      _clienteHttp.get(
        Uri.parse(
          '$_urlBase/gestao/membros',
        ).replace(queryParameters: {'usina_id': usinaId}),
      ),
    );
    final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (dados is! List) {
      throw const RepositorioUsinaException(
        'A API retornou uma lista de membros inválida.',
      );
    }
    return dados
        .whereType<Map<String, dynamic>>()
        .map(MembroUsina.fromJson)
        .toList(growable: true);
  }

  @override
  Future<MembroUsina> adicionarMembro({
    required String usinaId,
    required String nome,
    required String email,
  }) async {
    final resposta = await _requisicao(
      _clienteHttp.post(
        Uri.parse('$_urlBase/gestao/membros'),
        headers: _headersJson,
        body: jsonEncode({'nome': nome, 'email': email, 'usina_id': usinaId}),
      ),
    );
    return MembroUsina.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<MembroUsina>> atualizarCotas(
    String usinaId,
    List<CotaAtualizacao> cotas,
  ) async {
    final resposta = await _requisicao(
      _clienteHttp.put(
        Uri.parse('$_urlBase/gestao/usinas/$usinaId/cotas'),
        headers: _headersJson,
        body: jsonEncode({
          'cotas': cotas
              .map(
                (cota) => {
                  'membro_id': cota.membroId,
                  'percentual': cota.percentual,
                },
              )
              .toList(),
        }),
      ),
    );
    final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (dados is! List) {
      throw const RepositorioUsinaException(
        'A API retornou uma lista de cotas inválida.',
      );
    }
    return dados
        .whereType<Map<String, dynamic>>()
        .map(MembroUsina.fromJson)
        .toList(growable: true);
  }

  @override
  Future<ContratoUsina?> buscarContrato(String usinaId) async {
    final resposta = await _clienteHttp
        .get(Uri.parse('$_urlBase/gestao/usinas/$usinaId/contrato'))
        .timeout(const Duration(seconds: 10));
    if (resposta.statusCode == 404) {
      return null;
    }
    _validarResposta(resposta, const {200});
    return ContratoUsina.fromJson(
      jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>,
    );
  }

  @override
  Future<ContratoUsina> salvarContrato(
    String usinaId,
    String nomeArquivo,
    Uint8List conteudo,
  ) async {
    final requisicao =
        http.MultipartRequest(
            'POST',
            Uri.parse('$_urlBase/gestao/usinas/$usinaId/contrato'),
          )
          ..files.add(
            http.MultipartFile.fromBytes(
              'arquivo',
              conteudo,
              filename: nomeArquivo,
            ),
          );
    final resposta = await _clienteHttp
        .send(requisicao)
        .timeout(const Duration(seconds: 15));
    final corpo = await http.Response.fromStream(resposta);
    _validarResposta(corpo, const {201});
    return ContratoUsina.fromJson(
      jsonDecode(utf8.decode(corpo.bodyBytes)) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> excluirContrato(String usinaId) async {
    await _requisicao(
      _clienteHttp.delete(
        Uri.parse('$_urlBase/gestao/usinas/$usinaId/contrato'),
      ),
      codigosEsperados: const {204},
    );
  }

  Map<String, String> get _headersJson => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<http.Response> _requisicao(
    Future<http.Response> requisicao, {
    Set<int> codigosEsperados = const {200, 201},
  }) async {
    final resposta = await requisicao.timeout(const Duration(seconds: 10));
    _validarResposta(resposta, codigosEsperados);
    return resposta;
  }

  void _validarResposta(http.Response resposta, Set<int> codigosEsperados) {
    if (!codigosEsperados.contains(resposta.statusCode)) {
      final mensagem = _mensagemErro(resposta);
      throw RepositorioUsinaException(
        'A API da usina respondeu ${resposta.statusCode}: $mensagem',
      );
    }
  }

  String _mensagemErro(http.Response resposta) {
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) {
        return (corpo['message'] ?? corpo['mensagem'] ?? resposta.body)
            .toString();
      }
    } on FormatException {
      return resposta.body;
    }
    return resposta.body;
  }
}

class RepositorioUsinaException implements Exception {
  const RepositorioUsinaException(this.message);

  final String message;

  @override
  String toString() => message;
}
