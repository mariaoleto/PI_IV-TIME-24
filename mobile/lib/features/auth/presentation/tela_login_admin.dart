import 'package:flutter/material.dart';

import '../../../src/geracao_consumos/repositorio_energia.dart';
import '../../../src/geracao_consumos/tela_energia.dart';
import '../data/servico_auth.dart';
import '../domain/validadores.dart';
import 'widgets_auth.dart';

class TelaLoginAdmin extends StatefulWidget {
  const TelaLoginAdmin({super.key});

  @override
  State<TelaLoginAdmin> createState() => _EstadoTelaLoginAdmin();
}

class _EstadoTelaLoginAdmin extends State<TelaLoginAdmin> {
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
      await _auth.entrarAdministrador(
        email: _email.text.trim(),
        senha: _senha.text,
      );
      if (!mounted) return;
      // TODO: trocar pelo painel do administrador quando fizermos.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TelaEnergia(repositorio: RepositorioApiEnergia()),
        ),
        (rota) => false,
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.toString().replaceFirst('Exception: ', ''))),
      );
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EstruturaAuth(
      cabecalho: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        child: Column(
          children: [
            LogoSolis(
            subtitulo: 'Área administrativa',
            selo: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: corDestaque,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: corFundoEscuro, width: 2),
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 12,
                color: corFundoEscuro,
              ),
            ),
            ),
            const SizedBox(height: 14),
            _etiquetaAdmin(),
          ],
        ),
      ),
      conteudo: Form(
        key: _formulario,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bem-vindo, Administrador',
            style: TextStyle(
              color: corPrimaria,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gerencie sua usina solar',
            style: TextStyle(color: Color(0xFF5B6472), fontSize: 13),
          ),
          const SizedBox(height: 24),
          CampoAuth(
            rotulo: 'E-mail administrativo',
            dica: 'admin@solis.com.br',
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
          const SizedBox(height: 22),
          BotaoPrincipalAuth(
            texto: 'Entrar',
            aoPressionar: _entrar,
            carregando: _carregando,
          ),
        ],
        ),
      ),
      rodape: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left, size: 18, color: corPrimaria),
                Text(
                  'Voltar para login de membro',
                  style: TextStyle(
                    color: corPrimaria,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Solis v1.0 · Acesso restrito a administradores',
            style: TextStyle(color: Color(0xFFB0B6C0), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _etiquetaAdmin() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: corFundoEscuro.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: corDestaque),
          SizedBox(width: 6),
          Text(
            'ACESSO ADMINISTRADOR',
            style: TextStyle(
              color: corDestaque,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
