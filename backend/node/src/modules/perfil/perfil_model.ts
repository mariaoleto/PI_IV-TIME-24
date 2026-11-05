//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// schema do contrato do consórcio (coleção "contratos")
// o schema é flexível (strict: false): se a sua coleção já tem campos extras, eles continuam
// funcionando. só os campos abaixo são lidos pelo módulo de perfil
//
// obs: o membro (coleção "membros") continua em geracao_creditos/energia_model.ts

import mongoose, { Schema } from "mongoose";

const clausulaSchema = new Schema(
  {
    titulo: String,
    texto: String,
  },
  { _id: false },
);

const contratoSchema = new Schema(
  {
    membro_id: { type: Schema.Types.ObjectId, required: true, index: true },
    usina_id: { type: Schema.Types.ObjectId, index: true },
    numero: String, // ex.: "SOLIS-2025-0042"
    status: String, // "ativo" | "pendente" | "encerrado" | "cancelado"
    percentual_cota: Number, // se ausente, usa o percentual da coleção cotas
    tarifa_kwh: Number,
    data_assinatura: Date,
    data_inicio: Date,
    data_fim: Date,
    vigencia_meses: Number,
    clausulas: [clausulaSchema],
    arquivo_url: String, // opcional: link do PDF assinado, se existir
    observacoes: String,
  },
  { strict: false, versionKey: false, timestamps: true },
);

export const Contrato = mongoose.model("Contrato", contratoSchema, "contratos");
