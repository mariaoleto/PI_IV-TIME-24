// autora: Maria Julia Lazarini Oleto

// significado do arquivo:
// recebe a requisicao HTTP, chama o service e devolve a resposta.

import { NextFunction, Request, Response } from "express";
import { montarResumoEnergia } from "./energia_service";
import { listarCotasDistribuicao } from "./energia_service";

// monta e retorna em formato json o resumo dos dados baseado no ano, usina e membro
export async function buscarResumoEnergia(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const resumo = await montarResumoEnergia({
      ano: requisicao.query.ano?.toString(),
      usinaId: requisicao.query.usina_id?.toString(),
      membroId: requisicao.query.membro_id?.toString(),
    });

    resposta.json(resumo);
  } catch (erro) {
    proximo(erro);
  }
}

// monta e retorna em formato json um mapa dos nomes dos membros, com suas cotas, percentual e tarifa 
export async function buscarCotasDistribuicao(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const cotas = await listarCotasDistribuicao({
      usinaId: requisicao.query.usina_id?.toString(),
      membroId: requisicao.query.membro_id?.toString(),
    });

    resposta.json(cotas);
  } catch (erro) {
    proximo(erro);
  }
}