//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// schema da usina (coleção "usina")
// todos os campos opcionais permitem coexistência de registros pré-definidos e cadastros pela API

import mongoose, { Schema } from "mongoose";

const usinaSchema = new Schema(
  {
    nome: String,
    localizacao: Schema.Types.Mixed,
    local: String,
    capacidade_kwp: Number,
    potencia_instalada_kwp: Number,
    potencia: Number,
    distribuidora: String,
    codigo: String,
    geracao_esperada_kwh_mes: Number,
    ativa: Boolean,
  },
  { strict: false, versionKey: false },
);

export const Usina = mongoose.model("Usina", usinaSchema, "usina");
