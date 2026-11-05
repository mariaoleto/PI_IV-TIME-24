//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// validação, formatação e máscara de digitação do CPF (000.000.000-00)
// a mesma regra de validação existe no backend (auth_cpf.ts)

import 'package:flutter/services.dart';

String _soDigitos(String valor) => valor.replaceAll(RegExp(r'\D'), '');

// confere tamanho, rejeita sequências repetidas (111.111.111-11) e confere os 2 dígitos verificadores
bool cpfValido(String? valor) {
  final cpf = _soDigitos(valor ?? '');
  if (cpf.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

  int digito(String base) {
    var soma = 0;
    for (var i = 0; i < base.length; i++) {
      soma += int.parse(base[i]) * (base.length + 1 - i);
    }
    final resto = (soma * 10) % 11;
    return resto == 10 ? 0 : resto;
  }

  return digito(cpf.substring(0, 9)) == int.parse(cpf[9]) &&
      digito(cpf.substring(0, 10)) == int.parse(cpf[10]);
}

String? validarCpf(String? valor) {
  final digitos = _soDigitos(valor ?? '');
  if (digitos.isEmpty) return 'Informe seu CPF';
  if (!cpfValido(digitos)) return 'CPF inválido';
  return null;
}

// 52998224725 -> 529.982.247-25 (também formata CPF incompleto enquanto digita)
String formatarCpf(String? valor) {
  var digitos = _soDigitos(valor ?? '');
  if (digitos.length > 11) digitos = digitos.substring(0, 11);
  final texto = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i == 3 || i == 6) texto.write('.');
    if (i == 9) texto.write('-');
    texto.write(digitos[i]);
  }
  return texto.toString();
}

// o que é enviado para a API: só dígitos
String cpfSoDigitos(String valor) => _soDigitos(valor);

class MascaraCpf extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    final texto = formatarCpf(novo.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
