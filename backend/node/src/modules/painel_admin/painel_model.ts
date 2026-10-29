//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// schema da usina (coleção "usinas"), usado somente para leitura no painel admin
// o cadastro da usina é feito em outro módulo; todos os campos são opcionais aqui

import mongoose, { Schema } from "mongoose";

const usinaSchema = new Schema(
  {
    nome: String,
    localizacao: String,
    capacidade_kwp: Number,
    geracao_esperada_kwh_mes: Number,
    ativa: Boolean,
  },
  { strict: false, versionKey: false },
);

export const Usina = mongoose.model("Usina", usinaSchema, "usinas");
