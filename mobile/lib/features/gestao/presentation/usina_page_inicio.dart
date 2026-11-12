// Autora: Marina Hehnes Espósito.
// Propósito: apresenta o resumo e a tela inicial da gestão da usina.
part of 'usina_page.dart';

mixin _UsinaPageInicio on _UsinaPageStateBase {
  @override
  Widget _cabecalho(String titulo, String subtitulo) {
    final podeVoltarRota = Navigator.of(context).canPop();
    final podeVoltarInterno = _screen != widget.telaInicial && _screen != 0;
    final mostraVoltar = podeVoltarInterno || podeVoltarRota;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 17),
      color: navy,
      child: Row(
        children: [
          if (mostraVoltar)
            IconButton(
              onPressed: () {
                if (_screen == widget.telaInicial && podeVoltarRota) {
                  Navigator.of(context).pop(_usinaSelecionadaId);
                  return;
                }
                if (_screen != 0) {
                  setState(() {
                    if (_screen == 1) {
                      _screen = 0;
                    } else if (_screen == 2) {
                      _screen = widget.telaInicial == 2 ? 0 : 1;
                    } else {
                      _screen = 2;
                    }
                  });
                } else if (podeVoltarRota) {
                  Navigator.of(context).pop(_usinaSelecionadaId);
                }
              },
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            )
          else
            const Icon(Icons.bolt, color: Colors.white, size: 23),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: Color(0xFFCFD7E5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget _telaInicial() {
    final idxSelecionada = _usinas.indexWhere(
      (u) => u['id'] == _usinaSelecionadaId,
    );
    final usina = _usinas.isEmpty
        ? null
        : _usinas[idxSelecionada >= 0 ? idxSelecionada : 0];

    return Column(
      children: [
        _cabecalho('Usina', 'Gerenciamento da planta solar'),
        Expanded(
          child: _carregando && _usinas.isEmpty
              ? const Center(child: CircularProgressIndicator(color: navy))
              : _erroCarregamento != null && _usinas.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _erroCarregamento!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: muted),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _carregarDadosReais,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (usina != null)
                          _cartaoResumo(usina)
                        else
                          _cartao(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.solar_power_outlined,
                                  color: navy,
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Nenhuma usina cadastrada ainda.',
                                  style: TextStyle(
                                    color: navy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Cadastre a usina para gerenciar cotas e contrato.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: muted, fontSize: 11),
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () => _abrirCadastro(),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: navy,
                                  ),
                                  child: const Text('Cadastrar primeira usina'),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        _itemAtalhoGestao(
                          icone: Icons.bar_chart_rounded,
                          fundoIcone: const Color(0xFFFFE7E8),
                          corIcone: const Color(0xFFCE6B73),
                          titulo: 'Cadastro da Usina',
                          subtitulo: 'Editar dados e configurações',
                          aoTocar: () => _abrirCadastro(),
                        ),
                        const SizedBox(height: 10),
                        _itemAtalhoGestao(
                          icone: Icons.pie_chart_outline,
                          fundoIcone: const Color(0xFFFFF3DC),
                          corIcone: orange,
                          titulo: 'Cotas e Membros',
                          subtitulo: 'Vincular membros e distribuir cotas',
                          aoTocar: _abrirCotas,
                        ),
                        const SizedBox(height: 10),
                        _itemAtalhoGestao(
                          icone: Icons.description_outlined,
                          fundoIcone: const Color(0xFFE6EEF9),
                          corIcone: navy,
                          titulo: 'Contrato do Consórcio',
                          subtitulo: 'Enviar ou atualizar documento da usina',
                          aoTocar: _abrirContrato,
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _itemAtalhoGestao({
    required IconData icone,
    required Color fundoIcone,
    required Color corIcone,
    required String titulo,
    required String subtitulo,
    required VoidCallback aoTocar,
  }) {
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(14),
      child: _cartao(
        child: Row(
          children: [
            _icone(icone, fundoIcone, corIcone),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: navy,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitulo,
                    style: const TextStyle(color: muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: muted),
          ],
        ),
      ),
    );
  }

  @override
  Widget _cartaoResumo(Map<String, dynamic> usina) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: .13),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Status',
                style: TextStyle(color: Color(0xFFB9C4D6), fontSize: 10),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF203653),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 3,
                      backgroundColor: Color(0xFF55D68B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      usina['status'],
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF33435A),
                child: Icon(Icons.wb_sunny, color: orange, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            usina['nome'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _dadoResumo('Potência instalada', '${usina['potencia']} kWp'),
              const SizedBox(width: 35),
              _dadoResumo('Distribuidora', usina['distribuidora']),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _dadoResumo('Código', usina['codigo']),
              const SizedBox(width: 35),
              _dadoResumo('Localização', usina['local']),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget _dadoResumo(String titulo, String valor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: Color(0xFFABB8CB), fontSize: 9),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
