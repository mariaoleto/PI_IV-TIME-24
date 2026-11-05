//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// validação do telefone, máscara de digitação e formatação de datas/números do Perfil
// (nome, e-mail e senha reaproveitam auth/domain/validadores.dart)

import 'package:flutter/services.dart';

String _soDigitos(String valor) => valor.replaceAll(RegExp(r'\D'), '');

// telefone é opcional. se preenchido: DDD + 8 ou 9 dígitos (mesma regra do backend)
String? validarTelefone(String? valor) {
  final digitos = _soDigitos(valor ?? '');
  if (digitos.isEmpty) return null;
  if (digitos.length != 10 && digitos.length != 11) {
    return 'Telefone inválido. Use DDD + número';
  }
  if (digitos.startsWith('0')) return 'DDD inválido';
  if (digitos.length == 11 && digitos[2] != '9') {
    return 'Celular deve começar com 9 depois do DDD';
  }
  return null;
}

// (19) 99999-8888 ou (19) 3333-4444. aceita o valor com ou sem máscara
String formatarTelefone(String? valor) {
  final d = _soDigitos(valor ?? '');
  if (d.isEmpty) return '';
  if (d.length <= 2) return '($d';
  final ddd = d.substring(0, 2);
  final resto = d.substring(2);
  if (d.length <= 6) return '($ddd) $resto';
  if (d.length <= 10) {
    return '($ddd) ${resto.substring(0, 4)}-${resto.substring(4)}';
  }
  return '($ddd) ${resto.substring(0, 5)}-${resto.substring(5, 9)}';
}

// aplica a máscara enquanto a pessoa digita
class MascaraTelefone extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue antigo,
    TextEditingValue novo,
  ) {
    var digitos = _soDigitos(novo.text);
    if (digitos.length > 11) digitos = digitos.substring(0, 11);
    final texto = formatarTelefone(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

// o que é enviado para a API: só dígitos
String telefoneSoDigitos(String valor) => _soDigitos(valor);

const _mesesAbreviados = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

// 10/03/2025
String formatarData(DateTime? data) {
  if (data == null) return '—';
  return '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}/${data.year}';
}

// mar/2025 (usado no "Membro desde")
String formatarMesAno(DateTime? data) {
  if (data == null) return '—';
  return '${_mesesAbreviados[data.month - 1]}/${data.year}';
}

// 25 -> "25%", 12.5 -> "12,5%"
String formatarPercentual(double? valor) {
  if (valor == null) return '—';
  final texto = valor == valor.roundToDouble()
      ? valor.toInt().toString()
      : valor.toStringAsFixed(1).replaceAll('.', ',');
  return '$texto%';
}

// 0.69 -> "R$ 0,69/kWh"
String formatarTarifa(double? valor) {
  if (valor == null) return '—';
  return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}/kWh';
}
