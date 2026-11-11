import mongoose, { Schema } from "mongoose";

const relatorioSchema = new Schema(
  {
    membro_id: { type: Schema.Types.ObjectId, required: true },
    tipo: {
      type: String,
      enum: ["relatorio_mensal", "extrato_creditos", "demonstrativo_anual"],
      required: true,
    },
    titulo: { type: String, required: true },
    referencia: { type: String, required: true },
    tamanho_bytes: { type: Number, required: true },
    tamanho_mb: { type: Number, required: true },
    data_geracao: { type: Date, required: true, default: Date.now },
    arquivo_url: { type: String, required: true },
    arquivo_pdf: { type: Buffer, required: true, select: false },
    total_geracao_kwh: { type: Number, required: true },
    total_creditos_kwh: { type: Number, required: true },
    total_consumo_kwh: { type: Number, required: true },
    saldo_kwh: { type: Number, required: true },
    economia_estimada_reais: { type: Number, required: true },
    origem_dados_tcp: { type: String, required: false, default: "" },
    telemetria_tcp: {
      status_servidor: String,
      usina: String,
      status_operacao: String,
      geracao_atual: String,
      tensao: String,
      frequencia: String,
      bruta: String,
      consultado_em: Date,
    },
  },
  { versionKey: false },
);

relatorioSchema.index({ membro_id: 1, data_geracao: -1 });

export const Relatorio = mongoose.model("Relatorio", relatorioSchema, "relatorios");
