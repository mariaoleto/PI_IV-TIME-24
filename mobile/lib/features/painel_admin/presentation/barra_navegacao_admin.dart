import 'package:flutter/material.dart';

import '../../auth/data/sessao_auth.dart';
import '../../geracao_creditos/domain/repositorio_energia.dart';
import '../../geracao_creditos/presentation/tela_lancamento_geracao.dart';
import '../../gestao/data/repositorio_usina.dart';
import '../../gestao/presentation/usina_page.dart';
import '../../perfil/domain/repositorio_perfil.dart';
import '../../perfil/presentation/tela_perfil.dart';
import '../domain/repositorio_painel_admin.dart';
import 'tela_painel_admin.dart';

class BarraNavegacaoAdmin extends StatelessWidget {
  const BarraNavegacaoAdmin({
    super.key,
    required this.indiceSelecionado,
    required this.aoMudarAba,
  });

  final int indiceSelecionado;
  final ValueChanged<int> aoMudarAba;

  @override
  Widget build(BuildContext context) {
    const itens = [
      (Icons.home_outlined, 'Início'),
      (Icons.desktop_windows_outlined, 'Usina'),
      (Icons.people_outline, 'Membros'),
      (Icons.bar_chart_outlined, 'Relatórios'),
      (Icons.person_outline, 'Perfil'),
    ];

    return NavigationBar(
      height: 64,
      selectedIndex: indiceSelecionado,
      onDestinationSelected: aoMudarAba,
      backgroundColor: Colors.white,
      indicatorColor: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black12,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        for (var i = 0; i < itens.length; i++)
          NavigationDestination(
            icon: Icon(
              itens[i].$1,
              color: i == indiceSelecionado
                  ? const Color(0xFF142340)
                  : const Color(0xFF7A8795),
            ),
            selectedIcon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE59828),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 3),
                Icon(itens[i].$1, color: const Color(0xFF142340)),
              ],
            ),
            label: itens[i].$2,
          ),
      ],
    );
  }
}

Future<void> navegarAbaAdmin(
  BuildContext context, {
  required int indiceAtual,
  required int indiceDestino,
  String? nomeAdmin,
  String? usinaId,
  RepositorioPainelAdmin? repositorioPainel,
  RepositorioEnergia? repositorioEnergia,
  RepositorioUsina? repositorioUsina,
  RepositorioPerfil? repositorioPerfil,
  VoidCallback? aoRetornarParaAtual,
  ValueChanged<String?>? aoRetornarComUsina,
  ValueChanged<String?>? aoSincronizarPainel,
}) async {
  if (indiceDestino == indiceAtual) return;

  final navegador = Navigator.of(context);

  if (indiceDestino == 0) {
    if (navegador.canPop()) {
      aoSincronizarPainel?.call(usinaId);
      navegador.pop(usinaId);
    } else {
      await navegador.pushReplacement(
        MaterialPageRoute(
          builder: (_) => TelaPainelAdmin(
            repositorio: repositorioPainel ?? RepositorioApiPainelAdmin(),
            repositorioEnergia: repositorioEnergia ?? RepositorioApiEnergia(),
            repositorioUsina: repositorioUsina,
            repositorioPerfil: repositorioPerfil,
            nomeAdmin: nomeAdmin,
            usinaId: usinaId,
          ),
        ),
      );
    }
    return;
  }

  if (indiceDestino == 1 || indiceDestino == 2) {
    final rotaUsina = MaterialPageRoute<String>(
      builder: (_) => UsinaPage(
        repositorio: repositorioUsina ?? RepositorioApiUsina(),
        telaInicial: indiceDestino == 2 ? 2 : 0,
        usinaIdInicial: usinaId,
        nomeAdmin: nomeAdmin,
        repositorioPainel: repositorioPainel,
        repositorioEnergia: repositorioEnergia,
        repositorioPerfil: repositorioPerfil,
        aoSincronizarPainel: aoSincronizarPainel,
      ),
    );
    if (indiceAtual == 0) {
      final retorno = await navegador.push<String>(rotaUsina);
      aoRetornarComUsina?.call(retorno);
      aoRetornarParaAtual?.call();
    } else {
      await navegador.pushReplacement(rotaUsina);
    }
    return;
  }

  if (indiceDestino == 3) {
    final rotaRegistro = MaterialPageRoute<String>(
      builder: (_) => TelaLancamentoGeracao(
        repositorio: repositorioEnergia ?? RepositorioApiEnergia(),
        usinaId: usinaId,
        nomeAdmin: nomeAdmin,
        repositorioPainel: repositorioPainel,
        repositorioUsina: repositorioUsina,
        repositorioPerfil: repositorioPerfil,
        aoSincronizarPainel: aoSincronizarPainel,
      ),
    );
    if (indiceAtual == 0) {
      final retorno = await navegador.push<String>(rotaRegistro);
      aoRetornarComUsina?.call(retorno);
      aoRetornarParaAtual?.call();
    } else {
      await navegador.pushReplacement(rotaRegistro);
    }
    return;
  }

  if (indiceDestino == 4) {
    await abrirTelaPerfil(
      context,
      email: SessaoAuth.instancia.usuario?.email,
      repositorio: repositorioPerfil,
    );
    aoRetornarParaAtual?.call();
  }
}

