//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// acesso ao banco para o painel administrativo (somente leitura)
// reaproveita os modelos de cotas, geração, créditos e consumos do módulo de energia

import mongoose from "mongoose";
import {
  ConsumosMensais,
  Cota,
  Credito,
  GeracaoMensal,
} from "../geracao_creditos/energia_model";
import { Usina } from "./painel_model";

export type Doc = Record<string, any>;

function idObjeto(valor: string, nomeCampo: string) {
  if (!mongoose.Types.ObjectId.isValid(valor)) {
    throw new Error(`${nomeCampo} invalido`);
  }
  return new mongoose.Types.ObjectId(valor);
}

export function buscarUsina(usinaId: string) {
  return Usina.findById(idObjeto(usinaId, "usina_id")).lean<Doc>();
}

// primeira usina ativa (ativa ausente conta como ativa)
export function buscarUsinaAtiva() {
  return Usina.findOne({ ativa: { $ne: false } }).sort({ _id: 1 }).lean<Doc>();
}

// fallback para bases que ainda não possuem a coleção de usinas
export async function buscarUsinaIdPelasCotas() {
  const cota = await Cota.findOne({ usina_id: { $ne: null } })
    .sort({ _id: 1 })
    .lean<Doc>();
  return cota?.usina_id?.toString() as string | undefined;
}

export function listarCotas(usinaId: string) {
  return Cota.find({ usina_id: idObjeto(usinaId, "usina_id") }).lean<Doc[]>();
}

export function listarGeracoes(usinaId: string) {
  return GeracaoMensal.find({ usina_id: idObjeto(usinaId, "usina_id") })
    .sort({ mes_referencia: 1 })
    .lean<Doc[]>();
}

export function listarCreditos(usinaId: string, mesReferencia: string) {
  return Credito.find({
    usina_id: idObjeto(usinaId, "usina_id"),
    mes_referencia: mesReferencia,
  }).lean<Doc[]>();
}

// aceita documentos antigos sem usina_id (mesmo critério do módulo de energia)
export function listarConsumos(usinaId: string, mesReferencia: string) {
  return ConsumosMensais.find({
    mes_referencia: mesReferencia,
    $or: [
      { usina_id: idObjeto(usinaId, "usina_id") },
      { usina_id: { $exists: false } },
      { usina_id: null },
    ],
  }).lean<Doc[]>();
}
