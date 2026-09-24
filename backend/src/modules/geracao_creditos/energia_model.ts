// autora: Maria Júlia Lazarini Oleto

// significado do arquivo:
// geracao dos modelos de dados (schemas)
// eles serao utilizados em outros arquivos
// servem para definir quais dados serao utilizados e onde/como eles estao
// armazenados no banco

import mongoose, { Schema, SchemaOptions } from "mongoose";

// opcoes do schema 
// permite que campos adicionais no banco sejam aceitos mesmo sem estarem no schema
const opcoesFlexiveis: SchemaOptions = {
  strict: false,
  versionKey: false,
};

// modelo do documento de geracao mensal
const geracaoMensalSchema = new Schema(
  {
    usina_id: { type: Schema.Types.ObjectId, required: true, index: true },
    mes_referencia: { type: String, required: true, index: true },
    geracao_kwh: { type: Number, required: true },
    data_lancamento: Date,
  },
  opcoesFlexiveis,
);

// modelo do documento de creditos
const creditosSchema = new Schema(
  {
    membro_id: { type: Schema.Types.ObjectId, required: true, index: true },
    usina_id: { type: Schema.Types.ObjectId, required: true, index: true },
    mes_referencia: { type: String, required: true, index: true },
    geracao_total_kwh: Number,
    percentual_cota: Number,
    creditos_brutos_kwh: Number,
    perdas_transmissao_kwh: Number,
    creditos_liquidos_kwh: Number,
  },
  opcoesFlexiveis,
);

// modelo do documento de cota
const cotasSchema = new Schema(
  {
    membro_id: { type: Schema.Types.ObjectId, required: true, index: true },
    usina_id: { type: Schema.Types.ObjectId, required: true, index: true },
    percentual: { type: Number, required: true },
    tarifa_kwh: Number,
    data_inicio: Date,
  },
  opcoesFlexiveis,
);

// modelo do documento de consumo mensal
const consumosMensaisSchema = new Schema(
  {
    membro_id: { type: Schema.Types.ObjectId, required: true, index: true },
    usina_id: { type: Schema.Types.ObjectId, required: true, index: true },
    mes_referencia: { type: String, required: true, index: true },
    consumo_kwh: { type: Number, required: true }
  },
  opcoesFlexiveis,
);

// exporta os modelos 
export const GeracaoMensal = mongoose.model(
  "GeracaoMensal",
  geracaoMensalSchema,
  "geracao_mensal",
);
export const Credito = mongoose.model("Credito", creditosSchema, "creditos");
export const Cota = mongoose.model("Cota", cotasSchema, "cotas");
export const ConsumosMensais = mongoose.model(
  "ConsumosMensais",
  consumosMensaisSchema,
  "consumos_mensal",
);