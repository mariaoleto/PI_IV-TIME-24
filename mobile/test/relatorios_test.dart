import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/relatorios/domain/repositorio_relatorios.dart';
import 'package:mobile/features/relatorios/presentation/tela_relatorios.dart';

class RepositorioRelatoriosFalso implements RepositorioRelatorios {
  RepositorioRelatoriosFalso(this.documentos);

  final List<RelatorioDocumento> documentos;

  @override
  Future<List<RelatorioDocumento>> buscarDocumentos() async => documentos;

  @override
  Future<bool> gerar({
    required TipoRelatorioDocumento tipo,
    String? referencia,
    int? ano,
  }) async => true;

  @override
  Uri urlDownload(String relatorioId) => Uri.parse('https://example.com/$relatorioId');
}

void main() {
  testWidgets('renderiza os cards de resumo e a lista de documentos de relatórios', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));

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
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: TelaRelatorios(
          repositorio: RepositorioRelatoriosFalso(documentos),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Relatórios'), findsAtLeastNWidgets(1));
    expect(find.text('Geração total'), findsOneWidget);
    expect(find.text('Economia anual'), findsOneWidget);
    expect(find.text('CO₂ evitado'), findsOneWidget);
    expect(find.text('Relatório mensal'), findsAtLeastNWidgets(1));
    expect(find.text('Extrato de créditos'), findsAtLeastNWidgets(1));
    expect(find.text('Demonstrativo anual'), findsAtLeastNWidgets(1));
  });
}
