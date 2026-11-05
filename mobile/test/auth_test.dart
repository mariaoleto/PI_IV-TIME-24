//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// testes de login, cadastro (passos 1 e 2) e recuperação de senha, e da integração com o backend
// (chamadas HTTP simuladas com MockClient, sem precisar do servidor)

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/features/auth/data/servico_auth.dart';
import 'package:mobile/features/auth/data/sessao_auth.dart';
import 'package:mobile/features/auth/domain/cpf.dart';
import 'package:mobile/features/auth/presentation/tela_criar_conta.dart';
import 'package:mobile/features/auth/presentation/tela_login.dart';
import 'package:mobile/features/auth/presentation/tela_recuperar_senha.dart';
import 'package:mobile/features/perfil/domain/repositorio_perfil.dart';

const _cabecalhoJson = {'content-type': 'application/json; charset=utf-8'};

http.Response _json(int status, Object corpo) =>
    http.Response(jsonEncode(corpo), status, headers: _cabecalhoJson);

Map<String, Object?> _respostaLogin({bool admin = false}) => {
  'token': 'jwt-de-teste',
  'usuario': {
    'id': '507f1f77bcf86cd799439011',
    'nome': 'Ana Souza',
    'email': 'ana@gmail.com',
    'tipo_usuario': admin ? 'admin' : 'membro',
    'eh_admin': admin,
  },
};

// serviço falso que só anota o que o app enviou
class ServicoAuthFalso implements ServicoAuth {
  final chamadas = <String>[];
  Map<String, Object?> ultimosDados = {};
  Exception? erro;

  Future<void> _registrar(String nome, Map<String, Object?> dados) async {
    chamadas.add(nome);
    ultimosDados = dados;
    if (erro != null) throw erro!;
  }

  @override
  Future<void> entrarMembro({required String email, required String senha}) =>
      _registrar('entrarMembro', {'email': email, 'senha': senha});

  @override
  Future<void> entrarAdministrador({
    required String email,
    required String senha,
  }) => _registrar('entrarAdministrador', {'email': email, 'senha': senha});

  @override
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String cpf,
    String? telefone,
    required String senha,
  }) => _registrar('cadastrar', {
    'nome': nome,
    'email': email,
    'cpf': cpf,
    'telefone': telefone,
    'senha': senha,
  });

  @override
  Future<void> solicitarRecuperacao({required String email}) =>
      _registrar('solicitarRecuperacao', {'email': email});

  @override
  Future<void> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) => _registrar('redefinirSenha', {
    'email': email,
    'codigo': codigo,
    'nova_senha': novaSenha,
  });
}

