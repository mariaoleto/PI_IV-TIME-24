//Autora: Ana Luísa Maso Mafra | RA: 25007997

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/geracao_creditos/domain/repositorio_energia.dart';
import 'package:mobile/features/geracao_creditos/presentation/tela_lancamento_geracao.dart';
import 'package:mobile/features/gestao/data/modelos_usina.dart';
import 'package:mobile/features/gestao/data/repositorio_usina.dart';
import 'package:mobile/features/painel_admin/domain/repositorio_painel_admin.dart';
import 'package:mobile/features/painel_admin/presentation/tela_painel_admin.dart';
import 'package:mobile/features/perfil/domain/repositorio_perfil.dart';

// mesmo contrato do endpoint GET /admin/painel
const _json = <String, dynamic>{
  'usina': {
    'id': '507f1f77bcf86cd799439011',
    'nome': 'Usina Solis',
    'localizacao': 'Campinas - SP',
    'capacidade_kwp': 100.0,
    'ativa': true,
  },
  'resumo_mes': {
    'mes_referencia': '2026-10',
    'rotulo': 'Outubro/2026',
    'registrado': true,
    'geracao_kwh': 11160.0,
    'geracao_mes_anterior_kwh': 10000.0,
    'variacao_percentual': 11.6,
    'eficiencia_percentual': 90.0,
    'eficiencia_base': 'capacidade',
  },
  'membros': {
    'ativos': 3,
    'soma_percentual_cotas': 85.0,
    'percentual_disponivel': 15.0,
  },
  'alertas': [
    {
      'tipo': 'COTAS_INCOMPLETAS',
      'severidade': 'aviso',
      'titulo': 'Cotas abaixo de 100%',
      'mensagem': '15% da usina ainda não foram distribuídos entre os membros.',
    },
  ],
  'proximo_lancamento': {
    'mes_referencia': '2026-11',
    'rotulo': 'Novembro/2026',
    'status': 'em_dia',
    'meses_em_atraso': 0,
    'data_abertura': '2026-11-01',
  },
};

class _RepositorioPainelFalso implements RepositorioPainelAdmin {
  _RepositorioPainelFalso(this.respostas);

  // cada chamada consome uma resposta; Exception é lançada, PainelAdmin é devolvida
  final List<Object> respostas;
  int chamadas = 0;

  @override
  Future<PainelAdmin> buscarPainel({String? usinaId}) async {
    final r = respostas[chamadas < respostas.length ? chamadas : respostas.length - 1];
    chamadas++;
    if (r is Exception) throw r;
    return r as PainelAdmin;
  }
}

class _RepositorioEnergiaFalso implements RepositorioEnergia {
  @override
  Future<ResumoEnergia> buscarResumo({
    int? ano,
    String? usinaId,
    String? membroId,
    String? email,
  }) async => ResumoEnergia.exemplo();

  @override
  Future<List<CotaMembro>> buscarCotasDistribuicao({String? usinaId}) async => const [];

  @override
  Future<bool> salvarLancamentoMensal({
    required String mesReferencia,
    required double geracaoKwh,
    String? usinaId,
  }) async => true;

  @override
  Future<bool> salvarConsumoMensal({
    required String mesReferencia,
    required double consumoKwh,
    String? membroId,
    String? email,
    String? usinaId,
  }) async => true;
}

class _RepositorioPainelPorUsinaFalso implements RepositorioPainelAdmin {
  _RepositorioPainelPorUsinaFalso(this.aoBuscar);

  final PainelAdmin Function(String? usinaId) aoBuscar;
  final List<String?> usinasSolicitadas = [];

  @override
  Future<PainelAdmin> buscarPainel({String? usinaId}) async {
    usinasSolicitadas.add(usinaId);
    return aoBuscar(usinaId);
  }
}

class _RepositorioEnergiaMultiFalso implements RepositorioEnergia {
  _RepositorioEnergiaMultiFalso(this.cotasPorUsina);

  final Map<String, List<CotaMembro>> cotasPorUsina;
  final List<String?> lancamentosUsinaId = [];

  @override
  Future<ResumoEnergia> buscarResumo({
    int? ano,
    String? usinaId,
    String? membroId,
    String? email,
  }) async => ResumoEnergia.exemplo();

  @override
  Future<List<CotaMembro>> buscarCotasDistribuicao({String? usinaId}) async =>
      cotasPorUsina[usinaId ?? ''] ?? const [];

