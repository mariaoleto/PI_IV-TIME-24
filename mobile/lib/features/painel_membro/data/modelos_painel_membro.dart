// autora: Maria Júlia Lazarini Oleto
// significado do arquivo:
// define os modelos de dados utilizados no painel administrativo do membro (dashboard)

// classe de geração mensal
class ItemGeracaoMensal {
  final String mes;
  final String mesReferencia;
  final double valorKwh;
  final bool mesAtual;

  const ItemGeracaoMensal({
    required this.mes,
    required this.mesReferencia,
    required this.valorKwh,
    required this.mesAtual,
  });

  // metodo factory para criar uma instancia de ItemGeracaoMensal a partir de um json
  factory ItemGeracaoMensal.deJson(Map<String, dynamic> json) {
    return ItemGeracaoMensal(
      mes: json['mes']?.toString() ?? '',
      mesReferencia: json['mes_referencia']?.toString() ?? '',
      valorKwh: _lerDouble(json['valor_kwh']),
      mesAtual: json['mes_atual'] == true,
    );
  }
}

// classe de lançamento do histórico do membro
class ItemLancamentoHistorico {
  final String mesRotulo;
  final String mesReferencia;
  final double geradoKwh;
  final double consumoKwh;
  final double creditoKwh;
  final bool positivo;

  const ItemLancamentoHistorico({
    required this.mesRotulo,
    required this.mesReferencia,
    required this.geradoKwh,
    required this.consumoKwh,
    required this.creditoKwh,
    required this.positivo,
  });

  // metodo factory para criar uma instancia de ItemLancamentoHistorico a partir de um json
  factory ItemLancamentoHistorico.deJson(Map<String, dynamic> json) {
    final credito = _lerDouble(json['credito_kwh']);
    return ItemLancamentoHistorico(
      mesRotulo: json['mes_rotulo']?.toString() ?? '',
      mesReferencia: json['mes_referencia']?.toString() ?? '',
      geradoKwh: _lerDouble(json['gerado_kwh']),
      consumoKwh: _lerDouble(json['consumo_kwh']),
      creditoKwh: credito,
      positivo: json['positivo'] != null
          ? json['positivo'] == true
          : credito >= 0,
    );
  }
}

// classe com os dados gerais do painel do membro
class DadosPainelMembro {
  final String nomeMembro;
  final String inicialMembro;
  final double cotaPercentual;
  final String saudacao;
  final String mesReferencia;
  final double creditosDisponiveisKwh;
  final int percentualUtilizado;
  final double geradoMesKwh;
  final double consumidoMesKwh;
  final double co2EvitadoKg;
  final double economiaReais;
  final String mesEconomia;
  final double mediaDiariaKwh;
  final double picoConsumoKwh;
  final String picoConsumoData;
  final List<ItemGeracaoMensal> geracaoMensal;
  final List<ItemLancamentoHistorico> ultimosLancamentos;

  const DadosPainelMembro({
    required this.nomeMembro,
    required this.inicialMembro,
    required this.cotaPercentual,
    required this.saudacao,
    required this.mesReferencia,
    required this.creditosDisponiveisKwh,
    required this.percentualUtilizado,
    required this.geradoMesKwh,
    required this.consumidoMesKwh,
    required this.co2EvitadoKg,
    required this.economiaReais,
    required this.mesEconomia,
    required this.mediaDiariaKwh,
    required this.picoConsumoKwh,
    required this.picoConsumoData,
    required this.geracaoMensal,
    required this.ultimosLancamentos,
  });

  // metodo factory para criar uma instancia de DadosPainelMembro a partir de um json
  factory DadosPainelMembro.deJson(Map<String, dynamic> json) {
    final membroJson = json['membro'] as Map<String, dynamic>? ?? {};
    final resumoMesJson = json['resumo_mes'] as Map<String, dynamic>? ?? {};
    final metricasJson = json['metricas'] as Map<String, dynamic>? ?? {};
    final geracaoListaJson = json['geracao_mensal'] as List<dynamic>? ?? [];
    final lancamentosListaJson =
        json['ultimos_lancamentos'] as List<dynamic>? ?? [];

    final nome = membroJson['nome']?.toString() ?? 'João Oliveira';
    final inicial =
        membroJson['inicial']?.toString() ??
        (nome.isNotEmpty ? nome.trim()[0].toUpperCase() : 'J');

    return DadosPainelMembro(
      nomeMembro: nome,
      inicialMembro: inicial,
      cotaPercentual: _lerDouble(membroJson['cota_percentual'], 25),
      saudacao: membroJson['saudacao']?.toString() ?? 'Bom dia,',
      mesReferencia: resumoMesJson['mes_referencia']?.toString() ?? 'Set/2026',
      creditosDisponiveisKwh: _lerDouble(
        resumoMesJson['creditos_disponiveis_kwh'],
        287,
      ),
      percentualUtilizado: _lerInteiro(
        resumoMesJson['percentual_utilizado'],
        72,
      ),
      geradoMesKwh: _lerDouble(resumoMesJson['gerado_mes_kwh'], 310),
      consumidoMesKwh: _lerDouble(resumoMesJson['consumido_mes_kwh'], 223),
      co2EvitadoKg: _lerDouble(metricasJson['co2_evitado_kg'], 127),
      economiaReais: _lerDouble(metricasJson['economia_reais'], 186),
      mesEconomia: metricasJson['mes_economia']?.toString() ?? 'agosto',
      mediaDiariaKwh: _lerDouble(metricasJson['media_diaria_kwh'], 9.7),
      picoConsumoKwh: _lerDouble(metricasJson['pico_consumo_kwh'], 14.2),
      picoConsumoData:
          metricasJson['pico_consumo_data']?.toString() ?? '13 set',
      geracaoMensal: geracaoListaJson
          .whereType<Map<String, dynamic>>()
          .map(ItemGeracaoMensal.deJson)
          .toList(growable: false),
      ultimosLancamentos: lancamentosListaJson
          .whereType<Map<String, dynamic>>()
          .map(ItemLancamentoHistorico.deJson)
          .toList(growable: false),
    );
  }

