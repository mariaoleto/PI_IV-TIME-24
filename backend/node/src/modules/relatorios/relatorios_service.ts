import mongoose from "mongoose";
import { Membro } from "../geracao_creditos/energia_model";
import { montarResumoEnergia } from "../geracao_creditos/energia_service";
import { Relatorio } from "./relatorios_model";
import { DadosRelatorioPdf, gerarPdfRelatorio, LinhaRelatorio } from "./relatorios_pdf";

export type TipoRelatorio =
  | "relatorio_mensal"
  | "extrato_creditos"
  | "demonstrativo_anual";

export class ErroRelatorio extends Error {
  constructor(message: string, public readonly status = 400) {
    super(message);
    this.name = "ErroRelatorio";
  }
}

function validarReferencia(referencia: string) {
  if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(referencia)) {
    throw new ErroRelatorio("A referência deve estar no formato AAAA-MM.");
  }
}

function validarAno(ano: string) {
  if (!/^\d{4}$/.test(ano)) {
    throw new ErroRelatorio("O ano deve conter quatro dígitos.");
  }
}

function arredondar(valor: number) {
  return Number(valor.toFixed(1));
}

async function obterDadosPdf(
  membroId: string,
  tipo: TipoRelatorio,
  referencia: string,
): Promise<DadosRelatorioPdf> {
  if (!mongoose.Types.ObjectId.isValid(membroId)) {
    throw new ErroRelatorio("Identificador de membro inválido.", 401);
  }

  const membro = await Membro.findById(membroId).select("nome usina_id").lean<Record<string, unknown>>();
  if (!membro) throw new ErroRelatorio("Membro não encontrado.", 404);

  const ano = referencia.slice(0, 4);
  const resumo = await montarResumoEnergia({
    ano,
    usinaId: membro.usina_id?.toString(),
    membroId,
  });
  const mesesDoRelatorio =
    tipo === "demonstrativo_anual"
      ? resumo.meses
      : resumo.meses.filter((mes) => mes.mes_referencia === referencia);

  const meses: LinhaRelatorio[] = mesesDoRelatorio.map((mes) => ({
    mes_referencia: mes.mes_referencia,
    geracao_kwh: mes.geracao_kwh,
    creditos_liquidos_kwh: mes.creditos_liquidos_kwh,
    consumo_kwh: mes.consumo_kwh,
    saldo_mes_kwh: mes.saldo_mes_kwh,
  }));
  const totalGeracao = meses.reduce((total, mes) => total + mes.geracao_kwh, 0);
  const totalCreditos = meses.reduce((total, mes) => total + mes.creditos_liquidos_kwh, 0);
  const totalConsumo = meses.reduce((total, mes) => total + mes.consumo_kwh, 0);
  const saldo = totalCreditos - totalConsumo;

  const referenciaFormatada =
    tipo === "demonstrativo_anual"
      ? `${ano} - Completo`
      : new Intl.DateTimeFormat("pt-BR", { month: "long", year: "numeric", timeZone: "UTC" })
        .format(new Date(`${referencia}-01T00:00:00Z`));
  const titulos: Record<TipoRelatorio, string> = {
    relatorio_mensal: "Relatório mensal de energia",
    extrato_creditos: "Extrato mensal de créditos",
    demonstrativo_anual: "Demonstrativo anual de energia",
  };

  return {
    titulo: titulos[tipo],
    referencia: referenciaFormatada,
    nome_membro: String(membro.nome ?? "Membro"),
    percentual_cota: resumo.percentual_cota,
    tarifa_kwh: resumo.tarifa_kwh,
    total_geracao_kwh: arredondar(totalGeracao),
    total_creditos_kwh: arredondar(totalCreditos),
    total_consumo_kwh: arredondar(totalConsumo),
    saldo_kwh: arredondar(saldo),
    economia_estimada_reais: Number((saldo * resumo.tarifa_kwh).toFixed(2)),
    meses,
  };
}

export async function gerarRelatorio(
  membroId: string,
  tipo: TipoRelatorio,
  periodo: { referencia?: string; ano?: string },
) {
  let referencia: string;
  if (tipo === "demonstrativo_anual") {
    const ano = periodo.ano ?? "";
    validarAno(ano);
    referencia = ano;
  } else {
    referencia = periodo.referencia ?? "";
    validarReferencia(referencia);
  }

  const dados = await obterDadosPdf(membroId, tipo, referencia);
  const arquivo = await gerarPdfRelatorio(dados);
  const id = new mongoose.Types.ObjectId();
  const registro = await Relatorio.create({
    _id: id,
    membro_id: new mongoose.Types.ObjectId(membroId),
    tipo,
    titulo: dados.titulo,
    referencia: dados.referencia,
    tamanho_bytes: arquivo.length,
    tamanho_mb: Number((arquivo.length / (1024 * 1024)).toFixed(3)),
    data_geracao: new Date(),
    arquivo_url: `/relatorios/${id.toString()}/download`,
    arquivo_pdf: arquivo,
    total_geracao_kwh: dados.total_geracao_kwh,
    total_creditos_kwh: dados.total_creditos_kwh,
    total_consumo_kwh: dados.total_consumo_kwh,
    saldo_kwh: dados.saldo_kwh,
    economia_estimada_reais: dados.economia_estimada_reais,
  });
  return { arquivo, registro, dados };
}

export async function buscarRelatoriosDoMembro(membroId: string) {
  return Relatorio.find({ membro_id: new mongoose.Types.ObjectId(membroId) })
    .select("-arquivo_pdf")
    .sort({ data_geracao: -1 })
    .lean();
}

export async function buscarArquivoRelatorio(membroId: string, relatorioId: string) {
  if (!mongoose.Types.ObjectId.isValid(relatorioId)) {
    throw new ErroRelatorio("Identificador de relatório inválido.");
  }
  const relatorio = await Relatorio.findOne({
    _id: new mongoose.Types.ObjectId(relatorioId),
    membro_id: new mongoose.Types.ObjectId(membroId),
  }).select("+arquivo_pdf");
  if (!relatorio) throw new ErroRelatorio("Relatório não encontrado.", 404);
  return relatorio;
}
