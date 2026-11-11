// autora: Maria Julia Lazarini Oleto
// RA: 25006031

// significado do arquivo:
// recebe a requisicao HTTP, chama o service e devolve a resposta.

import { NextFunction, Request, Response } from "express";
import {
  montarResumoEnergia,
  listarCotasDistribuicao,
  registrarLancamentoMensal,
  consultarTelemetriaUsinaTcp,
} from "./energia_service";

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

// salva o lancamento mensal
export async function salvarLancamentoMensal(
  requisicao: Request,
  resposta: Response,
  proximo: NextFunction,
) {
  try {
    const { mes_referencia, geracao_kwh, usina_id } = requisicao.body;
    if (!mes_referencia) {
      return resposta.status(400).json({ message: "O periodo de referência (mes_referencia) é obrigatório." });
    }
    if (geracao_kwh === undefined || Number(geracao_kwh) <= 0) {
      return resposta.status(400).json({ message: "A geração total da usina (geracao_kwh) deve ser maior que zero." });
    }
    const resultado = await registrarLancamentoMensal({
      mesReferencia: mes_referencia.toString(),
      geracaoKwh: Number(geracao_kwh),
      usinaId: usina_id?.toString(),
    });
    resposta.status(201).json(resultado);
  } catch (erro) {
    proximo(erro);
  }
}

// consulta a telemetria do servidor TCP em Java 
export async function consultarTelemetriaTcp(_requisicao: Request, resposta: Response) {
  const resultado = await consultarTelemetriaUsinaTcp();

  if (resultado.status_servidor_tcp === "online") {
    return resposta.json({
      status_servidor_tcp: "online",
      servidor: resultado.servidor,
      telemetria: resultado.telemetria,
      detalhes: resultado,
    });
  }

  return resposta.status(503).json({
    status_servidor_tcp: "offline",
    servidor: resultado.servidor,
    mensagem: resultado.mensagem_erro || "Servidor TCP Java não está ativo na porta 5050",
    aviso: "Inicie o servidor Java com: java -cp backend/java/bin br.com.solis.tcp.Servidor",
  });
}