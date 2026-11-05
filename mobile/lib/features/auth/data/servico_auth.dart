//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// serviço de autenticação do app: login (membro e administrador), cadastro e recuperação de senha
// [ServicoAuthApi] conversa com o backend (/auth/...) e guarda o token na [SessaoAuth]
// [ServicoAuthLocal] é uma versão de mentira (sem backend), só para demonstração e testes
//
// endpoints do backend:
//   POST /auth/login             { email, senha, perfil: "membro" | "admin" }
//   POST /auth/cadastro          { nome, email, telefone?, senha, confirmar_senha }
//   POST /auth/recuperar-senha   { email }
//   POST /auth/redefinir-senha   { email, codigo, nova_senha }

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../geracao_creditos/domain/repositorio_energia.dart';
import 'sessao_auth.dart';

// erro com mensagem amigável para mostrar na tela
// [campos] traz o erro de cada campo quando a API validou o formulário
class ErroApiAuth implements Exception {
  ErroApiAuth(this.mensagem, {this.campos = const {}});

  final String mensagem;
  final Map<String, String> campos;

  @override
  String toString() => mensagem;
}

abstract class ServicoAuth {
  /// Lança [Exception] com mensagem amigável se as credenciais forem inválidas.
  Future<void> entrarMembro({required String email, required String senha});

  Future<void> entrarAdministrador({
    required String email,
    required String senha,
  });

  /// Cria a conta de membro e já deixa o usuário logado.
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String cpf, // somente dígitos
    String? telefone,
    required String senha,
  });

  /// Pede o envio do código de 6 dígitos por e-mail.
  /// A resposta é sempre a mesma, exista a conta ou não.
  Future<void> solicitarRecuperacao({required String email});

  Future<void> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  });
}

class ServicoAuthApi implements ServicoAuth {
  ServicoAuthApi({String? urlBase, http.Client? clienteHttp})
    : _urlBase = urlBase ?? RepositorioApiEnergia.urlPadrao,
      _clienteHttp = clienteHttp ?? http.Client();

  final String _urlBase;
  final http.Client _clienteHttp;

  @override
  Future<void> entrarMembro({required String email, required String senha}) {
    return _entrar(email, senha, 'membro');
  }

  @override
  Future<void> entrarAdministrador({
    required String email,
    required String senha,
  }) {
    return _entrar(email, senha, 'admin');
  }

  Future<void> _entrar(String email, String senha, String perfil) async {
    final corpo = await _post('/auth/login', {
      'email': email,
      'senha': senha,
      'perfil': perfil,
    });
    _iniciarSessao(corpo);
  }

  @override
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String cpf,
    String? telefone,
    required String senha,
  }) async {
    final corpo = await _post('/auth/cadastro', {
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'telefone': telefone,
      'senha': senha,
      'confirmar_senha': senha,
    });
    _iniciarSessao(corpo);
  }

  @override
  Future<void> solicitarRecuperacao({required String email}) async {
    await _post('/auth/recuperar-senha', {'email': email});
  }

  @override
  Future<void> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    await _post('/auth/redefinir-senha', {
      'email': email,
      'codigo': codigo,
      'nova_senha': novaSenha,
    });
  }

  void _iniciarSessao(Map<String, dynamic> corpo) {
    final token = corpo['token']?.toString();
    final usuario = corpo['usuario'];
    if (token == null || token.isEmpty || usuario is! Map<String, dynamic>) {
      throw ErroApiAuth('Resposta inesperada do servidor.');
    }
    SessaoAuth.instancia.iniciar(token, UsuarioSessao.deJson(usuario));
  }

  // faz o POST, trata falha de rede e converte status de erro em ErroApiAuth
  Future<Map<String, dynamic>> _post(
    String caminho,
    Map<String, Object?> corpo,
  ) async {
    final http.Response resposta;
    try {
      resposta = await _clienteHttp
          .post(
            Uri.parse('$_urlBase$caminho'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(corpo),
          )
          .timeout(const Duration(seconds: 15));
    } catch (erro) {
      // em modo debug mostra a URL e o motivo, para achar o problema (servidor desligado, IP errado...)
      debugPrint('[Solis] falha ao chamar $_urlBase$caminho: $erro');
      throw ErroApiAuth(
        kDebugMode
            ? 'Não foi possível conectar ao servidor ($_urlBase). Verifique sua conexão.'
            : 'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }

    Map<String, dynamic> json = {};
    try {
      final decodificado = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (decodificado is Map<String, dynamic>) json = decodificado;
    } catch (_) {
      // corpo vazio ou que não é JSON: segue com o mapa vazio
    }

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return json;

    final camposJson = json['campos'];
    throw ErroApiAuth(
      json['mensagem']?.toString() ??
          'O servidor não conseguiu concluir a operação.',
      campos: camposJson is Map
          ? camposJson.map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
    );
  }
}

/// Implementação SIMULADA (sem backend): aceita qualquer dado já validado no formulário.
/// Não é mais usada pelas telas por padrão; serve para demonstração e testes.
class ServicoAuthLocal implements ServicoAuth {
  Future<void> _esperar() =>
      Future<void>.delayed(const Duration(milliseconds: 600));

  @override
  Future<void> entrarMembro({
    required String email,
    required String senha,
  }) => _esperar();

  @override
  Future<void> entrarAdministrador({
    required String email,
    required String senha,
  }) => _esperar();

  @override
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String cpf,
    String? telefone,
    required String senha,
  }) => _esperar();

  @override
  Future<void> solicitarRecuperacao({required String email}) => _esperar();

  @override
  Future<void> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) => _esperar();
}
