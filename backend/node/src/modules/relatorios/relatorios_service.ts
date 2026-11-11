import crypto from "node:crypto";
import mongoose from "mongoose";
import { lerConfigAuth } from "../auth/auth_config";
import { Membro } from "../geracao_creditos/energia_model";
import {
  calcularCotasViaJavaTcp,
  consultarTelemetriaUsinaTcp,
  EnviarComandoTcpFn,
  montarResumoEnergia,
} from "../geracao_creditos/energia_service";
import { Relatorio } from "./relatorios_model";
import {
  DadosRelatorioPdf,
  gerarPdfRelatorio,
  LinhaRelatorio,
  TelemetriaPdf,
} from "./relatorios_pdf";

export type DepsRelatorios = {
  enviarTcp?: EnviarComandoTcpFn;
  buscarMembroPorId?: (id: string) => Promise<Record<string, unknown> | null>;
  montarResumo?: typeof montarResumoEnergia;
};

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

export async function obterDadosPdf(
  membroId: string,
  tipo: TipoRelatorio,
  referencia: string,
  deps: DepsRelatorios = {},
): Promise<DadosRelatorioPdf> {
  if (!mongoose.Types.ObjectId.isValid(membroId)) {
    throw new ErroRelatorio("Identificador de membro inválido.", 401);
  }

  const buscarMembro = deps.buscarMembroPorId ?? ((id: string) =>
    Membro.findById(id).select("nome usina_id").lean<Record<string, unknown>>()
  );
  const membro = await buscarMembro(membroId);
  if (!membro) throw new ErroRelatorio("Membro não encontrado.", 404);

  const ano = referencia.slice(0, 4);
  const montarResumo = deps.montarResumo ?? montarResumoEnergia;
  let resumo;
  try {
    resumo = await montarResumo({
      ano,
      usinaId: membro.usina_id?.toString(),
      membroId,
      enviarTcp: deps.enviarTcp,
    });
  } catch (erro) {
    const mensagem = erro instanceof Error ? erro.message : "Não foi possível montar o resumo de energia.";
    throw new ErroRelatorio(mensagem, 400);
  }

  const telemetriaResultado = await consultarTelemetriaUsinaTcp(deps.enviarTcp);
  const telemetriaPdf: TelemetriaPdf = {
    status_servidor: telemetriaResultado.status_servidor_tcp,
    usina: telemetriaResultado.usina,
    status_operacao: telemetriaResultado.status_operacao,
    geracao_atual: telemetriaResultado.geracao_atual,
    tensao: telemetriaResultado.tensao,
    frequencia: telemetriaResultado.frequencia,
    bruta: telemetriaResultado.telemetria,
    mensagem_erro: telemetriaResultado.mensagem_erro,
  };

  const mesesDoRelatorio =
    tipo === "demonstrativo_anual"
      ? resumo.meses
      : resumo.meses.filter((mes) => mes.mes_referencia === referencia);

  let tcpCalculoDisponivel = true;
  let calculouViaTcp = false;
  const meses: LinhaRelatorio[] = [];
  for (const mes of mesesDoRelatorio) {
    let creditosLiquidos = mes.creditos_liquidos_kwh;
    if (mes.geracao_kwh > 0 && resumo.percentual_cota > 0 && tcpCalculoDisponivel) {
      const resultadoTcp = await calcularCotasViaJavaTcp(
        mes.geracao_kwh,
        [resumo.percentual_cota],
        deps.enviarTcp,
      );
      if (resultadoTcp && resultadoTcp[resumo.percentual_cota] !== undefined) {
        creditosLiquidos = arredondar(resultadoTcp[resumo.percentual_cota]);
        calculouViaTcp = true;
      } else {
        tcpCalculoDisponivel = false;
      }
    }

    meses.push({
      mes_referencia: mes.mes_referencia,
      geracao_kwh: mes.geracao_kwh,
      creditos_liquidos_kwh: creditosLiquidos,
      consumo_kwh: mes.consumo_kwh,
      saldo_mes_kwh: arredondar(creditosLiquidos - mes.consumo_kwh),
    });
  }

  const origemDadosTcp = calculouViaTcp || telemetriaPdf.status_servidor === "online"
    ? "Java Socket TCP (porta 5050)"
    : "Fallback local / MongoDB (Servidor TCP Java offline)";

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
    origem_dados_tcp: origemDadosTcp,
    telemetria_tcp: telemetriaPdf,
    meses,
  };
}

