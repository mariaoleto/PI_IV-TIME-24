import { NextFunction, Request, Response } from "express";
import {
  adicionarMembroNaUsina,
  atualizarCotasUsina,
  atualizarUsina,
  buscarContratoUsina,
  criarUsina,
  ErroGestao,
  excluirContratoUsina,
  excluirUsina,
  extrairArquivoMultipart,
  listarMembrosUsina,
  listarUsinas,
  salvarContratoUsina,
} from "./gestao_service";

function tratarErroGestao(
  erro: unknown,
  resposta: Response,
  proximo: NextFunction,
) {
  if (erro instanceof ErroGestao) {
    return resposta.status(erro.status).json({
      erro: erro.message,
      mensagem: erro.message,
      message: erro.message,
    });
  }
  proximo(erro);
}

export async function listarUsinasController(
  _requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    resposta.json(await listarUsinas());
  } catch (erro) {
    tratarErroGestao(erro, resposta, proximo);
  }
}

export async function criarUsinaController(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const criada = await criarUsina(requisicao.body ?? {});
    resposta.status(201).json(criada);
  } catch (erro) {
    tratarErroGestao(erro, resposta, proximo);
  }
}

export async function atualizarUsinaController(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const id = String(requisicao.params.id ?? "");
    const atualizada = await atualizarUsina(id, requisicao.body ?? {});
    resposta.json(atualizada);
  } catch (erro) {
    tratarErroGestao(erro, resposta, proximo);
  }
}

export async function excluirUsinaController(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const id = String(requisicao.params.id ?? "");
    await excluirUsina(id);
    resposta.status(204).send();
  } catch (erro) {
    tratarErroGestao(erro, resposta, proximo);
  }
}

export async function listarMembrosController(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const usinaId = requisicao.query.usina_id?.toString();
    resposta.json(await listarMembrosUsina(usinaId));
  } catch (erro) {
    tratarErroGestao(erro, resposta, proximo);
  }
}

export async function adicionarMembroController(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const membro = await adicionarMembroNaUsina(requisicao.body ?? {});
    resposta.status(201).json(membro);
  } catch (erro) {
    tratarErroGestao(erro, resposta, proximo);
  }
}

export async function atualizarCotasController(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const id = String(requisicao.params.id ?? "");
    const membros = await atualizarCotasUsina(id, requisicao.body?.cotas);
    resposta.json(membros);
  } catch (erro) {
    tratarErroGestao(erro, resposta, proximo);
  }
}

export async function buscarContratoController(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const id = String(requisicao.params.id ?? "");
    resposta.json(await buscarContratoUsina(id));
  } catch (erro) {
    tratarErroGestao(erro, resposta, proximo);
  }
}

export async function enviarContratoController(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const id = String(requisicao.params.id ?? "");
    let arquivo;

    if (Buffer.isBuffer(requisicao.body)) {
      arquivo = extrairArquivoMultipart(
        requisicao.body,
        requisicao.headers["content-type"],
      );
    } else if (
      requisicao.body &&
      typeof requisicao.body === "object" &&
      typeof requisicao.body.conteudoBase64 === "string"
    ) {
      const conteudo = Buffer.from(requisicao.body.conteudoBase64, "base64");
      if (conteudo.length === 0) {
        throw new ErroGestao("O arquivo do contrato está vazio.");
      }
      arquivo = {
        nomeArquivo:
          typeof requisicao.body.nomeArquivo === "string" &&
          requisicao.body.nomeArquivo.trim().length > 0
            ? requisicao.body.nomeArquivo.trim()
            : "contrato.pdf",
        mimeType: "application/pdf",
        conteudo,
        tamanhoBytes: conteudo.length,
      };
    } else {
      throw new ErroGestao("Envie o contrato como multipart/form-data.");
    }

    const salvo = await salvarContratoUsina(id, arquivo);
    resposta.status(201).json(salvo);
  } catch (erro) {
    tratarErroGestao(erro, resposta, proximo);
  }
}

export async function excluirContratoController(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const id = String(requisicao.params.id ?? "");
    await excluirContratoUsina(id);
    resposta.status(204).send();
  } catch (erro) {
    tratarErroGestao(erro, resposta, proximo);
  }
}

