import { NextFunction, Request, Response } from "express";
import { RequisicaoAutenticada } from "../auth/auth_middleware";
import {
  buscarArquivoRelatorio,
  buscarRelatoriosDoMembro,
  ErroRelatorio,
  gerarRelatorio,
  TipoRelatorio,
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

export async function baixarRelatorio(requisicao: Request, resposta: Response, proximo: NextFunction) {
  try {
    const relatorio = await buscarArquivoRelatorio(
      membroLogado(requisicao),
      String(requisicao.params.id),
    );
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
