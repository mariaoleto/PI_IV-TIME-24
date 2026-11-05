// Autora: Marina Hehnes Espósito.
// Propósito: define os modelos de usina, contrato, membro e cota usados pela API.
class Usina {
  const Usina({
    required this.id,
    required this.nome,
    required this.potencia,
    required this.distribuidora,
    required this.codigo,
    this.local,
  });

  final String id;
  final String nome;
  final double potencia;
  final String distribuidora;
  final String codigo;
  final String? local;

  factory Usina.fromJson(Map<String, dynamic> json) => Usina(
    id: json['id'] as String,
    nome: json['nome'] as String,
    potencia: (json['potencia'] as num).toDouble(),
    distribuidora: json['distribuidora'] as String,
    codigo: json['codigo'] as String,
    local: json['local'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'potencia': potencia,
    'distribuidora': distribuidora,
    'local': local,
  };
}

class ContratoUsina {
  const ContratoUsina({
    required this.usinaId,
    required this.nomeArquivo,
    required this.tamanhoBytes,
    required this.dataEnvio,
  });

  final String usinaId;
  final String nomeArquivo;
  final int tamanhoBytes;
  final DateTime dataEnvio;

  factory ContratoUsina.fromJson(Map<String, dynamic> json) {
    final data = json['dataEnvio'];
    return ContratoUsina(
      usinaId: json['usinaId'] as String,
      nomeArquivo: json['nomeArquivo'] as String,
      tamanhoBytes: (json['tamanhoBytes'] as num).toInt(),
      dataEnvio: data is num
          ? DateTime.fromMillisecondsSinceEpoch(data.toInt())
          : DateTime.parse(data as String),
    );
  }
}

class MembroUsina {
  const MembroUsina({
    required this.id,
    required this.nome,
    required this.email,
    required this.cota,
    required this.status,
  });

  final String id;
  final String nome;
  final String email;
  final double cota;
  final String status;

  factory MembroUsina.fromJson(Map<String, dynamic> json) => MembroUsina(
    id: json['id'] as String,
    nome: json['nome'] as String,
    email: json['email'] as String,
    cota: (json['cota'] as num).toDouble(),
    status: json['status'] as String,
  );

  MembroUsina copyWith({double? cota}) => MembroUsina(
    id: id,
    nome: nome,
    email: email,
    cota: cota ?? this.cota,
    status: status,
  );
}

class CotaAtualizacao {
  const CotaAtualizacao({required this.membroId, required this.percentual});

  final String membroId;
  final double percentual;
}
