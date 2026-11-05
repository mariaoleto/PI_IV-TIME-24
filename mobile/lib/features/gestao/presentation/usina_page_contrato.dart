// Autora: Marina Hehnes Espósito.
// Propósito: apresenta as ações de visualização e gestão do contrato da usina.
part of 'usina_page.dart';

mixin _UsinaPageContrato on _UsinaPageStateBase {
  @override
  Widget _telaContrato() {
    return Column(
      children: [
        _cabecalho('Contrato do Consórcio', 'Documento vinculado à usina'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _cartao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rotulo('USINA VINCULADA'),
                    const SizedBox(height: 7),
                    DropdownButtonFormField<String>(
                      value: _usinas.isEmpty
                          ? null
                          : _usinas.last['nome'] as String,
                      decoration: _decoracao(),
                      items: _usinas
                          .map(
                            (u) => DropdownMenuItem<String>(
                              value: u['nome'],
                              child: Text(
                                u['nome'],
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _cartao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Documento do consórcio',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mantenha o contrato atualizado',
                      style: TextStyle(color: muted, fontSize: 10),
                    ),
                    const SizedBox(height: 13),
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FA),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.description_outlined,
                              color: navy,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _documento,
                                  style: const TextStyle(
                                    color: navy,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'PDF · Documento selecionado',
                                  style: TextStyle(color: muted, fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                          _status('Ativo'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(
                                () =>
                                    _documento = 'novo-contrato-consorcio.pdf',
                              );
                              _mensagem('Documento atualizado (demonstração).');
                            },
                            child: const Text('Substituir'),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(
                              () => _documento = 'Nenhum documento selecionado',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE35E64),
                              side: const BorderSide(color: Color(0xFFF3C6C8)),
                            ),
                            child: const Text('Remover'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4DF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: orange, size: 17),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'O contrato ficará disponível para todos os membros vinculados à usina selecionada.',
                        style: TextStyle(
                          color: Color(0xFF805719),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _botaoInferior('Salvar contrato', () {
          setState(() => _screen = 0);
          _mensagem('Contrato salvo com sucesso.');
        }),
      ],
    );
  }
}
