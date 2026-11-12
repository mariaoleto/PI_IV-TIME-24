import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/features/auth/data/sessao_auth.dart';
import 'package:mobile/features/geracao_creditos/domain/repositorio_energia.dart';
import 'package:mobile/features/geracao_creditos/presentation/tela_energia.dart';

class _RepositorioEnergiaConsumoFalso implements RepositorioEnergia {
  double _consumoOutubro = 0;
  String? ultimoEmailBuscado;
  String? ultimoConsumoSalvoMes;
  double? ultimoConsumoSalvoKwh;
  String? ultimoConsumoSalvoEmail;

  @override
  Future<ResumoEnergia> buscarResumo({
    int? ano,
    String? usinaId,
    String? membroId,
    String? email,
  }) async {
    ultimoEmailBuscado = email;
    const rotulos = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    final meses = List.generate(12, (i) {
      final ref = '2026-${(i + 1).toString().padLeft(2, '0')}';
      final credito = i == 9 ? 24.0 : 0.0;
      final consumo = i == 9 ? _consumoOutubro : 0.0;
      return MesEnergia(
        rotulo: rotulos[i],
        referencia: ref,
        geracaoKwh: i == 9 ? 100.0 : 0.0,
        creditosLiquidosKwh: credito,
        consumoKwh: consumo,
        saldoMesKwh: credito - consumo,
      );
    });
    final saldo = 24.0 - _consumoOutubro;
    return ResumoEnergia(
      ano: 2026,
      totalGeracaoKwh: 100,
      totalConsumoKwh: _consumoOutubro,
      saldoAcumuladoKwh: saldo,
      economiaEstimadaReais: saldo * 0.69,
      meses: meses,
    );
  }

  @override
  Future<List<CotaMembro>> buscarCotasDistribuicao({String? usinaId}) async =>
      const [];

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
  }) async {
    ultimoConsumoSalvoMes = mesReferencia;
    ultimoConsumoSalvoKwh = consumoKwh;
    ultimoConsumoSalvoEmail = email;
    _consumoOutubro = consumoKwh;
    return true;
  }
}

void main() {
  testWidgets(
    'aba Consumo orienta quando zerada e permite registrar consumo mensal',
    (WidgetTester tester) async {
      final repo = _RepositorioEnergiaConsumoFalso();

      await tester.pumpWidget(
        MaterialApp(
          home: TelaEnergia(
            repositorio: repo,
            emailMembro: 'juliana@solis.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.ultimoEmailBuscado, 'juliana@solis.com');

      await tester.tap(find.text('Consumo'));
      await tester.pumpAndSettle();

      expect(find.text('0 kWh'), findsOneWidget);
      expect(find.text('Nenhum consumo registrado ainda'), findsOneWidget);

      await tester.tap(find.text('Informar consumo mensal'));
      await tester.pumpAndSettle();

      expect(find.text('Registrar consumo mensal'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '180');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(repo.ultimoConsumoSalvoKwh, 180);
      expect(repo.ultimoConsumoSalvoEmail, 'juliana@solis.com');
      expect(repo.ultimoConsumoSalvoMes, isNotNull);
      expect(find.text('180 kWh'), findsOneWidget);
      expect(find.text('Consumo mensal registrado com sucesso!'), findsOneWidget);
    },
  );

  test('RepositorioApiEnergia envia email na consulta e POST em /energia/consumo', () async {
    SessaoAuth.instancia.iniciar(
      'jwt-teste',
      const UsuarioSessao(
        id: '507f1f77bcf86cd799439022',
        nome: 'Juliana',
        email: 'juliana@solis.com',
      ),
    );
    addTearDown(SessaoAuth.instancia.limpar);

    final requisicoes = <http.Request>[];
    final cliente = MockClient((req) async {
      requisicoes.add(req);
      if (req.url.path == '/energia') {
        return http.Response(
          jsonEncode({
            'ano': 2026,
            'total_geracao_kwh': 100,
            'total_consumo_kwh': 50,
            'saldo_acumulado_kwh': 50,
            'economia_estimada_reais': 34.5,
            'meses': [],
          }),
          200,
        );
      }
      if (req.url.path == '/energia/consumo') {
        return http.Response(jsonEncode({'consumo_kwh': 50}), 201);
      }
      return http.Response('Not found', 404);
    });

    final repo = RepositorioApiEnergia(
      urlBase: 'http://localhost:3000',
      clienteHttp: cliente,
    );

    final resumo = await repo.buscarResumo(ano: 2026);
    expect(resumo.totalConsumoKwh, 50);
    expect(requisicoes[0].url.queryParameters['email'], 'juliana@solis.com');
    expect(
      requisicoes[0].url.queryParameters['membro_id'],
      '507f1f77bcf86cd799439022',
    );
    expect(requisicoes[0].headers['Authorization'], 'Bearer jwt-teste');

    final salvo = await repo.salvarConsumoMensal(
      mesReferencia: '2026-10',
      consumoKwh: 50,
    );
    expect(salvo, isTrue);
    final corpoPost = jsonDecode(requisicoes[1].body) as Map<String, dynamic>;
    expect(corpoPost['mes_referencia'], '2026-10');
    expect(corpoPost['consumo_kwh'], 50);
    expect(corpoPost['email'], 'juliana@solis.com');
  });
}

