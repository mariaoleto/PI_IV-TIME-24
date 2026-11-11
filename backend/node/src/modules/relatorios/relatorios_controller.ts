import { NextFunction, Request, Response } from "express";
import { RequisicaoAutenticada } from "../auth/auth_middleware";
import { verificarToken } from "../auth/auth_token";
import {
  buscarArquivoRelatorio,
  buscarRelatoriosDoMembro,
  ErroRelatorio,
  gerarRelatorio,
  prepararTicketDownload,
  TipoRelatorio,
  validarTicketDownloadRelatorio,
} from "./relatorios_service";

function membroLogado(requisicao: Request) {
  const membroId = (requisicao as RequisicaoAutenticada).usuario?.id;
  if (!membroId) throw new ErroRelatorio("Sessão inválida ou expirada.", 401);
  return membroId;
}

function tratarErro(erro: unknown, resposta: Response, proximo: NextFunction) {
  if (erro instanceof ErroRelatorio) {
    return resposta.status(erro.status).json({ mensagem: erro.message });
  }
  proximo(erro);
}

function endpointGeracao(tipo: TipoRelatorio) {
  return async (requisicao: Request, resposta: Response, proximo: NextFunction) => {
    try {
      const gerado = await gerarRelatorio(membroLogado(requisicao), tipo, {
        referencia: requisicao.body?.referencia?.toString(),
        ano: requisicao.body?.ano?.toString(),
      });
      resposta.setHeader("Content-Type", "application/pdf");
      resposta.setHeader(
        "Content-Disposition",
        `attachment; filename="${tipo}-${gerado.registro._id.toString()}.pdf"`,
      );
      resposta.setHeader("Content-Length", gerado.arquivo.length);
      resposta.setHeader("X-Relatorio-Id", gerado.registro._id.toString());
      resposta.send(gerado.arquivo);
    } catch (erro) {
      tratarErro(erro, resposta, proximo);
    }
  };
}

export const gerarRelatorioMensal = endpointGeracao("relatorio_mensal");
export const gerarExtratoCreditos = endpointGeracao("extrato_creditos");
export const gerarDemonstrativoAnual = endpointGeracao("demonstrativo_anual");

export async function listarRelatorios(requisicao: Request, resposta: Response, proximo: NextFunction) {
  try {
    resposta.json(await buscarRelatoriosDoMembro(membroLogado(requisicao)));
  } catch (erro) {
    tratarErro(erro, resposta, proximo);
  }
}

export async function emitirTicketDownload(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const ticket = await prepararTicketDownload(
      membroLogado(requisicao),
      String(requisicao.params.id),
    );
    resposta.json(ticket);
  } catch (erro) {
    tratarErro(erro, resposta, proximo);
  }
}

export async function baixarRelatorio(requisicao: Request, resposta: Response, proximo: NextFunction) {
  try {
    const relatorioId = String(requisicao.params.id);
    const [esquema, token] = (requisicao.headers.authorization ?? "").split(" ");
    const usuarioBearer = esquema === "Bearer" && token ? verificarToken(token) : null;
    const ticketQuery = requisicao.query.ticket?.toString() ?? "";
    const membroViaTicket = !usuarioBearer && ticketQuery
      ? validarTicketDownloadRelatorio(ticketQuery, relatorioId)
      : null;

    const membroId = usuarioBearer?.id ?? membroViaTicket;
    if (!membroId) {
      throw new ErroRelatorio("Sessão inválida ou expirada. Entre novamente.", 401);
    }

    const relatorio = await buscarArquivoRelatorio(membroId, relatorioId);
    resposta.setHeader("Content-Type", "application/pdf");
    resposta.setHeader(
      "Content-Disposition",
      `attachment; filename="${relatorio.tipo}-${relatorio._id.toString()}.pdf"`,
    );
    resposta.setHeader("Content-Length", relatorio.tamanho_bytes);
    resposta.send(relatorio.arquivo_pdf);
  } catch (erro) {
    tratarErro(erro, resposta, proximo);
  }
}
