//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// consultas e gravações no banco para o perfil do membro
// reaproveita os modelos Membro e Cota (módulo de energia) e Usina (painel admin)

import mongoose from "mongoose";
import { Cota, Membro } from "../geracao_creditos/energia_model";
import { Usina } from "../painel_admin/painel_model";
import { Contrato } from "./perfil_model";
import { ErroHttp } from "./perfil_validacao";

export type Doc = Record<string, any>;

export type DadosAtualizacaoMembro = {
  nome: string;
  email: string;
  telefone: string | null;
};

// converte string em ObjectId; id inválido vira erro 400 (e não um 500 do mongoose)
export function idObjeto(valor: string, nomeCampo = "id") {
  if (!mongoose.Types.ObjectId.isValid(valor)) {
    throw new ErroHttp(400, `${nomeCampo} inválido`);
  }
  return new mongoose.Types.ObjectId(valor);
}

function escaparRegex(texto: string) {
  return texto.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// diferente do painel do membro, aqui NÃO existe "pega o membro mais recente":
// para editar dados pessoais é preciso saber exatamente quem é o membro
export function buscarMembroPorId(membroId: string) {
  return Membro.findById(idObjeto(membroId, "membro_id")).lean<Doc>();
}

export function buscarMembroPorEmail(email: string) {
  return Membro.findOne({
    email: new RegExp(`^${escaparRegex(email.trim())}$`, "i"),
  }).lean<Doc>();
}

// verifica se outro membro já usa o e-mail (sem diferenciar maiúsculas/minúsculas)
export async function emailEmUsoPorOutro(email: string, membroId: string) {
  const existente = await Membro.findOne({
    email: new RegExp(`^${escaparRegex(email.trim())}$`, "i"),
    _id: { $ne: idObjeto(membroId, "membro_id") },
  })
    .select("_id")
    .lean<Doc>();
  return existente !== null;
}

export function atualizarDadosMembro(membroId: string, dados: DadosAtualizacaoMembro) {
  const alteracao: Record<string, any> = {
    $set: { nome: dados.nome, email: dados.email, atualizado_em: new Date() },
  };
  if (dados.telefone === null) alteracao.$unset = { telefone: "" };
  else alteracao.$set.telefone = dados.telefone;

  return Membro.findByIdAndUpdate(idObjeto(membroId, "membro_id"), alteracao, {
    new: true,
  }).lean<Doc>();
}

export async function atualizarSenhaMembro(membroId: string, senhaHash: string) {
  await Membro.updateOne(
    { _id: idObjeto(membroId, "membro_id") },
    { $set: { senha_hash: senhaHash, senha_alterada_em: new Date() } },
  );
}

// cota mais recente do membro (mesma coleção usada pelo painel do membro)
export function buscarCotaDoMembro(membroId: string) {
  return Cota.findOne({ membro_id: idObjeto(membroId, "membro_id") })
    .sort({ data_inicio: -1, _id: -1 })
    .lean<Doc>();
}

export function buscarUsinaPorId(usinaId: string | undefined) {
  if (!usinaId || !mongoose.Types.ObjectId.isValid(usinaId)) return Promise.resolve(null);
  return Usina.findById(usinaId).lean<Doc>();
}

// contratos do membro; o service escolhe o vigente entre eles
export function listarContratosDoMembro(membroId: string) {
  return Contrato.find({ membro_id: idObjeto(membroId, "membro_id") })
    .sort({ data_assinatura: -1, _id: -1 })
    .lean<Doc[]>();
}
