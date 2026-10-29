// autora: Maria Júlia Lazarini Oleto
// RA: 25006031

// siginificado do arquivo:
// define os objetos usados no resumo de geracao e credito

// classe do objeto MesEnergia - retorna os dados mensais de geracao, consumo, saldo e economia
class MesEnergia {
  // atributos do objeto
  final String rotulo;
  final String referencia;
  final double geracaoKwh;
  final double creditosLiquidosKwh;
  final double consumoKwh;
  final double saldoMesKwh;

  // metodo construtor - cria um objeto MesEnergia
  const MesEnergia({
    required this.rotulo,
    required this.referencia,
    required this.geracaoKwh,
    required this.creditosLiquidosKwh,
    required this.consumoKwh,
    required this.saldoMesKwh,
  });

  // metodo factory, que gera e retorna um objeto MesEnergia com os dados de um json
  factory MesEnergia.deJson(Map<String, dynamic> json) {
    return MesEnergia(
      rotulo: json['mes']?.toString() ?? '',
      referencia: json['mes_referencia']?.toString() ?? '',
      geracaoKwh: _lerDouble(json['geracao_kwh']),
      creditosLiquidosKwh: _lerDouble(json['creditos_liquidos_kwh']),
      consumoKwh: _lerDouble(json['consumo_kwh']),
      saldoMesKwh: _lerDouble(json['saldo_mes_kwh']),
    );
  }
}

// classe do objeto ResumoEnergia - retorna os dados anuais de geracao, consumo, saldo e economia
class ResumoEnergia {
  final int ano;
  final double totalGeracaoKwh;
  final double totalConsumoKwh;
  final double saldoAcumuladoKwh;
  final double economiaEstimadaReais;
  final List<MesEnergia> meses;

  const ResumoEnergia({
    required this.ano,
    required this.totalGeracaoKwh,
    required this.totalConsumoKwh,
    required this.saldoAcumuladoKwh,
    required this.economiaEstimadaReais,
    required this.meses,
  });

  // metodo factory, que gera um objeto ResumoEnergia com os dados de um json
  factory ResumoEnergia.deJson(Map<String, dynamic> json) {
    // cria uma lista dos meses
    // trata possivel erro dos meses chegarem null
    // caso cheguem, cria uma lista vazia
    final mesesJson = json['meses'] as List<dynamic>? ?? <dynamic>[];
    // retorna o objeto com todos os dados
    return ResumoEnergia(
      ano: _lerInteiro(json['ano']),
      totalGeracaoKwh: _lerDouble(json['total_geracao_kwh']),
      totalConsumoKwh: _lerDouble(json['total_consumo_kwh']),
      saldoAcumuladoKwh: _lerDouble(json['saldo_acumulado_kwh']),
      economiaEstimadaReais: _lerDouble(json['economia_estimada_reais']),
      meses: mesesJson
          .whereType<Map<String, dynamic>>()
          .map(MesEnergia.deJson)
          .toList(growable: false),
    );
  }

  // exemplo
  static ResumoEnergia exemplo() {
    const geracao = <double>[
      284,
      312,
      298,
      340,
      287,
      310,
      295,
      325,
      270,
      260,
      0,
      0,
    ];

    const consumo = <double>[
      210,
      225,
      198,
      245,
      192,
      218,
      205,
      230,
      0,
      0,
      0,
      0,
    ];

    const rotulos = <String>[
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    // cria uma lista com os dados de cada mes
    final meses = List.generate(rotulos.length, (indice) {
      final valGeracao = geracao[indice];
      final valConsumo = consumo[indice];
      return MesEnergia(
        rotulo: rotulos[indice],
        referencia: '2026-${(indice + 1).toString().padLeft(2, '0')}',
        geracaoKwh: valGeracao,
        creditosLiquidosKwh: valGeracao,
        consumoKwh: valConsumo,
        saldoMesKwh: valGeracao - valConsumo,
      );
    });

    // retorna o resumo criado (dados anuais)
    return ResumoEnergia(
      ano: 2026,
      // soma o valor de todos os meses
      totalGeracaoKwh: geracao.reduce((a, b) => a + b),
      // soma o valor de todos os meses
      totalConsumoKwh: consumo.reduce((a, b) => a + b),
      saldoAcumuladoKwh: 417,
      economiaEstimadaReais: 289,
      meses: meses,
    );
  }
}

// metodos auxiliares

// le um valor double ou 0 se der erro
double _lerDouble(Object? valor) {
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor?.toString() ?? '') ?? 0;
}

// le um valor inteiro
int _lerInteiro(Object? valor) {
  if (valor is num) return valor.toInt();
  return int.tryParse(valor?.toString() ?? '') ?? DateTime.now().year;
}

// modelo que representa a cota de um membro para a distribuicao
class CotaMembro {
  final String cotaId;
  final String membroId;
  final String nome;
  final double percentual;
  final double tarifaKwh;

  const CotaMembro({
    required this.cotaId,
    required this.membroId,
    required this.nome,
    required this.percentual,
    required this.tarifaKwh,
  });

  factory CotaMembro.deJson(Map<String, dynamic> json) {
    return CotaMembro(
      cotaId: json['cota_id']?.toString() ?? '',
      membroId: json['membro_id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Membro',
      percentual: _lerDouble(json['percentual']),
      tarifaKwh: _lerDouble(json['tarifa_kwh']),
    );
  }

  // calcula o valor em kWh proporcional à geração total digitada pelo admin
  double calcularKwh(double geracaoTotalKwh) {
    final valor = geracaoTotalKwh * (percentual / 100);
    return double.parse(valor.toStringAsFixed(1));
  }
}
