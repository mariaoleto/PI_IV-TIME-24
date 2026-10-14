String? validarEmail(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return 'Informe seu e-mail';
  final valido = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(texto);
  return valido ? null : 'E-mail inválido';
}

String? validarSenha(String? valor) {
  final texto = valor ?? '';
  if (texto.isEmpty) return 'Informe sua senha';
  if (texto.length < 6) return 'A senha deve ter ao menos 6 caracteres';
  return null;
}

String? validarNome(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return 'Informe seu nome completo';
  if (texto.split(RegExp(r'\s+')).length < 2) return 'Informe nome e sobrenome';
  return null;
}
