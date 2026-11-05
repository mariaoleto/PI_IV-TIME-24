//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// modelos de dados da tela de Perfil do membro (perfil, usina e contrato do consórcio)
// espelham o JSON devolvido pelo backend em /perfil

// usina do consórcio exibida no card do perfil
class UsinaPerfil {
  final String id;
  final String nome;
  final String? localizacao;

  const UsinaPerfil({required this.id, required this.nome, this.localizacao});

  factory UsinaPerfil.deJson(Map<String, dynamic> json) {
    return UsinaPerfil(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      localizacao: _lerTextoOpcional(json['localizacao']),
    );
  }
}

// dados do perfil: avatar, nome, e-mail, telefone e card do consórcio
class PerfilMembro {
  final String id;
  final String nome;
  final String inicial;
  final String email;
  final String? telefone; // somente dígitos, ex.: 19999998888
  final bool ehAdmin; // quem tem acesso vê o botão "Painel Administrador"
  final double? cotaPercentual;
  final DateTime? membroDesde;
  final UsinaPerfil? usina;

  const PerfilMembro({
    required this.id,
    required this.nome,
    required this.inicial,
    required this.email,
    this.telefone,
    this.ehAdmin = false,
    this.cotaPercentual,
    this.membroDesde,
    this.usina,
  });

  factory PerfilMembro.deJson(Map<String, dynamic> json) {
    final membro = json['membro'] as Map<String, dynamic>? ?? {};
    final consorcio = json['consorcio'] as Map<String, dynamic>? ?? {};
    final usinaJson = consorcio['usina'];
    final nome = membro['nome']?.toString() ?? '';

    return PerfilMembro(
      id: membro['id']?.toString() ?? '',
      nome: nome,
      inicial:
          membro['inicial']?.toString() ??
          (nome.trim().isNotEmpty ? nome.trim()[0].toUpperCase() : '?'),
      email: membro['email']?.toString() ?? '',
      telefone: _lerTextoOpcional(membro['telefone']),
      ehAdmin: membro['eh_admin'] == true,
      cotaPercentual: _lerDoubleOpcional(consorcio['cota_percentual']),
      membroDesde: _lerData(consorcio['membro_desde']),
      usina: usinaJson is Map<String, dynamic>
          ? UsinaPerfil.deJson(usinaJson)
          : null,
    );
  }
}

class ClausulaContrato {
  final String titulo;
  final String texto;

  const ClausulaContrato({required this.titulo, required this.texto});

  factory ClausulaContrato.deJson(Map<String, dynamic> json) {
    return ClausulaContrato(
      titulo: json['titulo']?.toString() ?? '',
      texto: json['texto']?.toString() ?? '',
    );
  }
}

// contrato do consórcio (somente visualização)
class ContratoConsorcio {
  final String? numero;
  final String status; // ativo, pendente, encerrado ou cancelado
  final String nomeMembro;
  final String emailMembro;
  final String? nomeUsina;
  final String? localizacaoUsina;
  final double? cotaPercentual;
  final double? tarifaKwh;
  final DateTime? dataAssinatura;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final int? vigenciaMeses;
  final List<ClausulaContrato> clausulas;
  final String? observacoes;
  final String? arquivoUrl;

  const ContratoConsorcio({
    this.numero,
    required this.status,
    required this.nomeMembro,
    required this.emailMembro,
    this.nomeUsina,
    this.localizacaoUsina,
    this.cotaPercentual,
    this.tarifaKwh,
    this.dataAssinatura,
    this.dataInicio,
    this.dataFim,
    this.vigenciaMeses,
    this.clausulas = const [],
    this.observacoes,
    this.arquivoUrl,
  });

  factory ContratoConsorcio.deJson(Map<String, dynamic> json) {
    final membro = json['membro'] as Map<String, dynamic>? ?? {};
    final usina = json['usina'] as Map<String, dynamic>?;
    final clausulasJson = json['clausulas'] as List<dynamic>? ?? [];

    return ContratoConsorcio(
      numero: _lerTextoOpcional(json['numero']),
      status: json['status']?.toString() ?? 'ativo',
      nomeMembro: membro['nome']?.toString() ?? '',
      emailMembro: membro['email']?.toString() ?? '',
      nomeUsina: _lerTextoOpcional(usina?['nome']),
      localizacaoUsina: _lerTextoOpcional(usina?['localizacao']),
      cotaPercentual: _lerDoubleOpcional(json['cota_percentual']),
      tarifaKwh: _lerDoubleOpcional(json['tarifa_kwh']),
      dataAssinatura: _lerData(json['data_assinatura']),
      dataInicio: _lerData(json['data_inicio']),
      dataFim: _lerData(json['data_fim']),
      vigenciaMeses: _lerDoubleOpcional(json['vigencia_meses'])?.toInt(),
      clausulas: clausulasJson
          .whereType<Map<String, dynamic>>()
          .map(ClausulaContrato.deJson)
          .toList(growable: false),
      observacoes: _lerTextoOpcional(json['observacoes']),
      arquivoUrl: _lerTextoOpcional(json['arquivo_url']),
    );
  }
}

String? _lerTextoOpcional(Object? valor) {
  final texto = valor?.toString().trim();
  return (texto == null || texto.isEmpty) ? null : texto;
}

double? _lerDoubleOpcional(Object? valor) {
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor?.toString() ?? '');
}

// as datas chegam em UTC (ex.: 2025-03-10T00:00:00.000Z) e são datas de calendário,
// por isso NÃO convertemos para o fuso local (senão 10/03 viraria 09/03 no Brasil)
DateTime? _lerData(Object? valor) {
  if (valor == null) return null;
  return DateTime.tryParse(valor.toString());
}
