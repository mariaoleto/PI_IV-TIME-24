import 'package:flutter/material.dart';

import '../../painel_membro/domain/repositorio_painel_membro.dart';
import '../../painel_membro/presentation/tela_painel_membro.dart';
import '../data/servico_auth.dart';
import '../domain/validadores.dart';
import 'tela_criar_conta.dart';
import 'tela_login_admin.dart';
import 'widgets_auth.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _EstadoTelaLogin();
}

class _EstadoTelaLogin extends State<TelaLogin> {
  final _formulario = GlobalKey<FormState>();
  final ServicoAuth _auth = ServicoAuthLocal();
  bool _carregando = false;
  final _email = TextEditingController();
  final _senha = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      await _auth.entrarMembro(email: _email.text.trim(), senha: _senha.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TelaPainelMembro(
            repositorio: RepositorioApiPainelMembro(),
            emailMembro: _email.text.trim(),
          ),
        ),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro.toString().replaceFirst('Exception: ', '')),
        ),
      );
      setState(() => _carregando = false);
    }
  }

  void _esqueciSenha() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recuperação de senha em breve.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EstruturaAuth(
      cabecalho: const Padding(
        padding: EdgeInsets.only(top: 16, bottom: 28),
        child: Center(
          child: LogoSolis(subtitulo: 'Energia solar compartilhada'),
        ),
      ),
      conteudo: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bem-vindo de volta',
              style: TextStyle(
                color: corPrimaria,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Acesse seus créditos e geração solar',
              style: TextStyle(color: Color(0xFF5B6472), fontSize: 13),
            ),
            const SizedBox(height: 24),
            CampoAuth(
              rotulo: 'E-mail',
              dica: 'seu@email.com',
              controlador: _email,
              tipoTeclado: TextInputType.emailAddress,
              validador: validarEmail,
            ),
            const SizedBox(height: 16),
            CampoAuth(
              rotulo: 'Senha',
              dica: '••••••••',
              controlador: _senha,
              senha: true,
              validador: validarSenha,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _esqueciSenha,
                child: const Text(
                  'Esqueci a senha',
                  style: TextStyle(
                    color: corPrimaria,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            BotaoPrincipalAuth(
              texto: 'Entrar',
              aoPressionar: _entrar,
              carregando: _carregando,
            ),
            const SizedBox(height: 24),
            LinkAuth(
              pergunta: 'Não tem conta?',
              acao: 'Criar conta',
              aoPressionar: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const TelaCriarConta())),
            ),
          ],
        ),
      ),
      rodape: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Solis v1.0 · Dados protegidos com criptografia',
            style: TextStyle(color: Color(0xFFB0B6C0), fontSize: 11),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const TelaLoginAdmin())),
            child: const Text(
              'Entrar como administrador',
              style: TextStyle(
                color: Color(0xFF5B6472),
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
