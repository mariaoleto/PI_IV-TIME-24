// Autora: Marina Hehnes Espósito.
// Propósito: apresenta o resumo e a tela inicial da gestão da usina.
part of 'usina_page.dart';

mixin _UsinaPageInicio on _UsinaPageStateBase {
  @override
  Widget _cabecalho(String titulo, String subtitulo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 17),
      color: navy,
      child: Row(
        children: [
          if (_screen != 0)
            IconButton(
              onPressed: () {
                setState(() {
                  if (_screen == 1) {
                    _screen = 0;
                  } else if (_screen == 2) {
                    _screen = 1;
                  } else {
                    _screen = 2;
                  }
                });
              },
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            ),
          if (_screen == 0)
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
    final usina = _usinas.isNotEmpty ? _usinas.first : null;
    return Column(
      children: [
        _cabecalho('Usina', 'Gerenciamento da planta solar'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (usina != null) _cartaoResumo(usina),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _abrirCadastro(),
                borderRadius: BorderRadius.circular(14),
                child: _cartao(
                  child: Row(
                    children: [
                      _icone(
                        Icons.bar_chart_rounded,
                        const Color(0xFFFFE7E8),
                        const Color(0xFFCE6B73),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cadastro da Usina',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: navy,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Editar dados e configurações',
                              style: TextStyle(color: muted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
            color: navy.withOpacity(.13),
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
