// Autora: Marina Hehnes Espósito.
// Propósito: valida a renderização inicial e a navegação para o cadastro da usina.
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('mostra o resumo da usina na tela inicial', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AplicativoSolis());
    await tester.pumpAndSettle();

    expect(find.text('Gerenciamento da planta solar'), findsOneWidget);
    expect(find.text('Solis SP-Norte-01'), findsOneWidget);
    expect(find.text('Cadastro da Usina'), findsOneWidget);
  });

  testWidgets('abre o formulário de cadastro da usina', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AplicativoSolis());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastro da Usina'));
    await tester.pumpAndSettle();

    expect(find.text('NOME DA USINA'), findsOneWidget);
    expect(find.text('POTÊNCIA INSTALADA'), findsOneWidget);
    expect(find.text('Salvar usina'), findsOneWidget);
  });
}
