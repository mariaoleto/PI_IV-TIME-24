// autora: Maria Júlia Lazarini Oleto
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/features/geracao_creditos/domain/repositorio_energia.dart';

class RepositorioEnergiaFalso implements RepositorioEnergia {
  @override
  Future<ResumoEnergia> buscarResumo({
    int? ano,
    String? usinaId,
    String? membroId,
  }) async {
    return ResumoEnergia.exemplo();
  }

  @override
  Future<List<CotaMembro>> buscarCotasDistribuicao({String? usinaId}) async {
    return const [];
  }

  @override
  Future<bool> salvarLancamentoMensal({
    required String mesReferencia,
    required double geracaoKwh,
    String? usinaId,
  }) async {
    return true;
  }
}

void main() {
  testWidgets('mostra resumo de geração de energia', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AplicativoSolis(repositorioEnergia: RepositorioEnergiaFalso()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Energia'), findsNWidgets(2));
    expect(find.text('2981 kWh'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('+417 kWh'), 100);
    expect(find.text('+417 kWh'), findsOneWidget);
  });
}
