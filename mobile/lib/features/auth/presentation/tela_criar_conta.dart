import 'package:flutter/material.dart';

import '../domain/validadores.dart';
import 'widgets_auth.dart';

class TelaCriarConta extends StatefulWidget {
  const TelaCriarConta({super.key});

  @override
  State<TelaCriarConta> createState() => _EstadoTelaCriarConta();
}

class _EstadoTelaCriarConta extends State<TelaCriarConta> {
  final _formulario = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    super.dispose();
  }

  void _continuar() {
    if (!_formulario.currentState!.validate()) return;
    // TODO: seguir para o passo 2 do cadastro (ainda não existe).
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passo 2 do cadastro em breve.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EstruturaAuth(
      cabecalho: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.chevron_left, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _barra(corDestaque)),
                const SizedBox(width: 8),
                Expanded(child: _barra(Colors.white.withValues(alpha: 0.2))),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'PASSO 1 DE 2',
              style: TextStyle(
                color: Color(0xFF9AA5B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Criar sua conta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Junte-se ao consórcio Solis',
              style: TextStyle(color: Color(0xFF9AA5B8), fontSize: 13),
            ),
          ],
        ),
      ),
      conteudo: Form(
        key: _formulario,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CampoAuth(
            rotulo: 'Nome completo',
            dica: 'Ex: João Oliveira',
            controlador: _nome,
            autofocus: true,
            validador: validarNome,
          ),
          const SizedBox(height: 16),
          CampoAuth(
            rotulo: 'E-mail',
            dica: 'seu@email.com',
            controlador: _email,
            tipoTeclado: TextInputType.emailAddress,
            validador: validarEmail,
          ),
          const SizedBox(height: 16),
          _cartaoInformativo(),
          const SizedBox(height: 16),
          BotaoPrincipalAuth(texto: 'Continuar', aoPressionar: _continuar),
          const SizedBox(height: 20),
          LinkAuth(
            pergunta: 'Já tem conta?',
            acao: 'Entrar',
            aoPressionar: () => Navigator.of(context).maybePop(),
          ),
        ],
        ),
      ),
    );
  }

  Widget _barra(Color cor) => Container(
    height: 4,
    decoration: BoxDecoration(
      color: cor,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _cartaoInformativo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E6EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF1E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wb_sunny_outlined,
                color: corDestaque, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O que é o Solis?',
                  style: TextStyle(
                    color: corPrimaria,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Você compartilha uma usina fotovoltaica e recebe créditos '
                  'de energia proporcionais à sua cota no consórcio.',
                  style: TextStyle(
                    color: Color(0xFF5B6472),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
