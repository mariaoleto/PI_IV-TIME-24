//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// tela de Perfil do membro: avatar, nome, e-mail, card do consórcio (cota, membro desde, usina),
// menu (Editar perfil, Segurança, Contrato do consórcio) e os botões
// "Painel Administrador" (somente para quem tem acesso) e "Sair da conta"

import 'package:flutter/material.dart';

import '../../auth/data/sessao_auth.dart';
import '../../auth/presentation/tela_login.dart';
import '../../auth/presentation/widgets_auth.dart';
import '../../geracao_creditos/domain/repositorio_energia.dart';
import '../../painel_admin/domain/repositorio_painel_admin.dart';
import '../../painel_admin/presentation/tela_painel_admin.dart';
import '../domain/formatadores_perfil.dart';
import '../domain/repositorio_perfil.dart';
import 'tela_contrato.dart';
import 'tela_editar_perfil.dart';
import 'tela_seguranca.dart';
import 'widgets_perfil.dart';

// abre a tela de Perfil por cima da tela atual
// usada pela aba "Perfil" do painel do membro e da tela Energia (todas as abas abrem o mesmo Perfil)
Future<void> abrirTelaPerfil(
  BuildContext context, {
  String? email,
  ValueChanged<PerfilMembro>? aoPerfilAtualizado,
  RepositorioPerfil? repositorio, // permite trocar o repositório (útil nos testes)
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => TelaPerfil(
        repositorio: repositorio ?? RepositorioApiPerfil(),
        email: email,
        aoPerfilAtualizado: aoPerfilAtualizado,
      ),
    ),
  );
}

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({
    super.key,
    required this.repositorio,
    this.email,
    this.membroId,
    this.aoPerfilAtualizado,
    this.aoAbrirPainelAdmin,
    this.aoSair,
  });

  final RepositorioPerfil repositorio;

  // o login do app só guarda o e-mail; o id vem do backend junto com o perfil
  final String? email;
  final String? membroId;

  // avisa quem abriu a tela (ex.: painel do membro) que nome/e-mail mudaram
  final ValueChanged<PerfilMembro>? aoPerfilAtualizado;

  // permitem trocar a navegação padrão (útil nos testes)
  final ValueChanged<PerfilMembro>? aoAbrirPainelAdmin;
  final VoidCallback? aoSair;

  @override
  State<TelaPerfil> createState() => _EstadoTelaPerfil();
}

class _EstadoTelaPerfil extends State<TelaPerfil> {
  PerfilMembro? _perfil;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final perfil = await widget.repositorio.buscarPerfil(
        membroId: widget.membroId,
        email: widget.email,
      );
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = mensagemDeErro(erro);
        _carregando = false;
      });
    }
  }

  Future<void> _editarPerfil(PerfilMembro perfil) async {
    final atualizado = await Navigator.of(context).push<PerfilMembro>(
      MaterialPageRoute(
        builder: (_) =>
            TelaEditarPerfil(repositorio: widget.repositorio, perfil: perfil),
      ),
    );
    if (atualizado == null || !mounted) return;
    setState(() => _perfil = atualizado);
    widget.aoPerfilAtualizado?.call(atualizado);
  }

  void _abrirSeguranca(PerfilMembro perfil) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TelaSeguranca(repositorio: widget.repositorio, membroId: perfil.id),
      ),
    );
  }

  void _abrirContrato(PerfilMembro perfil) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TelaContrato(repositorio: widget.repositorio, membroId: perfil.id),
      ),
    );
  }

  void _abrirPainelAdmin(PerfilMembro perfil) {
    final aoAbrir = widget.aoAbrirPainelAdmin;
    if (aoAbrir != null) {
      aoAbrir(perfil);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TelaPainelAdmin(
          repositorio: RepositorioApiPainelAdmin(),
          repositorioEnergia: RepositorioApiEnergia(),
          nomeAdmin: perfil.nome,
        ),
      ),
    );
  }

  Future<void> _sair() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contextoDialogo).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    SessaoAuth.instancia.limpar(); // apaga o token: a próxima pessoa precisa fazer login
    final aoSair = widget.aoSair;
    if (aoSair != null) {
      aoSair();
      return;
    }
    // volta para o login e apaga as telas anteriores (não dá para "voltar" para a conta)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TelaLogin()),
      (rota) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfil = _perfil;

    return EstruturaAuth(
      cabecalho: _CabecalhoPerfil(perfil: perfil),
      conteudo: _montarConteudo(perfil),
    );
  }

  Widget _montarConteudo(PerfilMembro? perfil) {
    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: corPrimaria)),
      );
    }
    if (perfil == null) {
      return EstadoErro(
        mensagem: _erro ?? 'Não foi possível carregar o perfil.',
        aoTentar: _carregar,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CartaoConsorcio(perfil: perfil),
        const SizedBox(height: 16),
        CartaoPerfil(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              ItemMenuPerfil(
                icone: Icons.edit_outlined,
                titulo: 'Editar perfil',
                subtitulo: 'Nome, e-mail e telefone',
                aoTocar: () => _editarPerfil(perfil),
              ),
              const Divider(height: 1),
              ItemMenuPerfil(
                icone: Icons.lock_outline,
                titulo: 'Segurança',
                subtitulo: 'Alterar senha',
                aoTocar: () => _abrirSeguranca(perfil),
              ),
              const Divider(height: 1),
              ItemMenuPerfil(
                icone: Icons.description_outlined,
                titulo: 'Contrato do consórcio',
                subtitulo: 'Visualizar condições e cláusulas',
                aoTocar: () => _abrirContrato(perfil),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (perfil.ehAdmin) ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _abrirPainelAdmin(perfil),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text(
                'Painel Administrador',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: corPrimaria,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _sair,
            icon: const Icon(Icons.logout),
            label: const Text(
              'Sair da conta',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// parte escura do topo: voltar, avatar, nome e e-mail
class _CabecalhoPerfil extends StatelessWidget {
  const _CabecalhoPerfil({required this.perfil});

  final PerfilMembro? perfil;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: CabecalhoTelaInterna(titulo: 'Perfil'),
        ),
        if (perfil != null) ...[
          AvatarPerfil(inicial: perfil!.inicial),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              perfil!.nome,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              perfil!.email,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9AA5B8), fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// card do consórcio: cota, membro desde e usina
class _CartaoConsorcio extends StatelessWidget {
  const _CartaoConsorcio({required this.perfil});

  final PerfilMembro perfil;

  @override
  Widget build(BuildContext context) {
    final usina = perfil.usina;

    return CartaoPerfil(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TituloSecao('Meu consórcio'),
          Row(
            children: [
              Expanded(
                child: _DadoConsorcio(
                  rotulo: 'Cota',
                  valor: formatarPercentual(perfil.cotaPercentual),
                ),
              ),
              Expanded(
                child: _DadoConsorcio(
                  rotulo: 'Membro desde',
                  valor: formatarMesAno(perfil.membroDesde),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DadoConsorcio(
            rotulo: 'Usina',
            valor: usina?.nome.isNotEmpty == true ? usina!.nome : '—',
            detalhe: usina?.localizacao,
          ),
        ],
      ),
    );
  }
}

class _DadoConsorcio extends StatelessWidget {
  const _DadoConsorcio({required this.rotulo, required this.valor, this.detalhe});

  final String rotulo;
  final String valor;
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: corPrimaria,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (detalhe != null) ...[
          const SizedBox(height: 2),
          Text(
            detalhe!,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}
