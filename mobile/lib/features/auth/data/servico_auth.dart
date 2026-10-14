/// Contrato de autenticação. O backend ainda não tem rotas de login,
/// então hoje a implementação usada é a local (simulada).
/// Quando a API existir, crie uma `ServicoAuthApi implements ServicoAuth`
/// e troque nas telas.
abstract class ServicoAuth {
  /// Lança [Exception] com mensagem amigável se as credenciais forem inválidas.
  Future<void> entrarMembro({required String email, required String senha});
  Future<void> entrarAdministrador({
    required String email,
    required String senha,
  });
}

/// Implementação SIMULADA: aceita qualquer credencial já validada no formulário.
/// TODO: substituir pela chamada real à API.
class ServicoAuthLocal implements ServicoAuth {
  @override
  Future<void> entrarMembro({
    required String email,
    required String senha,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<void> entrarAdministrador({
    required String email,
    required String senha,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }
}
