//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// tela "Editar perfil": nome, e-mail e telefone
// ao salvar, volta para o Perfil devolvendo o perfil já atualizado

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth/domain/validadores.dart';
import '../../auth/presentation/widgets_auth.dart';
import '../domain/formatadores_perfil.dart';
import '../domain/repositorio_perfil.dart';
import 'widgets_perfil.dart';

class TelaEditarPerfil extends StatefulWidget {
  const TelaEditarPerfil({
    super.key,
    required this.repositorio,
    required this.perfil,
  });

  final RepositorioPerfil repositorio;
  final PerfilMembro perfil;

  @override
  State<TelaEditarPerfil> createState() => _EstadoTelaEditarPerfil();
}

class _EstadoTelaEditarPerfil extends State<TelaEditarPerfil> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.perfil.nome);
    _email = TextEditingController(text: widget.perfil.email);
    _telefone = TextEditingController(
      text: formatarTelefone(widget.perfil.telefone),
    );
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final telefone = telefoneSoDigitos(_telefone.text);
      final atualizado = await widget.repositorio.editarPerfil(
        membroId: widget.perfil.id,
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        telefone: telefone.isEmpty ? null : telefone,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
      Navigator.of(context).pop(atualizado);
    } catch (erro) {
      if (!mounted) return;
      // se a API apontou o campo com problema, mostra o erro dele
      var mensagem = mensagemDeErro(erro);
      if (erro is ErroApiPerfil && erro.campos.isNotEmpty) {
        mensagem = erro.campos.values.first;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EstruturaAuth(
      cabecalho: const Align(
        alignment: Alignment.centerLeft,
        child: CabecalhoTelaInterna(titulo: 'Editar perfil'),
      ),
      conteudo: Form(
        key: _formulario,
        child: Column(
          children: [
            CampoAuth(
              rotulo: 'Nome completo',
              dica: 'Seu nome e sobrenome',
              controlador: _nome,
              validador: validarNome,
            ),
            const SizedBox(height: 18),
            CampoAuth(
              rotulo: 'E-mail',
              dica: 'seu@email.com',
              controlador: _email,
              tipoTeclado: TextInputType.emailAddress,
              validador: validarEmail,
            ),
            const SizedBox(height: 18),
            CampoAuth(
              rotulo: 'Telefone (opcional)',
              dica: '(00) 00000-0000',
              controlador: _telefone,
              tipoTeclado: TextInputType.phone,
              formatadores: [MascaraTelefone()],
              validador: validarTelefone,
            ),
            const SizedBox(height: 28),
            BotaoPrincipalAuth(
              texto: 'Salvar alterações',
              carregando: _salvando,
              aoPressionar: _salvar,
            ),
          ],
        ),
      ),
    );
  }
}
