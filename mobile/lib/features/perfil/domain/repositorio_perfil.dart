//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// interface e implementação HTTP do repositório de Perfil do membro
// endpoints (backend Node):
//   GET /perfil?email=...        -> perfil + card do consórcio
//   PUT /perfil/:id              -> editar nome, e-mail e telefone
//   PUT /perfil/:id/senha        -> alterar senha
//   GET /perfil/:id/contrato     -> contrato do consórcio

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/data/sessao_auth.dart';
import '../../geracao_creditos/domain/repositorio_energia.dart';
import '../data/modelos_perfil.dart';
export '../data/modelos_perfil.dart';

// erro com mensagem amigável para mostrar na tela
// [campos] traz o erro de cada campo quando a API validou o formulário
class ErroApiPerfil implements Exception {
  ErroApiPerfil(this.mensagem, {this.campos = const {}});

  final String mensagem;
  final Map<String, String> campos;

  @override
  String toString() => mensagem;
}

// texto pronto para SnackBar/mensagem a partir de qualquer erro
String mensagemDeErro(Object erro) =>
    erro.toString().replaceFirst('Exception: ', '');

abstract class RepositorioPerfil {
  // informe [membroId] ou [email]; lança [ErroApiPerfil] se não conseguir
  Future<PerfilMembro> buscarPerfil({String? membroId, String? email});

  // devolve o perfil já atualizado
  Future<PerfilMembro> editarPerfil({
    required String membroId,
    required String nome,
    required String email,
    String? telefone,
  });

  Future<void> alterarSenha({
    required String membroId,
    required String senhaAtual,
    required String novaSenha,
  });

  // devolve null quando o membro ainda não tem contrato
  Future<ContratoConsorcio?> buscarContrato(String membroId);
}

class RepositorioApiPerfil implements RepositorioPerfil {
  RepositorioApiPerfil({String? urlBase, http.Client? clienteHttp})
    : _urlBase = urlBase ?? RepositorioApiEnergia.urlPadrao,
      _clienteHttp = clienteHttp ?? http.Client();

  final String _urlBase;
  final http.Client _clienteHttp;

  // as rotas /perfil exigem login: o token JWT vai no header Authorization
  Map<String, String> get _cabecalhos {
    final token = SessaoAuth.instancia.token;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<PerfilMembro> buscarPerfil({String? membroId, String? email}) async {
    final parametros = <String, String>{};
    if (membroId != null && membroId.isNotEmpty) {
      parametros['membro_id'] = membroId;
    }
    if (email != null && email.isNotEmpty) parametros['email'] = email;

    final uri = Uri.parse(
      '$_urlBase/perfil',
    ).replace(queryParameters: parametros.isEmpty ? null : parametros);

    final resposta = await _enviar(
      () => _clienteHttp.get(uri, headers: _cabecalhos),
    );
    return PerfilMembro.deJson(_lerJson(resposta));
  }

  @override
  Future<PerfilMembro> editarPerfil({
    required String membroId,
    required String nome,
    required String email,
    String? telefone,
  }) async {
    final uri = Uri.parse('$_urlBase/perfil/$membroId');
    final resposta = await _enviar(
      () => _clienteHttp.put(
        uri,
        headers: _cabecalhos,
        body: jsonEncode({'nome': nome, 'email': email, 'telefone': telefone}),
      ),
    );
    return PerfilMembro.deJson(_lerJson(resposta));
  }

  @override
  Future<void> alterarSenha({
    required String membroId,
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final uri = Uri.parse('$_urlBase/perfil/$membroId/senha');
    await _enviar(
      () => _clienteHttp.put(
        uri,
        headers: _cabecalhos,
        body: jsonEncode({
          'senha_atual': senhaAtual,
          'nova_senha': novaSenha,
          'confirmar_senha': novaSenha,
        }),
      ),
    );
  }

  @override
  Future<ContratoConsorcio?> buscarContrato(String membroId) async {
    final uri = Uri.parse('$_urlBase/perfil/$membroId/contrato');
    final resposta = await _enviar(
      () => _clienteHttp.get(uri, headers: _cabecalhos),
      aceitar404: true, // 404 aqui só quer dizer "ainda não tem contrato"
    );
    if (resposta.statusCode == 404) return null;
    return ContratoConsorcio.deJson(_lerJson(resposta));
  }

  // faz a chamada, trata falha de rede e converte status de erro em ErroApiPerfil
  Future<http.Response> _enviar(
    Future<http.Response> Function() chamada, {
    bool aceitar404 = false,
  }) async {
    final http.Response resposta;
    try {
      resposta = await chamada().timeout(const Duration(seconds: 15));
    } catch (erro) {
      // em modo debug mostra o motivo no console e a URL na mensagem
      debugPrint('[Solis] falha na chamada ao servidor ($_urlBase): $erro');
      throw ErroApiPerfil(
        kDebugMode
            ? 'Não foi possível conectar ao servidor ($_urlBase). Verifique sua conexão.'
            : 'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return resposta;
    }
    if (aceitar404 && resposta.statusCode == 404) return resposta;

    String? mensagem;
    var campos = <String, String>{};
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) {
        mensagem = corpo['mensagem']?.toString();
        final camposJson = corpo['campos'];
        if (camposJson is Map) {
          campos = camposJson.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      }
    } catch (_) {
      // corpo que não é JSON: usa a mensagem padrão abaixo
    }

    throw ErroApiPerfil(
      mensagem ?? 'O servidor não conseguiu concluir a operação.',
      campos: campos,
    );
  }

  Map<String, dynamic> _lerJson(http.Response resposta) {
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) return corpo;
    } catch (_) {
      // cai no erro abaixo
    }
    throw ErroApiPerfil('Resposta inesperada do servidor.');
  }
}
