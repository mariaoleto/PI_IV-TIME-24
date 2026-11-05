//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// middlewares que protegem rotas: exigem o header "Authorization: Bearer <token>"
// uso:  roteador.use(exigirAutenticacao);   ou   roteador.get("/x", exigirAdmin, controller);

import { NextFunction, Request, Response } from "express";
import { UsuarioToken, verificarToken } from "./auth_token";

export type RequisicaoAutenticada = Request & { usuario?: UsuarioToken };

export function exigirAutenticacao(requisicao: Request, resposta: Response, proximo: NextFunction) {
  const [esquema, token] = (requisicao.headers.authorization ?? "").split(" ");
  const usuario = esquema === "Bearer" && token ? verificarToken(token) : null;

  if (!usuario) {
    return resposta
      .status(401)
      .json({ mensagem: "Sessão inválida ou expirada. Entre novamente." });
  }
  (requisicao as RequisicaoAutenticada).usuario = usuario;
  proximo();
}

// use depois de exigirAutenticacao
export function exigirAdmin(requisicao: Request, resposta: Response, proximo: NextFunction) {
  const usuario = (requisicao as RequisicaoAutenticada).usuario;
  if (usuario?.tipo !== "admin") {
    return resposta.status(403).json({ mensagem: "Acesso restrito a administradores." });
  }
  proximo();
}
