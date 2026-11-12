// Autora: Marina Hehnes Espósito.
// Propósito: exibe e atualiza a distribuição de cotas entre membros.
part of 'usina_page.dart';

mixin _UsinaPageCotas on _UsinaPageStateBase {
  @override
  Widget _telaCotas() {
    final restante = (100 - _totalCotas).clamp(0, 100).toDouble();
    final semUsinaApi = _usaApi && _usinas.isEmpty && !_carregando;

    return Column(
      children: [
        _cabecalho('Cadastro de Cotas', 'Defina a participação de cada membro'),
        Expanded(
          child: _carregando && _usinas.isEmpty
              ? const Center(child: CircularProgressIndicator(color: navy))
              : semUsinaApi
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _cartao(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.solar_power_outlined,
                                color: navy,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Cadastre uma usina primeiro para gerenciar cotas e membros.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => _abrirCadastro(),
                                style: FilledButton.styleFrom(
                                  backgroundColor: navy,
                                ),
                                child: const Text('Cadastrar usina'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      children: [
                        if (_usinas.length > 1) ...[
                          _cartao(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _rotulo('USINA VINCULADA'),
                                const SizedBox(height: 7),
                                DropdownButtonFormField<String>(
                                  key: ValueKey('cotas-usina-$_usinaSelecionadaId'),
                                  initialValue: _usinaSelecionadaId,
                                  decoration: _decoracao(),
                                  items: _usinas
                                      .map(
                                        (u) => DropdownMenuItem<String>(
                                          value: u['id'] as String,
                                          child: Text(
                                            u['nome'] as String,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _selecionarUsina,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Container(
                          padding: const EdgeInsets.all(17),
                          decoration: BoxDecoration(
                            color: orange,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'COTA TOTAL DISTRIBUÍDA',
                                style: TextStyle(
                                  color: Color(0xFF65420B),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_totalCotas.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: navy,
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 9),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: (_totalCotas / 100).clamp(0, 1),
                                  minHeight: 6,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: .55),
                                  valueColor: const AlwaysStoppedAnimation(navy),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  Text(
                                    '${_membros.length} membros',
                                    style: const TextStyle(
                                      color: Color(0xFF65420B),
                                      fontSize: 9,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${restante.toStringAsFixed(0)}% disponível',
                                    style: const TextStyle(
                                      color: Color(0xFF65420B),
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Membros do consórcio',
                          style: TextStyle(
                            color: navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Ajuste a participação individual',
                          style: TextStyle(color: muted, fontSize: 10),
                        ),
                        const SizedBox(height: 10),
                        if (_membros.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _cartao(
                              child: const Text(
                                'Nenhum membro vinculado a esta usina ainda. Toque em Adicionar membro.',
                                style: TextStyle(color: muted, fontSize: 11),
                              ),
                            ),
                          )
                        else
                          ...List.generate(
                            _membros.length,
                            (index) => _cartaoMembro(index),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _salvando ? null : _adicionarMembro,
                          icon: const Icon(Icons.add, size: 17),
                          label: const Text('Adicionar membro'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: navy,
                            side: const BorderSide(color: navy),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
        ),
        if (!semUsinaApi) _botaoInferior('Salvar cotas', _salvarCotas),
      ],
    );
  }

  @override
  Widget _cartaoMembro(int index) {
    final membro = _membros[index];
    final cores = [
      navy,
      const Color(0xFF31476A),
      orange,
      const Color(0xFF253858),
    ];
    final subtitulo = (membro['email'] as String?)?.trim().isNotEmpty == true
        ? membro['email'] as String
        : membro['id'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: _cartao(
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: cores[index % cores.length],
              child: Text(
                membro['iniciais'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membro['nome'],
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitulo,
                    style: const TextStyle(color: muted, fontSize: 9),
                  ),
                  const SizedBox(height: 4),
                  _status(membro['status']),
                ],
              ),
            ),
            SizedBox(
              width: 68,
              child: TextFormField(
                key: ValueKey('cota-$index-${membro['id']}'),
                initialValue: (membro['cota'] as double).toStringAsFixed(0),
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                decoration: InputDecoration(
                  suffixText: '%',
                  suffixStyle: const TextStyle(fontSize: 9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: Color(0xFFE0E5ED)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: Color(0xFFE0E5ED)),
                  ),
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed != null) {
                    setState(() => membro['cota'] = parsed);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
