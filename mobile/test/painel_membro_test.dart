// autora: Maria Júlia Lazarini Oleto
// significado do arquivo:
// testes de widget do painel administrativo do membro (dashboard)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/painel_membro/domain/repositorio_painel_membro.dart';
import 'package:mobile/features/painel_membro/presentation/tela_painel_membro.dart';

class RepositorioPainelMembroFalso implements RepositorioPainelMembro {
  @override
  Future<DadosPainelMembro> buscarDashboard({
    String? membroId,
    String? email,
    String? usinaId,
    int? ano,
  }) async {
    return DadosPainelMembro.exemplo();
  }
}

void main() {
  testWidgets(
    'renderiza todos os componentes do painel do membro conforme protótipo',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(
        const Size(430, 932),
      ); // Tamanho iPhone Pro Max

      await tester.pumpWidget(
        MaterialApp(
          home: TelaPainelMembro(repositorio: RepositorioPainelMembroFalso()),
        ),
      );
      await tester.pumpAndSettle();

      // cabeçalho com saudação, nome, inicial e cota
      expect(find.text('Bom dia,'), findsOneWidget);
      expect(find.text('João Oliveira'), findsOneWidget);
      expect(find.text('J'), findsOneWidget);
      expect(find.text('Cota: 25%'), findsOneWidget);

      // cartão de créditos disponíveis
      expect(find.text('Créditos disponíveis · Set/2026'), findsOneWidget);
      expect(find.text('287'), findsOneWidget);
      expect(find.text('kWh'), findsAtLeastNWidgets(1));
      expect(find.text('Utilizado este mês'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('Gerado: 310 kWh'), findsOneWidget);
      expect(find.text('Consumido: 223 kWh'), findsOneWidget);

      // quatro cartões de métricas (CO2 evitado, Economia, Média diária, Pico consumo)
      expect(find.text('127 kg'), findsOneWidget);
      expect(find.text('CO₂ evitado'), findsOneWidget);
      expect(find.text('R\$ 186'), findsOneWidget);
      expect(find.text('Economia'), findsOneWidget);
      expect(find.text('9,7 kWh'), findsOneWidget);
      expect(find.text('Média diária'), findsOneWidget);
      expect(find.text('14,2 kWh'), findsOneWidget);
      expect(find.text('Pico consumo'), findsOneWidget);

      // cartão de Geração mensal
      expect(find.text('Geração mensal'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Set'), findsOneWidget);

      // ultimos lançamentos (rolar para garantir visibilidade)
      await tester.scrollUntilVisible(find.text('Últimos lançamentos'), 200);
      expect(find.text('Últimos lançamentos'), findsOneWidget);
      expect(find.text('Set/2026'), findsOneWidget);
      expect(find.text('+287 kWh'), findsOneWidget);
      expect(find.text('Ago/2026'), findsOneWidget);
      expect(find.text('+85 kWh'), findsOneWidget);
      expect(find.text('Jul/2026'), findsOneWidget);
      expect(find.text('+45 kWh'), findsOneWidget);
      expect(find.text('Jun/2026'), findsOneWidget);
      expect(find.text('-92 kWh'), findsOneWidget);

      // navigation Bar inferior: deve conter Início, Energia, Relatórios, Perfil
      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Energia'), findsOneWidget);
      expect(find.text('Relatórios'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);

      // E NÃO deve conter opção de alertas
      expect(find.text('Alertas'), findsNothing);
    },
  );
}
