// autora: Maria Júlia Lazarini Oleto
// significado do arquivo:
// controller que recebe a requisição HTTP do dashboard do membro e retorna os dados consolidados

import { NextFunction, Request, Response } from "express";
import { obterDashboardMembro } from "./painel_membro_service";

export async function buscarDashboardMembro(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const dados = await obterDashboardMembro({
      ano: requisicao.query.ano?.toString(),
      usinaId: requisicao.query.usina_id?.toString(),
      membroId: requisicao.query.membro_id?.toString(),
      email: requisicao.query.email?.toString(),
    });

    resposta.json(dados);
  } catch (erro) {
    proximo(erro);
  }
}
