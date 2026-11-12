// Autora: Marina Hehnes Espósito.
// Propósito: valida a renderização inicial, navegação e integração com repositório da gestão de usinas.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/gestao/data/modelos_usina.dart';
import 'package:mobile/features/gestao/data/repositorio_usina.dart';
import 'package:mobile/features/gestao/presentation/usina_page.dart';

class _RepositorioUsinaTeste implements RepositorioUsina {
  final List<Usina> usinas = [
    const Usina(
      id: 'u1',
      nome: 'Usina Teste Real',
      potencia: 75,
      distribuidora: 'CPFL',
      codigo: 'SOL-100',
      local: 'Campinas, SP',
    ),
  ];

  final List<MembroUsina> membros = [
    const MembroUsina(
      id: 'm1',
      nome: 'Carlos Pereira',
      email: 'carlos@solis.app',
      cota: 60,
      status: 'Ativo',
    ),
  ];

  ContratoUsina? contrato;
  List<CotaAtualizacao>? ultimasCotasSalvas;
  Usina? ultimaCriada;

  @override
  Future<List<Usina>> listar() async => List.unmodifiable(usinas);

  @override
  Future<Usina> criar(Usina usina) async {
    final nova = Usina(
      id: 'u-${usinas.length + 1}',
      nome: usina.nome,
      potencia: usina.potencia,
      distribuidora: usina.distribuidora,
      codigo: 'SOL-10${usinas.length + 1}',
      local: usina.local,
    );
    ultimaCriada = nova;
    usinas.add(nova);
    return nova;
  }

  @override
  Future<Usina> atualizar(Usina usina) async => usina;

  @override
  Future<void> excluir(String usinaId) async {
    usinas.removeWhere((u) => u.id == usinaId);
  }

  @override
  Future<List<MembroUsina>> listarMembros(String usinaId) async =>
      List.unmodifiable(membros);

  @override
  Future<MembroUsina> adicionarMembro({
    required String usinaId,
    required String nome,
    required String email,
  }) async {
    final m = MembroUsina(
      id: 'm-${membros.length + 1}',
      nome: nome,
      email: email,
      cota: 0,
      status: 'Pendente',
    );
    membros.add(m);
    return m;
  }

  @override
  Future<List<MembroUsina>> atualizarCotas(
    String usinaId,
    List<CotaAtualizacao> cotas,
  ) async {
    ultimasCotasSalvas = cotas;
    for (var i = 0; i < membros.length; i++) {
      final match = cotas.where((c) => c.membroId == membros[i].id).firstOrNull;
      if (match != null) {
        membros[i] = MembroUsina(
          id: membros[i].id,
          nome: membros[i].nome,
          email: membros[i].email,
          cota: match.percentual,
          status: match.percentual > 0 ? 'Ativo' : 'Pendente',
        );
      }
    }
    return List.unmodifiable(membros);
  }

  @override
  Future<ContratoUsina?> buscarContrato(String usinaId) async => contrato;

  @override
  Future<ContratoUsina> salvarContrato(
    String usinaId,
    String nomeArquivo,
    Uint8List conteudo,
  ) async {
    contrato = ContratoUsina(
      usinaId: usinaId,
      nomeArquivo: nomeArquivo,
      tamanhoBytes: conteudo.length,
      dataEnvio: DateTime(2026, 11, 1),
    );
    return contrato!;
  }

  @override
  Future<void> excluirContrato(String usinaId) async {
    contrato = null;
  }
}

void main() {
  testWidgets('mostra o resumo da usina na tela inicial', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: UsinaPage()));
    await tester.pumpAndSettle();

    expect(find.text('Gerenciamento da planta solar'), findsOneWidget);
    expect(find.text('Solis SP-Norte-01'), findsOneWidget);
    expect(find.text('Cadastro da Usina'), findsOneWidget);
  });

  testWidgets('abre o formulário de cadastro da usina', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: UsinaPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastro da Usina'));
    await tester.pumpAndSettle();

    expect(find.text('NOME DA USINA'), findsOneWidget);
    expect(find.text('POTÊNCIA INSTALADA'), findsOneWidget);
    expect(find.text('Salvar usina'), findsOneWidget);
  });

  testWidgets('carrega dados reais e persiste nova usina e cotas via repositório', (
    WidgetTester tester,
  ) async {
    final repo = _RepositorioUsinaTeste();

    await tester.pumpWidget(MaterialApp(home: UsinaPage(repositorio: repo)));
    await tester.pumpAndSettle();

    expect(find.text('Usina Teste Real'), findsOneWidget);

    await tester.tap(find.text('Cadastro da Usina'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Usina Campinas II');
    await tester.enterText(find.byType(TextField).at(1), '120');
    await tester.tap(find.text('Salvar usina'));
    await tester.pumpAndSettle();

    expect(repo.ultimaCriada?.nome, 'Usina Campinas II');
    expect(repo.ultimaCriada?.potencia, 120);
    expect(find.text('COTA TOTAL DISTRIBUÍDA'), findsOneWidget);
    expect(find.text('Carlos Pereira'), findsOneWidget);

    await tester.tap(find.text('Salvar cotas'));
    await tester.pumpAndSettle();

    expect(repo.ultimasCotasSalvas?.single.percentual, 60);
    expect(find.text('Contrato do Consórcio'), findsOneWidget);
  });
}
