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
} from "./energia_model";

export type DocumentoFlexivel = Record<string, unknown>;

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

  return Cota.findOne(filtro)
    .sort({ data_inicio: -1 })
    .lean<DocumentoFlexivel>();
}

// busca os dados da geracao por mes 
export function buscarGeracoesMensais(parametros: FiltroBase) {
  return GeracaoMensal.find({
    usina_id: idObjeto(parametros.usinaId, "usina_id"),
    mes_referencia: { $regex: `^${parametros.ano}-` },
  })
    .sort({ mes_referencia: 1 })
    .lean<DocumentoFlexivel[]>();
}

// busca os creditos por mes do usuario 
export function buscarCreditosMensais(parametros: FiltroComMembro) {
  return Credito.find({
    usina_id: idObjeto(parametros.usinaId, "usina_id"),
    membro_id: idObjeto(parametros.membroId, "membro_id"),
    mes_referencia: { $regex: `^${parametros.ano}-` },
  })
    .sort({ mes_referencia: 1 })
    .lean<DocumentoFlexivel[]>();
}

// busca os consumos por mes do usuario
export function buscarConsumosMensais(parametros: FiltroComMembro) {
  return ConsumosMensais.find({
    usina_id: idObjeto(parametros.usinaId, "usina_id"),
    membro_id: idObjeto(parametros.membroId, "membro_id"),
    mes_referencia: { $regex: `^${parametros.ano}-` },
  })
    .sort({ mes_referencia: 1 })
    .lean<DocumentoFlexivel[]>();
}
