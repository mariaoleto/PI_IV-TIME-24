import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/features/auth/data/sessao_auth.dart';
import 'package:mobile/features/relatorios/domain/repositorio_relatorios.dart';
import 'package:mobile/features/relatorios/presentation/tela_relatorios.dart';

class RepositorioRelatoriosFalso extends RepositorioRelatorios {
  RepositorioRelatoriosFalso(
    this.documentos, {
    this.telemetria,
    this.erroBusca,
  });

  final List<RelatorioDocumento> documentos;
  final TelemetriaTcpRelatorios? telemetria;
  final Exception? erroBusca;
  final List<Map<String, Object?>> geracoesSolicitadas = [];

  @override
  Future<List<RelatorioDocumento>> buscarDocumentos() async {
    if (erroBusca != null) throw erroBusca!;
    return documentos;
  }

  @override
  Future<bool> gerar({
    required TipoRelatorioDocumento tipo,
    String? referencia,
    int? ano,
  }) async {
    geracoesSolicitadas.add({
      'tipo': tipo,
      'referencia': referencia,
      'ano': ano,
    });
    return true;
  }

  @override
  Future<TelemetriaTcpRelatorios?> consultarTelemetriaTcp() async => telemetria;

  @override
  Uri urlDownload(String relatorioId) =>
      Uri.parse('https://example.com/$relatorioId');
}

