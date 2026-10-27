//Autora: Ana Luísa Maso Mafra | RA: 25007997

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/geracao_creditos/domain/repositorio_energia.dart';
import 'package:mobile/features/painel_admin/domain/repositorio_painel_admin.dart';
import 'package:mobile/features/painel_admin/presentation/tela_painel_admin.dart';

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
  Future<ResumoEnergia> buscarResumo({int? ano, String? usinaId, String? membroId}) async =>
      ResumoEnergia.exemplo();

  @override
  Future<List<CotaMembro>> buscarCotasDistribuicao({String? usinaId}) async => const [];

  @override
  Future<bool> salvarLancamentoMensal({
    required String mesReferencia,
    required double geracaoKwh,
    String? usinaId,
  }) async => true;
}

Future<void> _abrir(WidgetTester tester, RepositorioPainelAdmin repo) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: TelaPainelAdmin(
        repositorio: repo,
        repositorioEnergia: _RepositorioEnergiaFalso(),
        nomeAdmin: 'Ana',
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

  testWidgets('itens sem tela ligada avisam que ainda não estão disponíveis', (tester) async {
    await _abrir(tester, _RepositorioPainelFalso([PainelAdmin.deJson(_json)]));

    await tester.tap(find.text('Cadastro de Cotas'));
    await tester.pump();

    expect(find.text('Cadastro de Cotas ainda não está disponível.'), findsOneWidget);
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
}
