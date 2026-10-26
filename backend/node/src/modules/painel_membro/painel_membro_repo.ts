// autora: Maria Júlia Lazarini Oleto
// significado do arquivo:
// consultas de banco de dados para o painel administrativo do membro (dashboard)

import mongoose from "mongoose";
import {
  Cota,
  Credito,
  ConsumosMensais,
  GeracaoMensal,
  Membro,
} from "../geracao_creditos/energia_model";

export type DocumentoFlexivel = Record<string, unknown>;

// converte um string para ObjectId se for valido
function paraIdObjeto(valor?: string) {
  if (valor && mongoose.Types.ObjectId.isValid(valor)) {
    return new mongoose.Types.ObjectId(valor);
  }
  return undefined;
}

// padrao usado nas buscas:
// funcao recebe os paramentros (mesmo se estiver vazio)
// cria um filtro com os parametros 
// transforma as strings com os ids em ObjectId
// coloca os ObjectId no filtro, se estiverem validos
// usa o filtro na busca e retorna o dado encontrado  

// busca as informacoes do membro no banco (ou o primeiro membro disponivel)
export async function buscarMembroPorIdOuPrimeiro(membroId?: string) {
  const id = paraIdObjeto(membroId);
  if (id) {
    const membro = await Membro.findById(id).lean<DocumentoFlexivel>();
    if (membro) return membro;
  }

  // se nao passou id ou nao encontrou, busca o primeiro membro cadastrado
  const primeiroMembro = await Membro.findOne({
    $or: [{ tipo_usuario: "membro" }, { tipo_usuario: { $exists: false } }],
  }).lean<DocumentoFlexivel>();

  if (primeiroMembro) return primeiroMembro;

  // retorna qualquer membro cadastrado
  return Membro.findOne().lean<DocumentoFlexivel>();
}

// busca a cota do membro na usina
export async function buscarCotaDoMembro(membroId?: string, usinaId?: string) {
  const filtro: Record<string, unknown> = {};
  const idMembro = paraIdObjeto(membroId);
  const idUsina = paraIdObjeto(usinaId);

  if (idMembro) filtro.membro_id = idMembro;
  if (idUsina) filtro.usina_id = idUsina;

  return Cota.findOne(filtro)
    .sort({ percentual: -1, data_inicio: -1 })
    .lean<DocumentoFlexivel>();
}

// busca todos os dados de geração mensal do ano
export async function buscarGeracoesDoAno(usinaId?: string, ano = 2026) {
  const filtro: Record<string, unknown> = {
    mes_referencia: { $regex: `^${ano}-` },
  };

  const idUsina = paraIdObjeto(usinaId);
  if (idUsina) filtro.usina_id = idUsina;

  // retorna as geracoes ordenadas por mes (usadas no grafico)
  return GeracaoMensal.find(filtro)
    .sort({ mes_referencia: 1 })
    .lean<DocumentoFlexivel[]>();
}

// busca os creditos mensais do membro no ano 
export async function buscarCreditosDoMembro(
  membroId?: string,
  usinaId?: string,
  ano = 2026,
) {
  const filtro: Record<string, unknown> = {
    mes_referencia: { $regex: `^${ano}-` },
  };
  const idMembro = paraIdObjeto(membroId);
  const idUsina = paraIdObjeto(usinaId);

  if (idMembro) filtro.membro_id = idMembro;
  if (idUsina) filtro.usina_id = idUsina;

  // retorna os creditos ordenados por mes (usados no card)
  return Credito.find(filtro)
    .sort({ mes_referencia: 1 })
    .lean<DocumentoFlexivel[]>();
}

// busca os consumos mensais do membro no ano
export async function buscarConsumosDoMembro(
  membroId?: string,
  usinaId?: string,
  ano = 2026,
) {
  const filtro: Record<string, unknown> = {
    mes_referencia: { $regex: `^${ano}-` },
  };
  const idMembro = paraIdObjeto(membroId);
  if (idMembro) filtro.membro_id = idMembro;

  if (usinaId && mongoose.Types.ObjectId.isValid(usinaId)) {
    filtro.$or = [
      { usina_id: new mongoose.Types.ObjectId(usinaId) },
      { usina_id: { $exists: false } },
      { usina_id: null },
    ];
  }

  // retorna os consumos ordenados por mes 
  return ConsumosMensais.find(filtro)
    .sort({ mes_referencia: 1 })
    .lean<DocumentoFlexivel[]>();
}
