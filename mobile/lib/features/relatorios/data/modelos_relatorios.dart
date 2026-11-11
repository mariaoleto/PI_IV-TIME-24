String formatarNumero(double valor, {int casas = 0}) {
  final texto = valor.toStringAsFixed(casas);
  final partes = texto.split('.');
  final inteira = partes.first;
  final decimal = partes.length > 1 ? partes[1] : null;

  final buffer = StringBuffer();
  for (var indice = 0; indice < inteira.length; indice++) {
    final pos = inteira.length - indice;
    if (indice > 0 && pos % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(inteira[indice]);
  }

  if (decimal == null) {
    return buffer.toString();
  }

  return '${buffer.toString()},$decimal';
}

class TelemetriaTcpRelatorios {
  const TelemetriaTcpRelatorios({
    required this.online,
    this.usina,
    this.statusOperacao,
    this.geracaoAtual,
    this.tensao,
    this.frequencia,
    this.mensagem,
  });

  final bool online;
  final String? usina;
  final String? statusOperacao;
  final String? geracaoAtual;
  final String? tensao;
  final String? frequencia;
  final String? mensagem;

  factory TelemetriaTcpRelatorios.deJson(Map<String, dynamic> mapa) {
    final detalhes = mapa['detalhes'] is Map<String, dynamic>
        ? mapa['detalhes'] as Map<String, dynamic>
        : mapa;
    final telemetriaTexto = mapa['telemetria']?.toString() ?? '';

    String? lerCampo(String chave) =>
        RegExp('(?:^|\\s)$chave=([^\\s]+)').firstMatch(telemetriaTexto)?.group(1);

    final status =
        mapa['status_servidor_tcp']?.toString() ??
        detalhes['status_servidor']?.toString() ??
        'offline';

    return TelemetriaTcpRelatorios(
      online: status == 'online',
      usina: detalhes['usina']?.toString() ?? lerCampo('USINA'),
      statusOperacao:
          detalhes['status_operacao']?.toString() ?? lerCampo('STATUS'),
      geracaoAtual:
          detalhes['geracao_atual']?.toString() ?? lerCampo('GERACAO_ATUAL'),
      tensao: detalhes['tensao']?.toString() ?? lerCampo('TENSAO'),
      frequencia: detalhes['frequencia']?.toString() ?? lerCampo('FREQ'),
      mensagem: mapa['mensagem']?.toString(),
    );
  }
}

class RelatorioResumo {
  const RelatorioResumo({
    required this.totalGeracaoKwh,
    required this.economiaAnualReais,
    required this.co2EvitadoKg,
  });

  final double totalGeracaoKwh;
  final double economiaAnualReais;
  final double co2EvitadoKg;

  factory RelatorioResumo.fromLista(List<RelatorioDocumento> relatorios) {
    if (relatorios.isEmpty) {
      return const RelatorioResumo(
        totalGeracaoKwh: 0,
        economiaAnualReais: 0,
        co2EvitadoKg: 0,
      );
    }

    final anuais = relatorios
        .where((r) => r.tipo == 'demonstrativo_anual')
        .toList(growable: false);
    if (anuais.isNotEmpty) {
      final base = anuais.first;
      return RelatorioResumo(
        totalGeracaoKwh: base.totalGeracaoKwh,
        economiaAnualReais: base.economiaEstimadaReais,
        co2EvitadoKg: base.totalGeracaoKwh * 0.3996,
      );
    }

    // Agrega períodos distintos (evita somar em dobro mensal + extrato da mesma referência)
    final porReferencia = <String, RelatorioDocumento>{};
    for (final relatorio in relatorios) {
      final chave = relatorio.referencia.toLowerCase().trim();
      final existente = porReferencia[chave];
      if (existente == null ||
          (existente.tipo != 'relatorio_mensal' &&
              relatorio.tipo == 'relatorio_mensal')) {
        porReferencia[chave] = relatorio;
      }
    }

    final totalGeracao = porReferencia.values.fold<double>(
      0,
      (soma, item) => soma + item.totalGeracaoKwh,
    );
    final totalEconomia = porReferencia.values.fold<double>(
      0,
      (soma, item) => soma + item.economiaEstimadaReais,
    );

    return RelatorioResumo(
      totalGeracaoKwh: totalGeracao,
      economiaAnualReais: totalEconomia,
      co2EvitadoKg: totalGeracao * 0.3996,
    );
  }
}

class RelatorioDocumento {
  const RelatorioDocumento({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.referencia,
    required this.dataGeracao,
    required this.arquivoUrl,
    required this.tamanhoMb,
    required this.totalGeracaoKwh,
    required this.totalCreditosKwh,
    required this.totalConsumoKwh,
    required this.saldoKwh,
    required this.economiaEstimadaReais,
    this.origemDadosTcp = '',
    this.telemetriaTcp,
  });

  final String id;
  final String tipo;
  final String titulo;
  final String referencia;
  final DateTime dataGeracao;
  final String arquivoUrl;
  final double tamanhoMb;
  final double totalGeracaoKwh;
  final double totalCreditosKwh;
  final double totalConsumoKwh;
  final double saldoKwh;
  final double economiaEstimadaReais;
  final String origemDadosTcp;
  final TelemetriaTcpRelatorios? telemetriaTcp;

  factory RelatorioDocumento.deJson(Map<String, dynamic> json) {
    final tipo = json['tipo']?.toString() ?? 'relatorio_mensal';
    final arquivoUrl = json['arquivo_url']?.toString() ?? '';
    final telemetriaJson = json['telemetria_tcp'];

    return RelatorioDocumento(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      tipo: tipo,
      titulo: json['titulo']?.toString() ?? _tituloPadrao(tipo),
      referencia: json['referencia']?.toString() ?? 'Sem referência',
      dataGeracao: DateTime.tryParse(
            json['data_geracao']?.toString() ?? '',
          ) ??
          DateTime.now(),
      arquivoUrl: arquivoUrl,
      tamanhoMb: json['tamanho_mb'] != null
          ? _paraDouble(json['tamanho_mb'])
          : _paraDouble(json['tamanho_bytes']) / (1024 * 1024),
      totalGeracaoKwh: _paraDouble(json['total_geracao_kwh']),
      totalCreditosKwh: _paraDouble(json['total_creditos_kwh']),
      totalConsumoKwh: _paraDouble(json['total_consumo_kwh']),
      saldoKwh: _paraDouble(json['saldo_kwh']),
      economiaEstimadaReais: _paraDouble(json['economia_estimada_reais']),
      origemDadosTcp: json['origem_dados_tcp']?.toString() ?? '',
      telemetriaTcp: telemetriaJson is Map<String, dynamic>
          ? TelemetriaTcpRelatorios.deJson(telemetriaJson)
          : null,
    );
  }

  static List<RelatorioDocumento> exemplo() {
    final agora = DateTime.now();
    return [
      RelatorioDocumento(
        id: 'demo-mensal',
        tipo: 'relatorio_mensal',
        titulo: 'Relatório mensal',
        referencia: 'Setembro 2026',
        dataGeracao: DateTime(agora.year, agora.month, 12),
        arquivoUrl: '/relatorios/demo-mensal/download',
        tamanhoMb: 2.1,
        totalGeracaoKwh: 2565,
        totalCreditosKwh: 1420,
        totalConsumoKwh: 1180,
        saldoKwh: 240,
        economiaEstimadaReais: 1780,
      ),
      RelatorioDocumento(
        id: 'demo-creditos',
        tipo: 'relatorio_mensal',
        titulo: 'Relatório mensal',
        referencia: 'Agosto 2026',
        dataGeracao: DateTime(agora.year, agora.month - 1, 10),
        arquivoUrl: '/relatorios/demo-creditos/download',
        tamanhoMb: 1.9,
        totalGeracaoKwh: 2200,
        totalCreditosKwh: 1310,
        totalConsumoKwh: 990,
        saldoKwh: 320,
        economiaEstimadaReais: 1540,
      ),
      RelatorioDocumento(
        id: 'demo-julho',
        tipo: 'relatorio_mensal',
        titulo: 'Relatório mensal',
        referencia: 'Julho 2026',
        dataGeracao: DateTime(agora.year, agora.month - 2, 8),
        arquivoUrl: '/relatorios/demo-julho/download',
        tamanhoMb: 2.0,
        totalGeracaoKwh: 2220,
        totalCreditosKwh: 1380,
        totalConsumoKwh: 1030,
        saldoKwh: 350,
        economiaEstimadaReais: 1620,
      ),
      RelatorioDocumento(
        id: 'demo-contrato',
        tipo: 'contrato',
        titulo: 'Contrato do consórcio',
        referencia: 'Assinado em 01/03/2024',
        dataGeracao: DateTime(2024, 3, 1),
        arquivoUrl: '/relatorios/demo-contrato/download',
        tamanhoMb: 3.2,
        totalGeracaoKwh: 0,
        totalCreditosKwh: 0,
        totalConsumoKwh: 0,
        saldoKwh: 0,
        economiaEstimadaReais: 0,
      ),
    ];
  }

  static String _tituloPadrao(String tipo) {
    switch (tipo) {
      case 'extrato_creditos':
        return 'Extrato de créditos';
      case 'demonstrativo_anual':
        return 'Demonstrativo anual';
      case 'relatorio_mensal':
      default:
        return 'Relatório mensal';
    }
  }

  String get formatacaoMb => '${formatarNumero(tamanhoMb, casas: 1)} MB';

  static double _paraDouble(Object? valor) {
    if (valor == null) return 0;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString()) ?? 0;
  }

  String get rotuloTipo {
    switch (tipo) {
      case 'extrato_creditos':
        return 'Extrato de créditos';
      case 'demonstrativo_anual':
        return 'Demonstrativo anual';
      case 'contrato':
        return 'Contrato do consórcio';
      case 'relatorio_mensal':
      default:
        return 'Relatório mensal';
    }
  }
}
