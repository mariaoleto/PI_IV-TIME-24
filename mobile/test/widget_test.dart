import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/src/geracao_consumos/modelos_energia.dart';
import 'package:mobile/src/geracao_consumos/repositorio_energia.dart';

class RepositorioEnergiaFalso implements RepositorioEnergia {
  @override
  Future<ResumoEnergia> buscarResumo({
    int? ano,
    String? usinaId,
    String? membroId,
  }) async {
    return ResumoEnergia.exemplo();
  }
}

void main() {
  testWidgets('mostra resumo de geração de energia', (WidgetTester tester) async {
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