// abre a tela por cima de outra rota, como no app (assim o pop() ao concluir funciona)
Widget _abrirPorCima(Widget tela) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => tela)),
          child: const Text('abrir'),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(() => SessaoAuth.instancia.limpar());

  group('ServicoAuthApi (HTTP)', () {
    test('login de membro guarda token e usuário na sessão', () async {
      late http.Request enviada;
      final servico = ServicoAuthApi(
        urlBase: 'http://servidor',
        clienteHttp: MockClient((requisicao) async {
          enviada = requisicao;
          return _json(200, _respostaLogin());
        }),
      );

      await servico.entrarMembro(email: 'ana@gmail.com', senha: 'segredo1');

      expect(enviada.url.toString(), 'http://servidor/auth/login');
      expect(jsonDecode(enviada.body), {
        'email': 'ana@gmail.com',
        'senha': 'segredo1',
        'perfil': 'membro',
      });
      expect(SessaoAuth.instancia.logado, isTrue);
      expect(SessaoAuth.instancia.token, 'jwt-de-teste');
      expect(SessaoAuth.instancia.usuario?.nome, 'Ana Souza');
    });

    test('login de administrador envia perfil "admin"', () async {
      late Map<String, dynamic> corpo;
      final servico = ServicoAuthApi(
        urlBase: 'http://servidor',
        clienteHttp: MockClient((requisicao) async {
          corpo = jsonDecode(requisicao.body) as Map<String, dynamic>;
          return _json(200, _respostaLogin(admin: true));
        }),
      );

      await servico.entrarAdministrador(email: 'a@solis.com', senha: 'segredo1');

      expect(corpo['perfil'], 'admin');
      expect(SessaoAuth.instancia.usuario?.ehAdmin, isTrue);
    });

    test('senha errada vira mensagem amigável e não cria sessão', () async {
      final servico = ServicoAuthApi(
        urlBase: 'http://servidor',
        clienteHttp: MockClient(
          (_) async => _json(401, {'mensagem': 'E-mail ou senha incorretos'}),
        ),
      );

      await expectLater(
        servico.entrarMembro(email: 'ana@gmail.com', senha: 'errada1'),
        throwsA(
          isA<ErroApiAuth>().having(
            (e) => e.toString(),
            'mensagem',
            'E-mail ou senha incorretos',
          ),
        ),
      );
      expect(SessaoAuth.instancia.logado, isFalse);
    });

    test('cadastro envia os dados e já deixa o usuário logado', () async {
      late Map<String, dynamic> corpo;
      final servico = ServicoAuthApi(
        urlBase: 'http://servidor',
        clienteHttp: MockClient((requisicao) async {
          expect(requisicao.url.path, '/auth/cadastro');
          corpo = jsonDecode(requisicao.body) as Map<String, dynamic>;
          return _json(201, _respostaLogin());
        }),
      );

      await servico.cadastrar(
        nome: 'Ana Souza',
        email: 'ana@gmail.com',
        cpf: '52998224725',
        telefone: '19999998888',
        senha: 'segredo1',
      );

      expect(corpo['nome'], 'Ana Souza');
      expect(corpo['cpf'], '52998224725');
      expect(corpo['telefone'], '19999998888');
      expect(corpo['senha'], 'segredo1');
      expect(SessaoAuth.instancia.logado, isTrue);
    });

    test('e-mail já cadastrado devolve o erro do campo', () async {
      final servico = ServicoAuthApi(
        urlBase: 'http://servidor',
        clienteHttp: MockClient(
          (_) async => _json(409, {
            'mensagem': 'Este e-mail já está cadastrado',
            'campos': {'email': 'Este e-mail já está cadastrado'},
          }),
        ),
      );

      await expectLater(
        servico.cadastrar(
          nome: 'Ana Souza',
          email: 'a@b.co',
          cpf: '52998224725',
          senha: 'segredo1',
        ),
        throwsA(
          isA<ErroApiAuth>().having(
            (e) => e.campos['email'],
            'campos.email',
            'Este e-mail já está cadastrado',
          ),
        ),
      );
    });

    test('recuperação e redefinição chamam as rotas certas', () async {
      final rotas = <String>[];
      final corpos = <Map<String, dynamic>>[];
      final servico = ServicoAuthApi(
        urlBase: 'http://servidor',
        clienteHttp: MockClient((requisicao) async {
          rotas.add(requisicao.url.path);
          corpos.add(jsonDecode(requisicao.body) as Map<String, dynamic>);
          return _json(200, {'mensagem': 'ok'});
        }),
      );

      await servico.solicitarRecuperacao(email: 'ana@gmail.com');
      await servico.redefinirSenha(
        email: 'ana@gmail.com',
        codigo: '123456',
        novaSenha: 'novaSenha1',
      );

      expect(rotas, ['/auth/recuperar-senha', '/auth/redefinir-senha']);
      expect(corpos[1], {
        'email': 'ana@gmail.com',
        'codigo': '123456',
        'nova_senha': 'novaSenha1',
      });
    });

    test('sem conexão mostra mensagem amigável', () async {
      final servico = ServicoAuthApi(
        urlBase: 'http://servidor',
        clienteHttp: MockClient((_) async => throw http.ClientException('x')),
      );

      await expectLater(
        servico.entrarMembro(email: 'a@b.co', senha: 'segredo1'),
        throwsA(
          isA<ErroApiAuth>().having(
            (e) => e.toString(),
            'mensagem',
            contains('Não foi possível conectar'),
          ),
        ),
      );
    });
  });

  test('o perfil envia o token JWT no header Authorization', () async {
    SessaoAuth.instancia.iniciar(
      'jwt-de-teste',
      const UsuarioSessao(id: '1', nome: 'Ana Souza', email: 'ana@gmail.com'),
    );
    String? cabecalho;
    final repositorio = RepositorioApiPerfil(
      urlBase: 'http://servidor',
      clienteHttp: MockClient((requisicao) async {
        cabecalho = requisicao.headers['Authorization'];
        return _json(200, {
          'membro': {'id': '1', 'nome': 'Ana Souza', 'email': 'ana@gmail.com'},
          'consorcio': {},
        });
      }),
    );

    final perfil = await repositorio.buscarPerfil(email: 'ana@gmail.com');

    expect(cabecalho, 'Bearer jwt-de-teste');
    expect(perfil.nome, 'Ana Souza');
  });

  test('CPF: validação, máscara e dígitos', () {
    expect(cpfValido('529.982.247-25'), isTrue);
    expect(cpfValido('529.982.247-24'), isFalse);
    expect(cpfValido('111.111.111-11'), isFalse);
    expect(validarCpf(''), 'Informe seu CPF');
    expect(validarCpf('123'), 'CPF inválido');
    expect(validarCpf('52998224725'), isNull);
    expect(formatarCpf('52998224725'), '529.982.247-25');
    expect(formatarCpf('5299'), '529.9');
    expect(cpfSoDigitos('529.982.247-25'), '52998224725');
  });

  group('TelaLogin', () {
    testWidgets('entra pelo serviço e vai para a tela seguinte', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final servico = ServicoAuthFalso();
      await tester.pumpWidget(
        MaterialApp(
          home: TelaLogin(
            servicoAuth: servico,
            destinoAposLogin: (_, email) => Text('painel de $email'),
          ),
        ),
      );

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'ana@gmail.com');
      await tester.enterText(campos.at(1), 'segredo1');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(servico.chamadas, ['entrarMembro']);
      expect(servico.ultimosDados['senha'], 'segredo1');
      expect(find.text('painel de ana@gmail.com'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('credencial inválida mostra a mensagem e fica no login', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final servico = ServicoAuthFalso()
        ..erro = ErroApiAuth('E-mail ou senha incorretos');
      await tester.pumpWidget(
        MaterialApp(home: TelaLogin(servicoAuth: servico)),
      );

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'ana@gmail.com');
      await tester.enterText(campos.at(1), 'errada1');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail ou senha incorretos'), findsOneWidget);
      expect(find.text('Bem-vindo de volta'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('botão "Entrar como Administrador" abre o login de admin', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pumpWidget(
        MaterialApp(home: TelaLogin(servicoAuth: ServicoAuthFalso())),
      );

      await tester.tap(find.text('Entrar como Administrador'));
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo, Administrador'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('"Esqueci a senha" abre a recuperação', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pumpWidget(
        MaterialApp(home: TelaLogin(servicoAuth: ServicoAuthFalso())),
      );

      await tester.tap(find.text('Esqueci a senha'));
      await tester.pumpAndSettle();

      expect(find.text('Recuperar senha'), findsOneWidget);
      expect(find.text('Enviar código'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Cadastro', () {
    testWidgets('passo 1 leva ao passo 2 e o passo 2 cria a conta', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final servico = ServicoAuthFalso();
      await tester.pumpWidget(
        MaterialApp(
          home: TelaCriarConta(
            servicoAuth: servico,
            destinoAposCadastro: (_, email) => Text('painel de $email'),
          ),
        ),
      );

      // passo 1: nome sem sobrenome e CPF inválido não avançam
      var campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Ana');
      await tester.enterText(campos.at(1), 'ana@gmail.com');
      await tester.enterText(campos.at(2), '123.456.789-00');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('PASSO 2 DE 2'), findsNothing);
      expect(find.text('Informe nome e sobrenome'), findsOneWidget);
      expect(find.text('CPF inválido'), findsOneWidget);

      await tester.enterText(campos.at(0), 'Ana Souza');
      await tester.enterText(campos.at(2), '52998224725'); // a máscara formata sozinha
      await tester.pump();
      expect(find.text('529.982.247-25'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('PASSO 2 DE 2'), findsOneWidget);
      expect(find.text('Quase lá, Ana!'), findsOneWidget);

      // passo 2: senhas diferentes não criam a conta
      campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), '(19) 99999-8888');
      await tester.enterText(campos.at(1), 'segredo1');
      await tester.enterText(campos.at(2), 'diferente1');
      await tester.tap(find.text('Criar conta'));
      await tester.pump();
      expect(find.text('As senhas não conferem'), findsOneWidget);
      expect(servico.chamadas, isEmpty);

      await tester.enterText(campos.at(2), 'segredo1');
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(servico.chamadas, ['cadastrar']);
      expect(servico.ultimosDados, {
        'nome': 'Ana Souza',
        'email': 'ana@gmail.com',
        'cpf': '52998224725',
        'telefone': '19999998888',
        'senha': 'segredo1',
      });
      expect(find.text('painel de ana@gmail.com'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('e-mail ou CPF já cadastrado mostra o erro e volta ao passo 1', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final servico = ServicoAuthFalso()
        ..erro = ErroApiAuth(
          'Este e-mail já está cadastrado',
          campos: {'email': 'Este e-mail já está cadastrado'},
        );
      await tester.pumpWidget(
        MaterialApp(home: TelaCriarConta(servicoAuth: servico)),
      );

      var campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Ana Souza');
      await tester.enterText(campos.at(1), 'ana@gmail.com');
      await tester.enterText(campos.at(2), '529.982.247-25');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      campos = find.byType(TextFormField);
      await tester.enterText(campos.at(1), 'segredo1');
      await tester.enterText(campos.at(2), 'segredo1');
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('Este e-mail já está cadastrado'), findsOneWidget);
      // o e-mail é do passo 1, então o app volta para lá para a pessoa corrigir
      expect(find.text('PASSO 2 DE 2'), findsNothing);
      expect(find.text('PASSO 1 DE 2'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Recuperação de senha', () {
    testWidgets('pede o código e depois redefine a senha', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final servico = ServicoAuthFalso();
      await tester.pumpWidget(
        _abrirPorCima(
          TelaRecuperarSenha(servicoAuth: servico, emailInicial: 'ana@gmail.com'),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // etapa 1: e-mail
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();
      expect(servico.chamadas, ['solicitarRecuperacao']);
      expect(servico.ultimosDados['email'], 'ana@gmail.com');

      // etapa 2: código com menos de 6 dígitos não passa
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), '123');
      await tester.enterText(campos.at(1), 'novaSenha1');
      await tester.enterText(campos.at(2), 'novaSenha1');
      await tester.tap(find.text('Redefinir senha'));
      await tester.pump();
      expect(find.text('Digite o código de 6 dígitos'), findsOneWidget);
      expect(servico.chamadas, ['solicitarRecuperacao']);

      await tester.enterText(campos.at(0), '123456');
      await tester.tap(find.text('Redefinir senha'));
      await tester.pumpAndSettle();

      expect(servico.chamadas, ['solicitarRecuperacao', 'redefinirSenha']);
      expect(servico.ultimosDados, {
        'email': 'ana@gmail.com',
        'codigo': '123456',
        'nova_senha': 'novaSenha1',
      });
      // voltou para a tela anterior
      expect(find.text('abrir'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