export async function gerarRelatorio(
  membroId: string,
  tipo: TipoRelatorio,
  periodo: { referencia?: string; ano?: string },
  deps: DepsRelatorios = {},
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

  const dados = await obterDadosPdf(membroId, tipo, referencia, deps);
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
    origem_dados_tcp: dados.origem_dados_tcp,
    telemetria_tcp: dados.telemetria_tcp
      ? {
          status_servidor: dados.telemetria_tcp.status_servidor,
          usina: dados.telemetria_tcp.usina,
          status_operacao: dados.telemetria_tcp.status_operacao,
          geracao_atual: dados.telemetria_tcp.geracao_atual,
          tensao: dados.telemetria_tcp.tensao,
          frequencia: dados.telemetria_tcp.frequencia,
          bruta: dados.telemetria_tcp.bruta,
          consultado_em: new Date(),
        }
      : undefined,
  });
  return { arquivo, registro, dados };
}

export async function buscarRelatoriosDoMembro(membroId: string) {
  return Relatorio.find({ membro_id: new mongoose.Types.ObjectId(membroId) })
    .select("-arquivo_pdf")
    .sort({ data_geracao: -1 })
    .lean();
}

export function gerarTicketDownloadRelatorio(
  membroId: string,
  relatorioId: string,
  ttlSegundos = 120,
  agoraMs = Date.now(),
): string {
  const expira = Math.floor(agoraMs / 1000) + ttlSegundos;
  const carga = `${membroId}.${relatorioId}.${expira}`;
  const assinatura = crypto
    .createHmac("sha256", lerConfigAuth().segredo)
    .update(carga)
    .digest("hex");
  return `${carga}.${assinatura}`;
}

export function validarTicketDownloadRelatorio(
  ticket: string,
  relatorioId: string,
  agoraMs = Date.now(),
): string | null {
  const partes = ticket.split(".");
  if (partes.length !== 4) return null;
  const [membroId, idRelatorio, expiraStr, assinaturaHex] = partes;
  if (!membroId || idRelatorio !== relatorioId) return null;
  if (!mongoose.Types.ObjectId.isValid(membroId) || !mongoose.Types.ObjectId.isValid(idRelatorio)) {
    return null;
  }
  const expira = Number(expiraStr);
  if (!Number.isFinite(expira) || Math.floor(agoraMs / 1000) > expira) {
    return null;
  }
  if (!/^[0-9a-f]{64}$/i.test(assinaturaHex)) return null;

  const carga = `${membroId}.${idRelatorio}.${expiraStr}`;
  const esperado = crypto
    .createHmac("sha256", lerConfigAuth().segredo)
    .update(carga)
    .digest();
  const recebido = Buffer.from(assinaturaHex, "hex");
  if (recebido.length !== esperado.length || !crypto.timingSafeEqual(recebido, esperado)) {
    return null;
  }
  return membroId;
}

export async function prepararTicketDownload(membroId: string, relatorioId: string) {
  if (!mongoose.Types.ObjectId.isValid(relatorioId)) {
    throw new ErroRelatorio("Identificador de relatório inválido.");
  }
  const existe = await Relatorio.exists({
    _id: new mongoose.Types.ObjectId(relatorioId),
    membro_id: new mongoose.Types.ObjectId(membroId),
  });
  if (!existe) throw new ErroRelatorio("Relatório não encontrado.", 404);

  const ttlSegundos = 120;
  const ticket = gerarTicketDownloadRelatorio(membroId, relatorioId, ttlSegundos);
  return {
    ticket,
    download_url: `/relatorios/${relatorioId}/download?ticket=${ticket}`,
    expira_em_segundos: ttlSegundos,
  };
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
