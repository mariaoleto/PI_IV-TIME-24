// significado do arquivo:
// define os objetos retornados pelo endpoint agregador do painel admin (GET /admin/painel)

// converte qualquer valor numérico do json em double (0 se inválido)
double _lerDouble(Object? valor) {
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor?.toString().replaceAll(',', '.') ?? '') ?? 0;
}

// igual ao anterior, mas preserva null (ex.: eficiência sem base de comparação)
double? _lerDoubleOuNulo(Object? valor) {
  if (valor == null) return null;
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor.toString().replaceAll(',', '.'));
}

int _lerInt(Object? valor) => _lerDouble(valor).round();

Map<String, dynamic> _lerMapa(Object? valor) =>
    valor is Map<String, dynamic> ? valor : const <String, dynamic>{};

class UsinaPainel {
  final String id;
  final String? nome;
  final String? localizacao;
  final double? capacidadeKwp;
  final bool ativa;

  const UsinaPainel({
    required this.id,
    this.nome,
    this.localizacao,
    this.capacidadeKwp,
    this.ativa = true,
  });

  factory UsinaPainel.deJson(Map<String, dynamic> json) {
    return UsinaPainel(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString(),
      localizacao: json['localizacao']?.toString(),
      capacidadeKwp: _lerDoubleOuNulo(json['capacidade_kwp']),
      ativa: json['ativa'] != false,
    );
  }
}

// dados do mês exibido no card da usina ativa
class ResumoMesPainel {
  final String mesReferencia; // AAAA-MM
  final String rotulo; // ex.: Outubro/2026
  final bool registrado;
  final double geracaoKwh;
  final double? geracaoMesAnteriorKwh;
  final double? variacaoPercentual;
  final double? eficienciaPercentual;
  // "capacidade" ou "historico"; null quando não há base de comparação
  final String? eficienciaBase;

  const ResumoMesPainel({
    required this.mesReferencia,
    required this.rotulo,
    required this.registrado,
    required this.geracaoKwh,
    this.geracaoMesAnteriorKwh,
    this.variacaoPercentual,
    this.eficienciaPercentual,
    this.eficienciaBase,
  });

  factory ResumoMesPainel.deJson(Map<String, dynamic> json) {
    return ResumoMesPainel(
      mesReferencia: json['mes_referencia']?.toString() ?? '',
      rotulo: json['rotulo']?.toString() ?? '',
      registrado: json['registrado'] == true,
      geracaoKwh: _lerDouble(json['geracao_kwh']),
      geracaoMesAnteriorKwh: _lerDoubleOuNulo(json['geracao_mes_anterior_kwh']),
      variacaoPercentual: _lerDoubleOuNulo(json['variacao_percentual']),
      eficienciaPercentual: _lerDoubleOuNulo(json['eficiencia_percentual']),
      eficienciaBase: json['eficiencia_base']?.toString(),
    );
  }
}

class MembrosPainel {
  final int ativos;
  final double somaPercentualCotas;
  final double percentualDisponivel;

  const MembrosPainel({
    required this.ativos,
    required this.somaPercentualCotas,
    required this.percentualDisponivel,
  });

  factory MembrosPainel.deJson(Map<String, dynamic> json) {
    return MembrosPainel(
      ativos: _lerInt(json['ativos']),
      somaPercentualCotas: _lerDouble(json['soma_percentual_cotas']),
      percentualDisponivel: _lerDouble(json['percentual_disponivel']),
    );
  }
}

enum SeveridadeAlerta { erro, aviso, info }

class AlertaPainel {
  final String tipo;
  final SeveridadeAlerta severidade;
  final String titulo;
  final String mensagem;

  const AlertaPainel({
    required this.tipo,
    required this.severidade,
    required this.titulo,
    required this.mensagem,
  });

  factory AlertaPainel.deJson(Map<String, dynamic> json) {
    return AlertaPainel(
      tipo: json['tipo']?.toString() ?? '',
      severidade: switch (json['severidade']?.toString()) {
        'erro' => SeveridadeAlerta.erro,
        'aviso' => SeveridadeAlerta.aviso,
        _ => SeveridadeAlerta.info,
      },
      titulo: json['titulo']?.toString() ?? '',
      mensagem: json['mensagem']?.toString() ?? '',
    );
  }
}

enum StatusLancamento { atrasado, pendente, emDia }

class ProximoLancamentoPainel {
  final String mesReferencia;
  final String rotulo;
  final StatusLancamento status;
  final int mesesEmAtraso;
  // AAAA-MM-DD; só preenchido quando o status é "em_dia"
  final String? dataAbertura;

  const ProximoLancamentoPainel({
    required this.mesReferencia,
    required this.rotulo,
    required this.status,
    required this.mesesEmAtraso,
    this.dataAbertura,
  });

  factory ProximoLancamentoPainel.deJson(Map<String, dynamic> json) {
    return ProximoLancamentoPainel(
      mesReferencia: json['mes_referencia']?.toString() ?? '',
      rotulo: json['rotulo']?.toString() ?? '',
      status: switch (json['status']?.toString()) {
        'atrasado' => StatusLancamento.atrasado,
        'em_dia' => StatusLancamento.emDia,
        _ => StatusLancamento.pendente,
      },
      mesesEmAtraso: _lerInt(json['meses_em_atraso']),
      dataAbertura: json['data_abertura']?.toString(),
    );
  }
}

// resposta completa do painel administrativo
class PainelAdmin {
  final UsinaPainel usina;
  final ResumoMesPainel resumoMes;
  final MembrosPainel membros;
  final List<AlertaPainel> alertas;
  final ProximoLancamentoPainel proximoLancamento;

  const PainelAdmin({
    required this.usina,
    required this.resumoMes,
    required this.membros,
    required this.alertas,
    required this.proximoLancamento,
  });

  factory PainelAdmin.deJson(Map<String, dynamic> json) {
    final alertas = json['alertas'];
    return PainelAdmin(
      usina: UsinaPainel.deJson(_lerMapa(json['usina'])),
      resumoMes: ResumoMesPainel.deJson(_lerMapa(json['resumo_mes'])),
      membros: MembrosPainel.deJson(_lerMapa(json['membros'])),
      alertas: alertas is List
          ? alertas
                .whereType<Map<String, dynamic>>()
                .map(AlertaPainel.deJson)
                .toList(growable: false)
          : const [],
      proximoLancamento: ProximoLancamentoPainel.deJson(
        _lerMapa(json['proximo_lancamento']),
      ),
    );
  }
}