  // dados de exemplo
  // (questão somente relacionada a apresentação, como falha no servidor ou falta de internet)
  // isso não é executado quando o app funciona normalmente
  static DadosPainelMembro exemplo() {
    const meses = [
      ItemGeracaoMensal(
        mes: 'Jan',
        mesReferencia: '2026-01',
        valorKwh: 284,
        mesAtual: false,
      ),
      ItemGeracaoMensal(
        mes: 'Fev',
        mesReferencia: '2026-02',
        valorKwh: 312,
        mesAtual: false,
      ),
      ItemGeracaoMensal(
        mes: 'Mar',
        mesReferencia: '2026-03',
        valorKwh: 298,
        mesAtual: false,
      ),
      ItemGeracaoMensal(
        mes: 'Abr',
        mesReferencia: '2026-04',
        valorKwh: 340,
        mesAtual: false,
      ),
      ItemGeracaoMensal(
        mes: 'Mai',
        mesReferencia: '2026-05',
        valorKwh: 287,
        mesAtual: false,
      ),
      ItemGeracaoMensal(
        mes: 'Jun',
        mesReferencia: '2026-06',
        valorKwh: 310,
        mesAtual: false,
      ),
      ItemGeracaoMensal(
        mes: 'Jul',
        mesReferencia: '2026-07',
        valorKwh: 295,
        mesAtual: false,
      ),
      ItemGeracaoMensal(
        mes: 'Ago',
        mesReferencia: '2026-08',
        valorKwh: 325,
        mesAtual: false,
      ),
      ItemGeracaoMensal(
        mes: 'Set',
        mesReferencia: '2026-09',
        valorKwh: 310,
        mesAtual: true,
      ),
    ];

    const lancamentos = [
      ItemLancamentoHistorico(
        mesRotulo: 'Set/2026',
        mesReferencia: '2026-09',
        geradoKwh: 310,
        consumoKwh: 223,
        creditoKwh: 287,
        positivo: true,
      ),
      ItemLancamentoHistorico(
        mesRotulo: 'Ago/2026',
        mesReferencia: '2026-08',
        geradoKwh: 295,
        consumoKwh: 210,
        creditoKwh: 85,
        positivo: true,
      ),
      ItemLancamentoHistorico(
        mesRotulo: 'Jul/2026',
        mesReferencia: '2026-07',
        geradoKwh: 325,
        consumoKwh: 280,
        creditoKwh: 45,
        positivo: true,
      ),
      ItemLancamentoHistorico(
        mesRotulo: 'Jun/2026',
        mesReferencia: '2026-06',
        geradoKwh: 218,
        consumoKwh: 310,
        creditoKwh: -92,
        positivo: false,
      ),
    ];

    return const DadosPainelMembro(
      nomeMembro: 'João Oliveira',
      inicialMembro: 'J',
      cotaPercentual: 25,
      saudacao: 'Bom dia,',
      mesReferencia: 'Set/2026',
      creditosDisponiveisKwh: 287,
      percentualUtilizado: 72,
      geradoMesKwh: 310,
      consumidoMesKwh: 223,
      co2EvitadoKg: 127,
      economiaReais: 186,
      mesEconomia: 'agosto',
      mediaDiariaKwh: 9.7,
      picoConsumoKwh: 14.2,
      picoConsumoData: '13 set',
      geracaoMensal: meses,
      ultimosLancamentos: lancamentos,
    );
  }
}

double _lerDouble(Object? valor, [double padrao = 0]) {
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor?.toString() ?? '') ?? padrao;
}

int _lerInteiro(Object? valor, [int padrao = 0]) {
  if (valor is num) return valor.toInt();
  return int.tryParse(valor?.toString() ?? '') ?? padrao;
}
