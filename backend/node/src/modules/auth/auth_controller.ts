//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// recebe as requisições HTTP de cadastro, login e recuperação de senha e devolve JSON
// erros esperados (ErroHttp) viram {mensagem, campos}; o resto cai no tratador de erros do server.ts

import { NextFunction, Request, Response } from "express";
import { ErroHttp } from "../perfil/perfil_validacao";
import {
  cadastrarMembro,
  entrar,
  redefinirSenha,
  solicitarRecuperacao,
} from "./auth_service";

function tratarErro(erro: unknown, resposta: Response, proximo: NextFunction) {
  if (erro instanceof ErroHttp) {
    return resposta.status(erro.status).json({
      mensagem: erro.message,
      ...(Object.keys(erro.campos).length > 0 ? { campos: erro.campos } : {}),
    });
  }
  proximo(erro);
}

export async function cadastro(requisicao: Request, resposta: Response, proximo: NextFunction) {
  try {
    resposta.status(201).json(await cadastrarMembro(requisicao.body ?? {}));
  } catch (erro) {
    tratarErro(erro, resposta, proximo);
  }
}

export async function login(requisicao: Request, resposta: Response, proximo: NextFunction) {
  try {
    resposta.json(await entrar(requisicao.body ?? {}));
  } catch (erro) {
    tratarErro(erro, resposta, proximo);
  }
}

export async function recuperarSenha(requisicao: Request, resposta: Response, proximo: NextFunction) {
  try {
    resposta.json(await solicitarRecuperacao(requisicao.body ?? {}));
  } catch (erro) {
    tratarErro(erro, resposta, proximo);
  }
}

export async function redefinir(requisicao: Request, resposta: Response, proximo: NextFunction) {
  try {
    resposta.json(await redefinirSenha(requisicao.body ?? {}));
  } catch (erro) {
    tratarErro(erro, resposta, proximo);
  }
}
