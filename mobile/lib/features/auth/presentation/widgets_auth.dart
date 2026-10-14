import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color corFundoEscuro = Color(0xFF0B1830);
const Color corPrimaria = Color(0xFF142340);
const Color corDestaque = Color(0xFFF4A12B);
const Color corFundoCartao = Color(0xFFF7F8FA);

/// Estrutura comum das telas de autenticação: cabeçalho escuro + cartão claro.
class EstruturaAuth extends StatelessWidget {
  const EstruturaAuth({
    super.key,
    required this.cabecalho,
    required this.conteudo,
    this.rodape,
  });

  final Widget cabecalho;
  final Widget conteudo;
  final Widget? rodape;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: corFundoEscuro,
        body: Column(
          children: [
            SafeArea(bottom: false, child: cabecalho),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: corFundoCartao,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                          child: conteudo,
                        ),
                      ),
                      if (rodape != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: rodape,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo oficial do Solis (assets/logo_solis.png) em um cartão branco,
/// já que o logo tem letras azul-escuro e não aparece sobre o fundo escuro.
class LogoSolis extends StatelessWidget {
  const LogoSolis({super.key, required this.subtitulo, this.selo});

  final String subtitulo;
  final Widget? selo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: corDestaque.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo_solis.png',
                width: 150,
                fit: BoxFit.contain,
              ),
            ),
            if (selo != null) Positioned(right: -6, bottom: -6, child: selo!),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          subtitulo,
          style: const TextStyle(color: Color(0xFF9AA5B8), fontSize: 13),
        ),
      ],
    );
  }
}

class CampoAuth extends StatefulWidget {
  const CampoAuth({
    super.key,
    required this.rotulo,
    required this.dica,
    this.controlador,
    this.senha = false,
    this.tipoTeclado,
    this.autofocus = false,
    this.validador,
  });

  final String rotulo;
  final String dica;
  final TextEditingController? controlador;
  final bool senha;
  final TextInputType? tipoTeclado;
  final bool autofocus;
  final String? Function(String?)? validador;

  @override
  State<CampoAuth> createState() => _EstadoCampoAuth();
}

class _EstadoCampoAuth extends State<CampoAuth> {
  bool _oculta = true;

  OutlineInputBorder _borda(Color cor, [double largura = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cor, width: largura),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.rotulo,
          style: const TextStyle(
            color: corPrimaria,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controlador,
          obscureText: widget.senha && _oculta,
          keyboardType: widget.tipoTeclado,
          autofocus: widget.autofocus,
          validator: widget.validador,
          style: const TextStyle(color: corPrimaria, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.dica,
            hintStyle: const TextStyle(color: Color(0xFF9AA2AF)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: _borda(const Color(0xFFD5D9E0)),
            enabledBorder: _borda(const Color(0xFFD5D9E0)),
            focusedBorder: _borda(corPrimaria, 1.5),
            errorBorder: _borda(Colors.red.shade400),
            focusedErrorBorder: _borda(Colors.red.shade400, 1.5),
            suffixIcon: widget.senha
                ? IconButton(
                    icon: Icon(
                      _oculta
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF4B5563),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _oculta = !_oculta),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class BotaoPrincipalAuth extends StatelessWidget {
  const BotaoPrincipalAuth({
    super.key,
    required this.texto,
    required this.aoPressionar,
    this.carregando = false,
  });

  final String texto;
  final VoidCallback? aoPressionar;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: corPrimaria.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: carregando ? null : aoPressionar,
        style: ElevatedButton.styleFrom(
          backgroundColor: corPrimaria,
          disabledBackgroundColor: corPrimaria,
          disabledForegroundColor: Colors.white,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

/// Texto "Pergunta? **Ação**" usado no rodapé das telas.
class LinkAuth extends StatelessWidget {
  const LinkAuth({
    super.key,
    required this.pergunta,
    required this.acao,
    required this.aoPressionar,
  });

  final String pergunta;
  final String acao;
  final VoidCallback aoPressionar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          pergunta,
          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: aoPressionar,
          child: Text(
            acao,
            style: const TextStyle(
              color: corPrimaria,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
