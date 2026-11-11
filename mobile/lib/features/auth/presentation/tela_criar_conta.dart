//Autora: Ana Luísa Maso Mafra | RA: 25007997

import 'package:flutter/material.dart';

import '../data/servico_auth.dart';
import '../domain/cpf.dart';
import '../domain/validadores.dart';
import 'tela_criar_conta_passo2.dart';
import 'widgets_auth.dart';

class TelaCriarConta extends StatefulWidget {
  const TelaCriarConta({super.key, this.servicoAuth, this.destinoAposCadastro});

  // permitem trocar o serviço e a tela seguinte (útil nos testes)
  final ServicoAuth? servicoAuth;
  final Widget Function(BuildContext contexto, String email)? destinoAposCadastro;

  @override
  State<TelaCriarConta> createState() => _EstadoTelaCriarConta();
}

class _EstadoTelaCriarConta extends State<TelaCriarConta> {
  final _formulario = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _cpf = TextEditingController();
  String _tipoConta = 'membro'; // 'membro' ou 'admin'

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _cpf.dispose();
    super.dispose();
  }

  void _continuar() {
    if (!_formulario.currentState!.validate()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TelaCriarContaPasso2(
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          cpf: cpfSoDigitos(_cpf.text),
          tipoConta: _tipoConta,
          servicoAuth: widget.servicoAuth,
          destinoAposCadastro: widget.destinoAposCadastro,
        ),
      ),
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
          CampoAuth(
            rotulo: 'CPF',
            dica: '000.000.000-00',
            controlador: _cpf,
            tipoTeclado: TextInputType.number,
            formatadores: [MascaraCpf()],
            validador: validarCpf,
          ),
          const SizedBox(height: 16),
          _seletorTipoConta(),
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

  // "Quero me cadastrar como": membro ou administrador
  Widget _seletorTipoConta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quero me cadastrar como',
          style: TextStyle(
            color: corPrimaria,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _opcaoTipoConta('membro', 'Membro', Icons.person_outline),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _opcaoTipoConta(
                'admin',
                'Administrador',
                Icons.shield_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _opcaoTipoConta(String valor, String rotulo, IconData icone) {
    final selecionado = _tipoConta == valor;
    return Material(
      color: selecionado ? corPrimaria : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _tipoConta = valor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selecionado ? corPrimaria : const Color(0xFFE3E6EB),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icone,
                  size: 18,
                  color: selecionado ? Colors.white : corPrimaria,
                ),
                const SizedBox(width: 8),
                Text(
                  rotulo,
                  style: TextStyle(
                    color: selecionado ? Colors.white : corPrimaria,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
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
