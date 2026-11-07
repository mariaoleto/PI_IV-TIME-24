//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// testes das telas de Perfil do membro (perfil, editar, segurança) e dos formatadores

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/geracao_creditos/domain/repositorio_energia.dart';
import 'package:mobile/features/geracao_creditos/presentation/tela_energia.dart';
import 'package:mobile/features/perfil/domain/formatadores_perfil.dart';
import 'package:mobile/features/perfil/domain/repositorio_perfil.dart';
import 'package:mobile/features/perfil/presentation/tela_editar_perfil.dart';
import 'package:mobile/features/perfil/presentation/tela_perfil.dart';
import 'package:mobile/features/perfil/presentation/tela_seguranca.dart';

PerfilMembro _perfil({bool admin = false}) => PerfilMembro(
  id: '507f1f77bcf86cd799439011',
  nome: 'João Oliveira',
  inicial: 'J',
  email: 'joao@email.com',
  telefone: '19999998888',
  ehAdmin: admin,
  cotaPercentual: 25,
  membroDesde: DateTime.utc(2025, 3, 10),
  usina: const UsinaPerfil(
    id: 'u1',
    nome: 'Usina Solis',
    localizacao: 'Campinas - SP',
  ),
);

class RepositorioPerfilFalso implements RepositorioPerfil {
  RepositorioPerfilFalso({this.admin = false});

  final bool admin;
  String? senhaAtualEnviada;
  String? novaSenhaEnviada;
  String? nomeEnviado;
  String? telefoneEnviado;

  @override
  Future<PerfilMembro> buscarPerfil({String? membroId, String? email}) async =>
      _perfil(admin: admin);

  @override
  Future<PerfilMembro> editarPerfil({
    required String membroId,
    required String nome,
    required String email,
    String? telefone,
  }) async {
    nomeEnviado = nome;
    telefoneEnviado = telefone;
    return _perfil(admin: admin);
  }

  @override
  Future<void> alterarSenha({
    required String membroId,
    required String senhaAtual,
    required String novaSenha,
  }) async {
    senhaAtualEnviada = senhaAtual;
    novaSenhaEnviada = novaSenha;
  }

  @override
  Future<ContratoConsorcio?> buscarContrato(String membroId) async => null;
}

// abre a tela por cima de outra rota, como no app (assim o pop() ao salvar funciona)
Widget _abrirPorCima(Widget tela) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => tela),
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  ),
);

class RepositorioEnergiaFalso implements RepositorioEnergia {
  @override
  Future<ResumoEnergia> buscarResumo({
    int? ano,
    String? usinaId,
    String? membroId,
  }) async => ResumoEnergia.exemplo();

  @override
  Future<List<CotaMembro>> buscarCotasDistribuicao({String? usinaId}) async =>
      const [];

  @override
  Future<bool> salvarLancamentoMensal({
    required String mesReferencia,
    required double geracaoKwh,
    String? usinaId,
  }) async => true;
}

