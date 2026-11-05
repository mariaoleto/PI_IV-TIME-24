//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// guarda o login atual (token JWT + dados do usuário) enquanto o app está aberto
// o token é enviado no header "Authorization: Bearer <token>" nas rotas protegidas (ex.: /perfil)
//
// obs: fica só na memória. se o app for fechado, é preciso entrar de novo.
// para manter o login entre aberturas do app, guarde o token com o pacote flutter_secure_storage

class UsuarioSessao {
  final String id;
  final String nome;
  final String email;
  final String tipoUsuario;
  final bool ehAdmin;

  const UsuarioSessao({
    required this.id,
    required this.nome,
    required this.email,
    this.tipoUsuario = 'membro',
    this.ehAdmin = false,
  });

  factory UsuarioSessao.deJson(Map<String, dynamic> json) {
    return UsuarioSessao(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      tipoUsuario: json['tipo_usuario']?.toString() ?? 'membro',
      ehAdmin: json['eh_admin'] == true,
    );
  }
}

class SessaoAuth {
  SessaoAuth._();

  static final SessaoAuth instancia = SessaoAuth._();

  String? _token;
  UsuarioSessao? _usuario;

  String? get token => _token;
  UsuarioSessao? get usuario => _usuario;
  bool get logado => _token != null;

  void iniciar(String token, UsuarioSessao usuario) {
    _token = token;
    _usuario = usuario;
  }

  // chamado ao sair da conta
  void limpar() {
    _token = null;
    _usuario = null;
  }
}
