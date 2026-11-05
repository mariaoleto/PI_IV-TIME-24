//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// tela "Segurança": alterar senha (senha atual, nova senha e confirmação)

import 'package:flutter/material.dart';

import '../../auth/domain/validadores.dart';
import '../../auth/presentation/widgets_auth.dart';
import '../domain/repositorio_perfil.dart';
import 'widgets_perfil.dart';

class TelaSeguranca extends StatefulWidget {
  const TelaSeguranca({
    super.key,
    required this.repositorio,
    required this.membroId,
  });

  final RepositorioPerfil repositorio;
  final String membroId;

  @override
  State<TelaSeguranca> createState() => _EstadoTelaSeguranca();
}

class _EstadoTelaSeguranca extends State<TelaSeguranca> {
  final _formulario = GlobalKey<FormState>();
  final _senhaAtual = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _senhaAtual.dispose();
    _novaSenha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  String? _validarSenhaAtual(String? valor) {
    if ((valor ?? '').isEmpty) return 'Informe sua senha atual';
    return null;
  }

  String? _validarNovaSenha(String? valor) {
    final erro = validarSenha(valor);
    if (erro != null) return erro;
    if (valor == _senhaAtual.text) {
      return 'A nova senha deve ser diferente da atual';
    }
    return null;
  }

  String? _validarConfirmacao(String? valor) {
    if ((valor ?? '').isEmpty) return 'Confirme a nova senha';
    if (valor != _novaSenha.text) return 'As senhas não conferem';
    return null;
  }

  Future<void> _salvar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await widget.repositorio.alterarSenha(
        membroId: widget.membroId,
        senhaAtual: _senhaAtual.text,
        novaSenha: _novaSenha.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada com sucesso.')),
      );
      Navigator.of(context).pop();
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemDeErro(erro))),
      );
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EstruturaAuth(
      cabecalho: const Align(
        alignment: Alignment.centerLeft,
        child: CabecalhoTelaInterna(titulo: 'Segurança'),
      ),
      conteudo: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TituloSecao('Alterar senha'),
            CampoAuth(
              rotulo: 'Senha atual',
              dica: 'Digite sua senha atual',
              controlador: _senhaAtual,
              senha: true,
              validador: _validarSenhaAtual,
            ),
            const SizedBox(height: 18),
            CampoAuth(
              rotulo: 'Nova senha',
              dica: 'Mínimo de 6 caracteres',
              controlador: _novaSenha,
              senha: true,
              validador: _validarNovaSenha,
            ),
            const SizedBox(height: 18),
            CampoAuth(
              rotulo: 'Confirmar nova senha',
              dica: 'Repita a nova senha',
              controlador: _confirmacao,
              senha: true,
              validador: _validarConfirmacao,
            ),
            const SizedBox(height: 28),
            BotaoPrincipalAuth(
              texto: 'Alterar senha',
              carregando: _salvando,
              aoPressionar: _salvar,
            ),
          ],
        ),
      ),
    );
  }
}
