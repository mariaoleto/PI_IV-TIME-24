// significado do arquivo:
// recuperação de senha em 2 etapas, na mesma tela:
//   1) informa o e-mail e recebe um código de 6 dígitos (válido por 15 minutos)
//   2) digita o código e define a nova senha
// por segurança, o app (e o backend) não revelam se o e-mail está cadastrado

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/servico_auth.dart';
import '../domain/validadores.dart';
import 'widgets_auth.dart';

class TelaRecuperarSenha extends StatefulWidget {
  const TelaRecuperarSenha({super.key, this.servicoAuth, this.emailInicial});

  final ServicoAuth? servicoAuth; // permite trocar o serviço (útil nos testes)
  final String? emailInicial; // se a pessoa já digitou o e-mail no login

  @override
  State<TelaRecuperarSenha> createState() => _EstadoTelaRecuperarSenha();
}

class _EstadoTelaRecuperarSenha extends State<TelaRecuperarSenha> {
  final _formularioEmail = GlobalKey<FormState>();
  final _formularioCodigo = GlobalKey<FormState>();
  late final ServicoAuth _auth = widget.servicoAuth ?? ServicoAuthApi();
  late final TextEditingController _email = TextEditingController(
    text: widget.emailInicial ?? '',
  );
  final _codigo = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmacao = TextEditingController();

  bool _codigoEnviado = false; // false = etapa 1, true = etapa 2
  bool _carregando = false;

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    _novaSenha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String _textoDoErro(Object erro) {
    if (erro is ErroApiAuth && erro.campos.isNotEmpty) {
      return erro.campos.values.first;
    }
    return erro.toString().replaceFirst('Exception: ', '');
  }

  // etapa 1 (e "reenviar código")
  Future<void> _enviarCodigo({bool reenvio = false}) async {
    if (!_formularioEmail.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      await _auth.solicitarRecuperacao(email: _email.text.trim());
      if (!mounted) return;
      setState(() {
        _codigoEnviado = true;
        _carregando = false;
      });
      if (reenvio) {
        _mostrarMensagem(
          'Se o e-mail estiver cadastrado, enviamos um novo código.',
        );
      }
    } catch (erro) {
      if (!mounted) return;
      _mostrarMensagem(_textoDoErro(erro));
      setState(() => _carregando = false);
    }
  }

  // etapa 2
  Future<void> _redefinirSenha() async {
    if (!_formularioCodigo.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      await _auth.redefinirSenha(
        email: _email.text.trim(),
        codigo: _codigo.text.trim(),
        novaSenha: _novaSenha.text,
      );
      if (!mounted) return;
      _mostrarMensagem('Senha redefinida com sucesso. Entre com a nova senha.');
      Navigator.of(context).pop(); // volta para o login
    } catch (erro) {
      if (!mounted) return;
      _mostrarMensagem(_textoDoErro(erro));
      setState(() => _carregando = false);
    }
  }

  String? _validarCodigo(String? valor) {
    if (!RegExp(r'^\d{6}$').hasMatch((valor ?? '').trim())) {
      return 'Digite o código de 6 dígitos';
    }
    return null;
  }

  String? _validarConfirmacao(String? valor) {
    if ((valor ?? '').isEmpty) return 'Confirme a nova senha';
    if (valor != _novaSenha.text) return 'As senhas não conferem';
    return null;
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
            const Text(
              'Recuperar senha',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _codigoEnviado
                  ? 'Digite o código e escolha a nova senha'
                  : 'Enviaremos um código para o seu e-mail',
              style: const TextStyle(color: Color(0xFF9AA5B8), fontSize: 13),
            ),
          ],
        ),
      ),
      conteudo: _codigoEnviado ? _etapaCodigo() : _etapaEmail(),
    );
  }

  Widget _etapaEmail() {
    return Form(
      key: _formularioEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CampoAuth(
            rotulo: 'E-mail',
            dica: 'seu@email.com',
            controlador: _email,
            tipoTeclado: TextInputType.emailAddress,
            autofocus: true,
            validador: validarEmail,
          ),
          const SizedBox(height: 24),
          BotaoPrincipalAuth(
            texto: 'Enviar código',
            aoPressionar: _enviarCodigo,
            carregando: _carregando,
          ),
        ],
      ),
    );
  }

  Widget _etapaCodigo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E6EB)),
          ),
          child: Text(
            'Se ${_email.text.trim()} estiver cadastrado, enviamos um código '
            'de 6 dígitos. Ele vale por 15 minutos.',
            style: const TextStyle(
              color: Color(0xFF5B6472),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Form(
          key: _formularioCodigo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CampoAuth(
                rotulo: 'Código',
                dica: '000000',
                controlador: _codigo,
                tipoTeclado: TextInputType.number,
                autofocus: true,
                formatadores: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validador: _validarCodigo,
              ),
              const SizedBox(height: 16),
              CampoAuth(
                rotulo: 'Nova senha',
                dica: 'Mínimo de 6 caracteres',
                controlador: _novaSenha,
                senha: true,
                validador: validarSenha,
              ),
              const SizedBox(height: 16),
              CampoAuth(
                rotulo: 'Confirmar nova senha',
                dica: 'Repita a nova senha',
                controlador: _confirmacao,
                senha: true,
                validador: _validarConfirmacao,
              ),
              const SizedBox(height: 24),
              BotaoPrincipalAuth(
                texto: 'Redefinir senha',
                aoPressionar: _redefinirSenha,
                carregando: _carregando,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Wrap(
            spacing: 18,
            children: [
              GestureDetector(
                onTap: _carregando ? null : () => _enviarCodigo(reenvio: true),
                child: const Text(
                  'Reenviar código',
                  style: TextStyle(
                    color: corPrimaria,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _carregando
                    ? null
                    : () => setState(() => _codigoEnviado = false),
                child: const Text(
                  'Trocar e-mail',
                  style: TextStyle(
                    color: corPrimaria,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