void main() {
  group('formatadores', () {
    test('telefone: máscara e validação', () {
      expect(formatarTelefone('19999998888'), '(19) 99999-8888');
      expect(formatarTelefone('1933334444'), '(19) 3333-4444');
      expect(formatarTelefone(''), '');
      expect(validarTelefone(''), isNull); // opcional
      expect(validarTelefone('(19) 99999-8888'), isNull);
      expect(validarTelefone('12345'), isNotNull);
      expect(validarTelefone('19899998888'), isNotNull); // celular sem 9
      expect(telefoneSoDigitos('(19) 99999-8888'), '19999998888');
    });

    test('datas e números', () {
      expect(formatarMesAno(DateTime.utc(2025, 3, 10)), 'mar/2025');
      expect(formatarData(DateTime.utc(2025, 3, 10)), '10/03/2025');
      expect(formatarData(null), '—');
      expect(formatarPercentual(25), '25%');
      expect(formatarPercentual(12.5), '12,5%');
      expect(formatarTarifa(0.69), 'R\$ 0,69/kWh');
    });
  });

  group('TelaPerfil', () {
    testWidgets('mostra avatar, dados, card do consórcio e menu (membro comum)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pumpWidget(
        MaterialApp(
          home: TelaPerfil(
            repositorio: RepositorioPerfilFalso(),
            email: 'joao@email.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('J'), findsOneWidget); // avatar
      expect(find.text('João Oliveira'), findsOneWidget);
      expect(find.text('joao@email.com'), findsOneWidget);
      expect(find.text('Meu consórcio'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('mar/2025'), findsOneWidget);
      expect(find.text('Usina Solis'), findsOneWidget);
      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.text('Segurança'), findsOneWidget);
      expect(find.text('Contrato do consórcio'), findsOneWidget);
      expect(find.text('Sair da conta'), findsOneWidget);
      expect(find.text('Painel Administrador'), findsNothing);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('admin vê e usa o botão Painel Administrador', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      PerfilMembro? aberto;
      await tester.pumpWidget(
        MaterialApp(
          home: TelaPerfil(
            repositorio: RepositorioPerfilFalso(admin: true),
            email: 'joao@email.com',
            aoAbrirPainelAdmin: (perfil) => aberto = perfil,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Painel Administrador'), findsOneWidget);
      await tester.tap(find.text('Painel Administrador'));
      expect(aberto?.nome, 'João Oliveira');

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Sair da conta pede confirmação antes de sair', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      var saiu = false;
      await tester.pumpWidget(
        MaterialApp(
          home: TelaPerfil(
            repositorio: RepositorioPerfilFalso(),
            email: 'joao@email.com',
            aoSair: () => saiu = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(saiu, isFalse);

      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(saiu, isTrue);

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('TelaEditarPerfil', () {
    testWidgets('preenche os campos, valida e envia os dados', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final repositorio = RepositorioPerfilFalso();
      await tester.pumpWidget(
        _abrirPorCima(
          TelaEditarPerfil(repositorio: repositorio, perfil: _perfil()),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('João Oliveira'), findsOneWidget);
      expect(find.text('(19) 99999-8888'), findsOneWidget);

      // nome sem sobrenome não deixa salvar
      await tester.enterText(find.byType(TextFormField).first, 'João');
      await tester.tap(find.text('Salvar alterações'));
      await tester.pump();
      expect(find.text('Informe nome e sobrenome'), findsOneWidget);
      expect(repositorio.nomeEnviado, isNull);

      await tester.enterText(find.byType(TextFormField).first, 'João Silva');
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();
      expect(repositorio.nomeEnviado, 'João Silva');
      expect(repositorio.telefoneEnviado, '19999998888');

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('TelaSeguranca', () {
    testWidgets('exige confirmação igual e envia a troca de senha', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final repositorio = RepositorioPerfilFalso();
      await tester.pumpWidget(
        _abrirPorCima(TelaSeguranca(repositorio: repositorio, membroId: 'm1')),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'antiga123');
      await tester.enterText(campos.at(1), 'nova12345');
      await tester.enterText(campos.at(2), 'diferente1');
      await tester.tap(find.text('Alterar senha').last);
      await tester.pump();
      expect(find.text('As senhas não conferem'), findsOneWidget);
      expect(repositorio.novaSenhaEnviada, isNull);

      await tester.enterText(campos.at(2), 'nova12345');
      await tester.tap(find.text('Alterar senha').last);
      await tester.pumpAndSettle();
      expect(repositorio.senhaAtualEnviada, 'antiga123');
      expect(repositorio.novaSenhaEnviada, 'nova12345');

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Aba Perfil na tela Energia', () {
    testWidgets('tocar em Perfil na barra inferior abre o perfil', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      await tester.pumpWidget(
        MaterialApp(
          home: TelaEnergia(
            repositorio: RepositorioEnergiaFalso(),
            emailMembro: 'joao@email.com',
            repositorioPerfil: RepositorioPerfilFalso(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      // chegou na tela de Perfil, com os dados do membro
      expect(find.text('João Oliveira'), findsOneWidget);
      expect(find.text('Meu consórcio'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
