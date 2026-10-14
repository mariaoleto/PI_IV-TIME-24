// autora: Maria Julia Lazarini Oleto

// significado do arquivo:
// centraliza o acesso ao banco 
// auxilia na pesquisa e atualizacao de informacoes e construcao dos resultados 

import mongoose from "mongoose";
import {
  Cota,
  Credito,
  ConsumosMensais,
  GeracaoMensal,
  Membro,
} from "./energia_model";

export type DocumentoFlexivel = Record<string, unknown>;

// tipo que representa documento de cota com membro 
export type CotaComMembro = DocumentoFlexivel & {
  _id?: unknown;
  cota_id?: unknown;
  membro_id?: unknown;
  usina_id?: unknown;
  percentual?: unknown;
  tarifa_kwh?: unknown;
  nome_membro: string;
}

// filtro por ano e id da usina
type FiltroBase = {
  ano: number;
  usinaId: string;
};

// filtro base + por id do membro
type FiltroComMembro = FiltroBase & {
  membroId: string;
};

// retorna o valor de um campo especifico
function idObjeto(valor: string | undefined, nomeCampo: string) {
  if (!valor || !mongoose.Types.ObjectId.isValid(valor)) {
    throw new Error(`${nomeCampo} invalido`);
  }

  return new mongoose.Types.ObjectId(valor);
}

// busca a cota mais recente de membro dentro da usina 
export function buscarCotaMaisRecente(parametros: {
  usinaId?: string;
  membroId?: string;
}) {
  const filtro: Record<string, unknown> = {};

  if (parametros.usinaId) {
    filtro.usina_id = idObjeto(parametros.usinaId, "usina_id");
  }
  if (parametros.membroId) {
    filtro.membro_id = idObjeto(parametros.membroId, "membro_id");
  }

  return Cota.findOne(filtro).sort({
    percentual: -1, data_inicio: -1
  }).lean<DocumentoFlexivel>(); // lean() impede o mongoose de criar um documento mock
}

// busca e retorna uma promise de todas as cotas com os membros 
export async function buscarTodasCotasComMembros(
  usina_Id?: string,
  membro_Id?: string,
): Promise<CotaComMembro[]> {
  const filtro: Record<string, unknown> = {};

  if (usina_Id) {
    filtro.usina_id = idObjeto(usina_Id, "usina_id");
  }
  if (membro_Id) {
    filtro.membro_id = idObjeto(membro_Id, "membro_id");
  }

  // busca as cotas com os percentuais em ordem decrescente
  const cotas = await Cota.find(filtro).sort({
    percentual: -1
  }).lean<DocumentoFlexivel[]>();

  // busca os ids dos membros com os ids das cotas
  // busca os nomes de acordo com os ids
  const membrosIds = cotas.map((c) => c.membro_id);
  const membros = await Membro.find({
    _id: { $in: membrosIds }
  }).lean<DocumentoFlexivel[]>();

  // cria um mapa para a associacao dos membros (id e nome)
  const mapaMembros = new Map(membros.map((m) => [m._id?.toString(),
  m.nome?.toString() || "Membro"]));

  // retorna as cotas com nome dos membros 
  return cotas.map((cota) => ({
    ...cota,
    // garante que cota_id seja sempre retornado (_id ou cota_id)
    cota_id: cota._id ?? cota.cota_id,
    nome_membro: mapaMembros.get(cota.membro_id?.toString()) || "Membro",
  })) as CotaComMembro[];
}

// busca os dados da geracao por mes 
export function buscarGeracoesMensais(parametros: FiltroBase) {
  return GeracaoMensal.find({
    usina_id: idObjeto(parametros.usinaId, "usina_id"),
    mes_referencia: { $regex: `^${parametros.ano}-` },
  }).sort({ mes_referencia: 1 }).lean<DocumentoFlexivel[]>();
}

// busca os creditos por mes do usuario 
export function buscarCreditosMensais(parametros: FiltroComMembro) {
  return Credito.find({
    usina_id: idObjeto(parametros.usinaId, "usina_id"),
    membro_id: idObjeto(parametros.membroId, "membro_id"),
    mes_referencia: { $regex: `^${parametros.ano}-` },
  }).sort({ mes_referencia: 1 }).lean<DocumentoFlexivel[]>();
}

// busca os consumos por mes do usuario
export function buscarConsumosMensais(parametros: FiltroComMembro) {
  const filtro: Record<string, unknown> = {
    membro_id: idObjeto(parametros.membroId, "membro_id"),
    mes_referencia: { $regex: `^${parametros.ano}-` },
  };

  if (parametros.usinaId) {
    filtro.$or = [
      { usina_id: idObjeto(parametros.usinaId, "usina_id") },
      { usina_id: { $exists: false } },
      { usina_id: null },
    ];
  }

  return ConsumosMensais.find(filtro).sort({
    mes_referencia: 1
  }).lean<DocumentoFlexivel[]>();
}

// salva ou atualiza os dados de geracao mensal
export function salvarOuAtualizarGeracao(parametros: {
  usinaId: string;
  mesReferencia: string;
  geracaoKwh: number;
}) {
  // busca por usina e mes de referencia
  // insere o novo documento no banco caso nao exista 
  // se ja existe, ele da um update do valor e da data
  return GeracaoMensal.findOneAndUpdate(
    {
      usina_id: idObjeto(parametros.usinaId, "usina_id"),
      mes_referencia: parametros.mesReferencia,
    },
    {
      $set: {
        geracao_kwh: parametros.geracaoKwh,
        data_lancamento: new Date(),
      },
    },
    { upsert: true, new: true }, // cria se nao existir e retorna o novo 
  ).lean<DocumentoFlexivel>();
}

export function salvarOuAtualzarCredito(parametros: {
  usinaId: string;
  membroId: string;
  mesReferencia: string;
  geracaoTotalKwh: number;
  percentualCota: number;
  creditosLiquidosKwh: number;
}) {
  return Credito.findOneAndUpdate(
    {
      usina_id: idObjeto(parametros.usinaId, "usina_id"),
      membro_id: idObjeto(parametros.membroId, "membro_id"),
      mes_referencia: parametros.mesReferencia,
    },
    {
      $set: {
        geracao_total_kwh: parametros.geracaoTotalKwh,
        percentual_cota: parametros.percentualCota,
        creditos_brutos_kwh: parametros.creditosLiquidosKwh,
        perdas_transmissao_kwh: 0,
        creditos_liquidos_kwh: parametros.creditosLiquidosKwh,
      },
    },
    { upsert: true, new: true },
  ).lean<DocumentoFlexivel>();
}