  @override
  Future<bool> salvarLancamentoMensal({
    required String mesReferencia,
    required double geracaoKwh,
    String? usinaId,
  }) async {
    lancamentosUsinaId.add(usinaId);
    return true;
  }

  @override
  Future<bool> salvarConsumoMensal({
    required String mesReferencia,
    required double consumoKwh,
    String? membroId,
    String? email,
    String? usinaId,
  }) async => true;
}

class _RepositorioUsinaFalso implements RepositorioUsina {
  _RepositorioUsinaFalso({List<Usina>? usinasIniciais})
    : _usinas = List<Usina>.from(
        usinasIniciais ??
            [
              const Usina(
                id: '507f1f77bcf86cd799439011',
                nome: 'Usina Solis',
                potencia: 100,
                distribuidora: 'CPFL',
                codigo: 'SOL-001',
                local: 'Campinas - SP',
              ),
            ],
      );

  final List<Usina> _usinas;

  final List<MembroUsina> _membros = [
    const MembroUsina(
      id: 'm1',
      nome: 'João Silva',
      email: 'joao@solis.app',
      cota: 85,
      status: 'Ativo',
    ),
  ];

  @override
  Future<List<Usina>> listar() async => List.unmodifiable(_usinas);

  @override
  Future<Usina> criar(Usina usina) async {
    final criada = Usina(
      id: 'usina-${_usinas.length + 1}',
      nome: usina.nome,
      potencia: usina.potencia,
      distribuidora: usina.distribuidora,
      codigo: 'SOL-002',
      local: usina.local,
    );
    _usinas.add(criada);
    return criada;
  }

  @override
  Future<Usina> atualizar(Usina usina) async => usina;

  @override
  Future<void> excluir(String usinaId) async {
    _usinas.removeWhere((u) => u.id == usinaId);
  }

  @override
  Future<List<MembroUsina>> listarMembros(String usinaId) async =>
      List.unmodifiable(_membros);

  @override
  Future<MembroUsina> adicionarMembro({
    required String usinaId,
    required String nome,
    required String email,
  }) async {
    final novo = MembroUsina(
      id: 'm-${_membros.length + 1}',
      nome: nome,
      email: email,
      cota: 0,
      status: 'Pendente',
    );
    _membros.add(novo);
    return novo;
  }

  @override
  Future<List<MembroUsina>> atualizarCotas(
    String usinaId,
    List<CotaAtualizacao> cotas,
  ) async => List.unmodifiable(_membros);

  @override
  Future<ContratoUsina?> buscarContrato(String usinaId) async => null;

  @override
  Future<ContratoUsina> salvarContrato(
    String usinaId,
    String nomeArquivo,
    Uint8List conteudo,
  ) async => ContratoUsina(
    usinaId: usinaId,
    nomeArquivo: nomeArquivo,
    tamanhoBytes: conteudo.length,
    dataEnvio: DateTime(2026, 10, 26),
  );

  @override
  Future<void> excluirContrato(String usinaId) async {}
}

class _RepositorioPerfilFalso implements RepositorioPerfil {
  @override
  Future<PerfilMembro> buscarPerfil({String? membroId, String? email}) async =>
      const PerfilMembro(
        id: 'admin-1',
        nome: 'Ana Administradora',
        inicial: 'A',
        email: 'ana@solis.app',
        ehAdmin: true,
      );

  @override
  Future<PerfilMembro> editarPerfil({
    required String membroId,
    required String nome,
    required String email,
    String? telefone,
  }) async => buscarPerfil();

  @override
  Future<void> alterarSenha({
    required String membroId,
    required String senhaAtual,
    required String novaSenha,
  }) async {}

  @override
  Future<ContratoConsorcio?> buscarContrato(String membroId) async => null;
}

