//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// recebe as requisições HTTP do perfil do membro, chama o service e devolve JSON
// erros esperados (validação, não encontrado, e-mail repetido...) viram ErroHttp -> {mensagem, campos}
//
// as rotas passam por exigirAutenticacao (perfil_routes.ts): o id de quem está logado vem do token.
// um membro só mexe no próprio perfil; administrador pode consultar/editar o de outros.

import { NextFunction, Request, Response } from "express";
import { RequisicaoAutenticada } from "../auth/auth_middleware";
import {
  alterarSenha,
  editarPerfil,
  obterContrato,
  obterPerfil,
} from "./perfil_service";
import { ErroHttp } from "./perfil_validacao";

function usuarioLogado(requisicao: Request) {
  const usuario = (requisicao as RequisicaoAutenticada).usuario;
  if (!usuario) throw new ErroHttp(401, "Sessão inválida ou expirada. Entre novamente.");
  return usuario;
}

// id do membro da URL (/perfil/:id). só o dono ou um administrador pode acessar
function obterMembroId(requisicao: Request): string {
  const usuario = usuarioLogado(requisicao);
  const alvo = String(requisicao.params.id ?? "");
  if (alvo !== usuario.id && usuario.tipo !== "admin") {
    throw new ErroHttp(403, "Você não tem permissão para acessar este perfil");
  }
  return alvo;
}

function tratarErro(erro: unknown, resposta: Response, proximo: NextFunction) {
  if (erro instanceof ErroHttp) {
    return resposta.status(erro.status).json({
      mensagem: erro.message,
      ...(Object.keys(erro.campos).length > 0 ? { campos: erro.campos } : {}),
    });
  }
  proximo(erro);
}

export async function buscarPerfil(requisicao: Request, resposta: Response, proximo: NextFunction) {
  try {
    const usuario = usuarioLogado(requisicao);
    const membroIdConsulta = requisicao.query.membro_id?.toString();
    const emailConsulta = requisicao.query.email?.toString();

    // membro comum: sempre o próprio perfil (ignora os parâmetros)
    // administrador: pode consultar outro membro por membro_id ou email
    let params: { membroId?: string; email?: string } = { membroId: usuario.id };
    if (usuario.tipo === "admin" && (membroIdConsulta || emailConsulta)) {
      params = { membroId: membroIdConsulta, email: emailConsulta };
    }
    resposta.json(await obterPerfil(params));
  } catch (erro) {
    tratarErro(erro, resposta, proximo);
  }
}

export async function atualizarPerfil(requisicao: Request, resposta: Response, proximo: NextFunction) {
  try {
    resposta.json(await editarPerfil(obterMembroId(requisicao), requisicao.body ?? {}));
  } catch (erro) {
    tratarErro(erro, resposta, proximo);
  }
}

export async function trocarSenha(requisicao: Request, resposta: Response, proximo: NextFunction) {
  try {
    await alterarSenha(obterMembroId(requisicao), requisicao.body ?? {});
    resposta.json({ mensagem: "Senha alterada com sucesso" });
  } catch (erro) {
    tratarErro(erro, resposta, proximo);
  }
}

export async function buscarContrato(requisicao: Request, resposta: Response, proximo: NextFunction) {
  try {
    resposta.json(await obterContrato(obterMembroId(requisicao)));
  } catch (erro) {
    tratarErro(erro, resposta, proximo);
  }
}
