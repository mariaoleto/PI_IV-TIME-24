//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// recebe a requisição HTTP do painel administrativo e devolve o agregado em JSON

import { NextFunction, Request, Response } from "express";
import { montarPainelAdmin, UsinaNaoEncontrada } from "./painel_service";

export async function buscarPainelAdmin(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const painel = await montarPainelAdmin(requisicao.query.usina_id?.toString());
    resposta.json(painel);
  } catch (erro) {
    if (erro instanceof UsinaNaoEncontrada) {
      return resposta.status(404).json({ message: erro.message });
    }
    proximo(erro);
  }
}