Future<void> _abrir(
  WidgetTester tester,
  RepositorioPainelAdmin repo, {
  VoidCallback? aoAbrirCadastroUsina,
  VoidCallback? aoAbrirCadastroCotas,
}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: TelaPainelAdmin(
        repositorio: repo,
        repositorioEnergia: _RepositorioEnergiaFalso(),
        repositorioUsina: _RepositorioUsinaFalso(),
        repositorioPerfil: _RepositorioPerfilFalso(),
        nomeAdmin: 'Ana',
        aoAbrirCadastroUsina: aoAbrirCadastroUsina,
        aoAbrirCadastroCotas: aoAbrirCadastroCotas,
        agora: () => DateTime(2026, 10, 26, 9),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('interpreta o json do endpoint agregador', () {
    final painel = PainelAdmin.deJson(_json);

    expect(painel.usina.nome, 'Usina Solis');
    expect(painel.resumoMes.geracaoKwh, 11160);
    expect(painel.resumoMes.eficienciaPercentual, 90);
    expect(painel.membros.ativos, 3);
    expect(painel.alertas.single.severidade, SeveridadeAlerta.aviso);
    expect(painel.proximoLancamento.status, StatusLancamento.emDia);
  });

  test('campos ausentes não quebram a interpretação', () {
    final painel = PainelAdmin.deJson(const {});

    expect(painel.alertas, isEmpty);
    expect(painel.resumoMes.eficienciaPercentual, isNull);
    expect(painel.membros.ativos, 0);
  });

  test('formata números no padrão brasileiro', () {
    expect(formatarNumeroBr(11160), '11.160');
    expect(formatarNumeroBr(1234567), '1.234.567');
    expect(formatarNumeroBr(90, casas: 1), '90,0');
    expect(formatarNumeroBr(-11.6, casas: 1), '-11,6');
    expect(formatarNumeroBr(0), '0');
  });

  testWidgets('mostra saudação, selo, card da usina e menu', (tester) async {
    await _abrir(tester, _RepositorioPainelFalso([PainelAdmin.deJson(_json)]));

    expect(find.text('Bom dia,'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);

    expect(find.text('Usina Solis'), findsOneWidget);
    expect(find.text('11.160 kWh'), findsOneWidget);
    expect(find.text('Membros ativos'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('90,0%'), findsOneWidget);

    expect(find.text('Cadastro da Usina'), findsOneWidget);
    expect(find.text('Cadastro de Cotas'), findsOneWidget);
    expect(find.text('Registro de Geração e Consumo'), findsOneWidget);
  });

  testWidgets('mostra alertas ativos e o próximo lançamento', (tester) async {
    await _abrir(tester, _RepositorioPainelFalso([PainelAdmin.deJson(_json)]));

    await tester.scrollUntilVisible(find.text('Novembro/2026'), 200);
    expect(find.text('Cotas abaixo de 100%'), findsOneWidget);
    expect(find.text('Novembro/2026'), findsOneWidget);
    expect(find.text('Em dia — abre em 01/11'), findsOneWidget);
    expect(find.text('Lançar agora'), findsNothing);
  });

  testWidgets('lançamento atrasado oferece o botão de lançar', (tester) async {
    final atrasado = Map<String, dynamic>.from(_json)
      ..['alertas'] = <Map<String, dynamic>>[]
      ..['proximo_lancamento'] = {
        'mes_referencia': '2026-09',
        'rotulo': 'Setembro/2026',
        'status': 'atrasado',
        'meses_em_atraso': 2,
        'data_abertura': null,
      };
    await _abrir(tester, _RepositorioPainelFalso([PainelAdmin.deJson(atrasado)]));

    await tester.scrollUntilVisible(find.text('Lançar agora'), 200);
    expect(find.text('Nenhum alerta ativo. Está tudo certo com a usina.'), findsOneWidget);
    expect(find.text('2 meses em atraso'), findsOneWidget);
    expect(find.text('Lançar agora'), findsOneWidget);
  });

  testWidgets(
    'atalhos e barra inferior navegam para Usina, Membros/Cotas e Perfil sem avisos',
    (tester) async {
      await _abrir(tester, _RepositorioPainelFalso([PainelAdmin.deJson(_json)]));

      // Card Cadastro da Usina -> abre formulário preenchido da usina
      await tester.tap(find.text('Cadastro da Usina'));
      await tester.pumpAndSettle();
      expect(find.text('NOME DA USINA'), findsOneWidget);
      expect(find.text('LOCALIZAÇÃO'), findsOneWidget);
      expect(find.text('Cadastro da Usina ainda não está disponível.'), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      // Card Cadastro de Cotas -> abre aba de cotas/membros
      await tester.tap(find.text('Cadastro de Cotas'));
      await tester.pumpAndSettle();
      expect(find.text('COTA TOTAL DISTRIBUÍDA'), findsOneWidget);
      expect(find.text('João Silva'), findsOneWidget);

      // Troca pela barra inferior para Usina dentro da própria UsinaPage
      await tester.tap(find.text('Usina'));
      await tester.pumpAndSettle();
      expect(find.text('Gerenciamento da planta solar'), findsOneWidget);
      expect(find.text('Contrato do Consórcio'), findsOneWidget);

      // Volta ao Início pela barra inferior
      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();
      expect(find.text('11.160 kWh'), findsOneWidget);

      // Barra inferior: Membros
      await tester.tap(find.text('Membros'));
      await tester.pumpAndSettle();
      expect(find.text('COTA TOTAL DISTRIBUÍDA'), findsOneWidget);

      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();

      // Barra inferior: Perfil
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Administradora'), findsOneWidget);
      expect(find.text('ana@solis.app'), findsOneWidget);
    },
  );

  testWidgets('callbacks customizados funcionam quando informados', (tester) async {
    var abriuUsina = false;
    var abriuCotas = false;

    await _abrir(
      tester,
      _RepositorioPainelFalso([PainelAdmin.deJson(_json)]),
      aoAbrirCadastroUsina: () => abriuUsina = true,
      aoAbrirCadastroCotas: () => abriuCotas = true,
    );

    await tester.tap(find.text('Cadastro da Usina'));
    await tester.pump();
    await tester.tap(find.text('Cadastro de Cotas'));
    await tester.pump();

    expect(abriuUsina, isTrue);
    expect(abriuCotas, isTrue);
  });

  testWidgets('sem usina cadastrada oferece botão para cadastrar usina', (tester) async {
    await _abrir(
      tester,
      _RepositorioPainelFalso([Exception('Nenhuma usina cadastrada ainda.')]),
    );

    expect(find.text('Cadastrar usina'), findsOneWidget);
    await tester.tap(find.text('Cadastrar usina'));
    await tester.pumpAndSettle();

    expect(find.text('NOME DA USINA'), findsOneWidget);
  });

  testWidgets('erro de carregamento mostra mensagem e permite tentar de novo', (tester) async {
    final repo = _RepositorioPainelFalso([
      Exception('Não foi possível conectar ao servidor.'),
      PainelAdmin.deJson(_json),
    ]);
    await _abrir(tester, repo);

    expect(find.text('Não foi possível conectar ao servidor.'), findsOneWidget);
    expect(find.text('11.160 kWh'), findsNothing);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(repo.chamadas, 2);
    expect(find.text('11.160 kWh'), findsOneWidget);
  });

  testWidgets('permite alternar entre múltiplas usinas diretamente no painel admin', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final usinas = [
      const Usina(
        id: 'u-seed',
        nome: 'Consórcio Solis',
        potencia: 75,
        distribuidora: 'CPFL',
        codigo: 'SOLIS-01',
        local: 'Campinas - SP',
      ),
      const Usina(
        id: 'u-nova',
        nome: 'Usina Nova',
        potencia: 120,
        distribuidora: 'Enel',
        codigo: 'SOLIS-02',
        local: 'Jundiaí - SP',
      ),
    ];

    final repoPainel = _RepositorioPainelPorUsinaFalso((usinaId) {
      if (usinaId == 'u-nova') {
        return PainelAdmin.deJson({
          ..._json,
          'usina': {
            'id': 'u-nova',
            'nome': 'Usina Nova',
            'localizacao': 'Jundiaí - SP',
            'capacidade_kwp': 120.0,
            'ativa': true,
          },
          'resumo_mes': {
            ...(_json['resumo_mes'] as Map<String, dynamic>),
            'geracao_kwh': 8500.0,
          },
        });
      }
      return PainelAdmin.deJson({
        ..._json,
        'usina': {
          'id': 'u-seed',
          'nome': 'Consórcio Solis',
          'localizacao': 'Campinas - SP',
          'capacidade_kwp': 75.0,
          'ativa': true,
        },
        'resumo_mes': {
          ...(_json['resumo_mes'] as Map<String, dynamic>),
          'geracao_kwh': 5000.0,
        },
      });
    });

    await tester.pumpWidget(
      MaterialApp(
        home: TelaPainelAdmin(
          repositorio: repoPainel,
          repositorioEnergia: _RepositorioEnergiaFalso(),
          repositorioUsina: _RepositorioUsinaFalso(usinasIniciais: usinas),
          repositorioPerfil: _RepositorioPerfilFalso(),
          nomeAdmin: 'Ana',
          agora: () => DateTime(2026, 10, 26, 9),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Consórcio Solis'), findsWidgets);
    expect(find.text('5.000 kWh'), findsOneWidget);

    await tester.tap(find.byKey(const Key('seletor_usina_painel')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usina Nova (SOLIS-02)').last);
    await tester.pumpAndSettle();

    expect(repoPainel.usinasSolicitadas.last, 'u-nova');
    expect(find.text('Usina Nova'), findsWidgets);
    expect(find.text('8.500 kWh'), findsOneWidget);
  });

  testWidgets(
    'ao cadastrar nova usina na gestão e voltar, o painel passa a exibir a nova usina',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repoUsina = _RepositorioUsinaFalso(
        usinasIniciais: [
          const Usina(
            id: 'usina-1',
            nome: 'Consórcio Solis',
            potencia: 75,
            distribuidora: 'CPFL',
            codigo: 'SOLIS-01',
          ),
        ],
      );

      final repoPainel = _RepositorioPainelPorUsinaFalso((usinaId) {
        if (usinaId == 'usina-2') {
          return PainelAdmin.deJson({
            ..._json,
            'usina': {
              'id': 'usina-2',
              'nome': 'Usina Nova',
              'localizacao': 'Sorocaba - SP',
              'capacidade_kwp': 150.0,
              'ativa': true,
            },
            'resumo_mes': {
              ...(_json['resumo_mes'] as Map<String, dynamic>),
              'geracao_kwh': 9200.0,
            },
          });
        }
        return PainelAdmin.deJson({
          ..._json,
          'usina': {
            'id': 'usina-1',
            'nome': 'Consórcio Solis',
            'localizacao': 'Campinas - SP',
            'capacidade_kwp': 75.0,
            'ativa': true,
          },
          'resumo_mes': {
            ...(_json['resumo_mes'] as Map<String, dynamic>),
            'geracao_kwh': 5000.0,
          },
        });
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TelaPainelAdmin(
            repositorio: repoPainel,
            repositorioEnergia: _RepositorioEnergiaFalso(),
            repositorioUsina: repoUsina,
            repositorioPerfil: _RepositorioPerfilFalso(),
            nomeAdmin: 'Ana',
            agora: () => DateTime(2026, 10, 26, 9),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Usina'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cadastro da Usina'));
      await tester.pumpAndSettle();

      final campoNome = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Nome da usina',
      );
      final campoPotencia = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Ex.: 42',
      );

      await tester.enterText(campoNome, 'Usina Nova');
      await tester.enterText(campoPotencia, '150');
      await tester.ensureVisible(find.text('Salvar usina'));
      await tester.tap(find.text('Salvar usina'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();

      expect(repoPainel.usinasSolicitadas.last, 'usina-2');
      expect(find.text('Usina Nova'), findsWidgets);
      expect(find.text('9.200 kWh'), findsOneWidget);
      expect(find.byKey(const Key('seletor_usina_painel')), findsOneWidget);
    },
  );

  testWidgets(
    'tela de geração exibe estado vazio sem cotas reais e alterna entre usinas',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repoUsina = _RepositorioUsinaFalso(
        usinasIniciais: [
          const Usina(
            id: 'u-seed',
            nome: 'Consórcio Solis',
            potencia: 75,
            distribuidora: 'CPFL',
            codigo: 'SOLIS-01',
          ),
          const Usina(
            id: 'u-nova',
            nome: 'Usina Nova',
            potencia: 120,
            distribuidora: 'Enel',
            codigo: 'SOLIS-02',
          ),
        ],
      );
      final repoEnergia = _RepositorioEnergiaMultiFalso({
        'u-nova': const [],
        'u-seed': const [
          CotaMembro(
            cotaId: 'c1',
            membroId: 'm1',
            nome: 'Ana Paula',
            percentual: 100,
            tarifaKwh: 0.69,
          ),
        ],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: TelaLancamentoGeracao(
            repositorio: repoEnergia,
            repositorioUsina: repoUsina,
            usinaId: 'u-nova',
            nomeAdmin: 'Ana',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Esta usina ainda não possui membros com cotas cadastradas.'),
        findsOneWidget,
      );
      expect(find.text('João Oliveira'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '5000');
      await tester.pumpAndSettle();

      var botao = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(botao.onPressed, isNull);

      await tester.tap(find.byKey(const Key('seletor_usina_geracao')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Consórcio Solis (SOLIS-01)').last);
      await tester.pumpAndSettle();

      expect(
        find.text('Esta usina ainda não possui membros com cotas cadastradas.'),
        findsNothing,
      );
      expect(find.text('Ana Paula'), findsOneWidget);

      botao = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(botao.onPressed, isNotNull);

      await tester.tap(find.text('Confirmar e distribuir créditos'));
      await tester.pumpAndSettle();

      expect(repoEnergia.lancamentosUsinaId, ['u-seed']);
    },
  );
}