void main() {
  testWidgets('renderiza os cards de resumo, telemetria TCP e lista sem exigir tamanho fixo', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));

    final List<RelatorioDocumento> documentos = [
      RelatorioDocumento(
        id: '1',
        tipo: 'relatorio_mensal',
        titulo: 'Relatório mensal',
        referencia: 'Set/2026',
        dataGeracao: DateTime(2026, 9, 12),
        arquivoUrl: 'https://example.com/relatorio-1.pdf',
        tamanhoMb: 2.1,
        totalGeracaoKwh: 4200,
        totalCreditosKwh: 3200,
        totalConsumoKwh: 2100,
        saldoKwh: 1100,
        economiaEstimadaReais: 680,
      ),
      RelatorioDocumento(
        id: '2',
        tipo: 'extrato_creditos',
        titulo: 'Extrato de créditos',
        referencia: 'Ago/2026',
        dataGeracao: DateTime(2026, 8, 11),
        arquivoUrl: 'https://example.com/relatorio-2.pdf',
        tamanhoMb: 1.9,
        totalGeracaoKwh: 3900,
        totalCreditosKwh: 2860,
        totalConsumoKwh: 1800,
        saldoKwh: 1060,
        economiaEstimadaReais: 540,
      ),
      RelatorioDocumento(
        id: '3',
        tipo: 'demonstrativo_anual',
        titulo: 'Demonstrativo anual',
        referencia: '2026',
        dataGeracao: DateTime(2026, 12, 15),
        arquivoUrl: 'https://example.com/relatorio-3.pdf',
        tamanhoMb: 2.5,
        totalGeracaoKwh: 42800,
        totalCreditosKwh: 35600,
        totalConsumoKwh: 28960,
        saldoKwh: 6640,
        economiaEstimadaReais: 6890,
        origemDadosTcp: 'Java Socket TCP (porta 5050)',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TelaRelatorios(
          repositorio: RepositorioRelatoriosFalso(
            documentos,
            telemetria: const TelemetriaTcpRelatorios(
              online: true,
              usina: 'Solis_1',
              geracaoAtual: '14.2kW',
              tensao: '220V',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Relatórios'), findsAtLeastNWidgets(1));
    expect(find.text('Geração total'), findsOneWidget);
    expect(find.text('Economia anual'), findsOneWidget);
    expect(find.text('CO₂ evitado'), findsOneWidget);
    // Usa os valores do demonstrativo anual (42.800 kWh e R$ 6.890) em vez de apenas 1 mês
    expect(find.text('42.800 kWh'), findsOneWidget);
    expect(find.text('R\$ 6.890'), findsOneWidget);
    expect(find.text('Solis_1 · 14.2kW · 220V'), findsOneWidget);
    expect(find.text('Relatório mensal'), findsAtLeastNWidgets(1));
    expect(find.text('Extrato de créditos'), findsAtLeastNWidgets(1));
    expect(find.text('Demonstrativo anual'), findsAtLeastNWidgets(1));

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('exibe estado vazio real e permite gerar relatório pela tela', (
    WidgetTester tester,
  ) async {
    final repo = RepositorioRelatoriosFalso(const []);

    await tester.pumpWidget(
      MaterialApp(home: TelaRelatorios(repositorio: repo)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum relatório gerado ainda'), findsOneWidget);
    expect(find.text('Contrato do consórcio'), findsNothing);
    expect(find.text('0 kWh'), findsOneWidget);

    await tester.tap(find.text('Gerar PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Gerar relatório PDF'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Gerar PDF'));
    await tester.pumpAndSettle();

    expect(repo.geracoesSolicitadas.length, 1);
    expect(
      repo.geracoesSolicitadas.first['tipo'],
      TipoRelatorioDocumento.relatorioMensal,
    );
  });

  testWidgets('exibe erro amigável quando a busca na API falha', (
    WidgetTester tester,
  ) async {
    final repo = RepositorioRelatoriosFalso(
      const [],
      erroBusca: ErroApiRelatorios('Sessão inválida ou expirada.'),
    );

    await tester.pumpWidget(
      MaterialApp(home: TelaRelatorios(repositorio: repo)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sessão inválida ou expirada.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  test('RepositorioApiRelatorios usa as rotas corretas do backend e resolve ticket autenticado', () async {
    SessaoAuth.instancia.iniciar(
      'jwt-de-teste',
      const UsuarioSessao(id: '1', nome: 'Ana', email: 'ana@solis.com'),
    );
    final chamadas = <String>[];

    final mockClient = MockClient((request) async {
      chamadas.add('${request.method} ${request.url.path}');
      expect(request.headers['Authorization'], 'Bearer jwt-de-teste');

      if (request.method == 'POST' && request.url.path == '/relatorios/mensal') {
        return http.Response('', 200);
      }
      if (request.method == 'POST' &&
          request.url.path == '/relatorios/extrato-creditos') {
        return http.Response('', 200);
      }
      if (request.method == 'POST' &&
          request.url.path == '/relatorios/demonstrativo-anual') {
        return http.Response('', 200);
      }
      if (request.method == 'GET' &&
          request.url.path == '/relatorios/abc123/ticket') {
        return http.Response(
          jsonEncode({'download_url': '/relatorios/abc123/download?ticket=ok.1'}),
          200,
        );
      }
      return http.Response('{"mensagem":"não encontrado"}', 404);
    });

    final repo = RepositorioApiRelatorios(
      urlBase: 'http://localhost:3000',
      clienteHttp: mockClient,
    );

    expect(
      await repo.gerar(
        tipo: TipoRelatorioDocumento.relatorioMensal,
        referencia: '2026-09',
      ),
      isTrue,
    );
    expect(
      await repo.gerar(
        tipo: TipoRelatorioDocumento.extratoCreditos,
        referencia: '2026-09',
      ),
      isTrue,
    );
    expect(
      await repo.gerar(
        tipo: TipoRelatorioDocumento.demonstrativoAnual,
        ano: 2026,
      ),
      isTrue,
    );

    final uriDownload = await repo.resolverUrlDownload(
      RelatorioDocumento(
        id: 'abc123',
        tipo: 'relatorio_mensal',
        titulo: 'Relatório mensal',
        referencia: 'setembro de 2026',
        dataGeracao: DateTime(2026, 9, 12),
        arquivoUrl: '/relatorios/abc123/download',
        tamanhoMb: 0.1,
        totalGeracaoKwh: 1000,
        totalCreditosKwh: 250,
        totalConsumoKwh: 150,
        saldoKwh: 100,
        economiaEstimadaReais: 70,
      ),
    );

    expect(
      uriDownload.toString(),
      'http://localhost:3000/relatorios/abc123/download?ticket=ok.1',
    );
    expect(chamadas, [
      'POST /relatorios/mensal',
      'POST /relatorios/extrato-creditos',
      'POST /relatorios/demonstrativo-anual',
      'GET /relatorios/abc123/ticket',
    ]);

    SessaoAuth.instancia.limpar();
  });
}
