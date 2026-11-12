// Autora: Marina Hehnes Espósito.
// Propósito: permite cadastrar e editar os dados de uma usina.
part of 'usina_page.dart';

mixin _UsinaPageCadastro on _UsinaPageStateBase {
  @override
  Widget _telaCadastro() {
    const baseDistribuidoras = [
      'Enel',
      'CPFL',
      'Energisa',
      'Neoenergia',
      'Outra',
    ];
    final opcoesDistribuidora = baseDistribuidoras.contains(_distribuidora)
        ? baseDistribuidoras
        : [...baseDistribuidoras, _distribuidora];

    return Column(
      children: [
        _cabecalho('Cadastro da Usina', 'Dados gerais e configuração'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              _cartao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rotulo('NOME DA USINA'),
                    _campo(_nomeController, hint: 'Nome da usina'),
                    const SizedBox(height: 13),
                    _rotulo('POTÊNCIA INSTALADA'),
                    _campo(
                      _potenciaController,
                      hint: 'Ex.: 42',
                      sufixo: 'kWp',
                      teclado: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 13),
                    _rotulo('DISTRIBUIDORA'),
                    DropdownButtonFormField<String>(
                      key: ValueKey('distribuidora-$_distribuidora'),
                      initialValue: _distribuidora,
                      decoration: _decoracao(),
                      items: opcoesDistribuidora
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _distribuidora = value ?? 'Enel'),
                    ),
                    const SizedBox(height: 13),
                    _rotulo('LOCALIZAÇÃO'),
                    _campo(
                      _localController,
                      hint: 'Ex.: Campinas, SP (opcional)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _cartaoResumo({
                'nome': _nomeController.text.isEmpty
                    ? 'Nome da usina'
                    : _nomeController.text,
                'potencia': _potenciaController.text.isEmpty
                    ? '0'
                    : _potenciaController.text,
                'distribuidora': _distribuidora,
                'status': 'Pré-visualização',
                'codigo': _editingIndex != null && _editingIndex! < _usinas.length
                    ? _usinas[_editingIndex!]['codigo']
                    : 'Novo cadastro',
                'local': _localController.text.trim().isEmpty
                    ? 'Não informado'
                    : _localController.text.trim(),
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Minhas usinas',
                          style: TextStyle(
                            color: navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _usinas.length == 1
                              ? '1 unidade cadastrada'
                              : '${_usinas.length} unidades cadastradas',
                          style: const TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (_editingIndex != null)
                    TextButton.icon(
                      onPressed: () => _abrirCadastro(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nova usina'),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              ...List.generate(_usinas.length, (index) {
                final item = _usinas[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _cartao(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['nome'],
                                style: const TextStyle(
                                  color: navy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            _status(item['status']),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item['potencia']} kWp · ${item['distribuidora']}',
                          style: const TextStyle(color: muted, fontSize: 10),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _abrirCadastro(index: index),
                                child: const Text('Editar'),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFE35E64),
                                  side: const BorderSide(
                                    color: Color(0xFFF3C6C8),
                                  ),
                                ),
                                onPressed: _salvando
                                    ? null
                                    : () => _excluirUsina(index),
                                child: const Text('Excluir'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        _botaoInferior('Salvar usina', _salvarUsina),
      ],
    );
  }

  Widget _campo(
    TextEditingController controller, {
    String? hint,
    String? sufixo,
    TextInputType? teclado,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: navy, fontSize: 12),
      decoration: _decoracao(hint: hint, sufixo: sufixo),
    );
  }
}
