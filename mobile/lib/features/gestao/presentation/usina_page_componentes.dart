// Autora: Marina Hehnes Espósito.
// Propósito: reúne os componentes visuais compartilhados pela tela da usina.
part of 'usina_page.dart';

mixin _UsinaPageComponentes on _UsinaPageStateBase {
  @override
  Widget _navegacaoInferior() {
    final indiceAtual = _screen == 2 ? 2 : 1;
    return BarraNavegacaoAdmin(
      indiceSelecionado: indiceAtual,
      aoMudarAba: (destino) {
        if (destino == 1) {
          setState(() => _screen = 0);
          return;
        }
        if (destino == 2) {
          _abrirCotas();
          return;
        }
        navegarAbaAdmin(
          context,
          indiceAtual: indiceAtual,
          indiceDestino: destino,
          nomeAdmin: widget.nomeAdmin,
          usinaId: _usinaSelecionadaId ?? widget.usinaIdInicial,
          repositorioPainel: widget.repositorioPainel,
          repositorioEnergia: widget.repositorioEnergia,
          repositorioUsina: widget.repositorio,
          repositorioPerfil: widget.repositorioPerfil,
          aoSincronizarPainel: widget.aoSincronizarPainel,
        );
      },
    );
  }

  @override
  Widget _botaoInferior(String texto, VoidCallback acao) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 13),
      color: background,
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: FilledButton(
          onPressed: _salvando ? null : acao,
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: _salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget _cartao({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172B4D).withValues(alpha: .035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget _icone(IconData icon, Color fundo, Color cor) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: cor, size: 18),
    );
  }

  @override
  Widget _rotulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        color: muted,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: .3,
      ),
    );
  }

  @override
  InputDecoration _decoracao({String? hint, String? sufixo}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFADB5C2), fontSize: 11),
      suffixText: sufixo,
      suffixStyle: const TextStyle(color: muted, fontSize: 10),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE0E5ED)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE0E5ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: navy, width: 1.2),
      ),
    );
  }

  @override
  Widget _status(String texto) {
    final pendente = texto.toLowerCase() == 'pendente';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: pendente ? const Color(0xFFFFF0D6) : const Color(0xFFE5F8EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: pendente ? const Color(0xFFB87913) : const Color(0xFF26945A),
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
