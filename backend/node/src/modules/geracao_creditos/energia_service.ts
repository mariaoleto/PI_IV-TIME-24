// autora: Maria Julia Lazarini Oleto
// RA: 25006031

// significado do arquivo:
// criacao das regras de negocio e calculos de geracao, consumo e créditos

import mongoose from "mongoose";
import {
  buscarConsumosMensais,
  buscarCotaMaisRecente,
  buscarCreditosMensais,
  buscarGeracoesMensais,
  DocumentoFlexivel,
  buscarTodasCotasComMembros,
  salvarOuAtualizarGeracao,
  salvarOuAtualzarCredito,
} from "./energia_repo";

// comunicacao TCP com o servidor Java 
import { enviarComandoTcp } from "../../utils/cliente_tcp_java";

const rotulosMeses = [
  "Jan",
  "Fev",
  "Mar",
  "Abr",
  "Mai",
  "Jun",
  "Jul",
  "Ago",
  "Set",
  "Out",
  "Nov",
  "Dez",
];

// parametros usados nas buscas 
export type EnviarComandoTcpFn = (comando: string, tempoLimiteMs?: number) => Promise<string>;

export type TelemetriaUsinaTcp = {
  status_servidor_tcp: "online" | "offline";
  servidor: string;
  telemetria: string;
  usina?: string;
  status_operacao?: string;
  geracao_atual?: string;
  tensao?: string;
  frequencia?: string;
  consultado_em?: string;
  mensagem_erro?: string;
};

type ParametrosResumoEnergia = {
  ano?: string;
  usinaId?: string;
  membroId?: string;
  enviarTcp?: EnviarComandoTcpFn;
};

export function interpretarTelemetriaUsina(respostaJava: string): TelemetriaUsinaTcp {
  const texto = respostaJava.trim();
  const lerCampo = (chave: string) => {
    const match = new RegExp(`(?:^|\\s)${chave}=([^\\s]+)`).exec(texto);
    return match?.[1];
  };

  if (!texto.startsWith("OK")) {
    return {
      status_servidor_tcp: "offline",
      servidor: "Java Socket TCP (porta 5050)",
      telemetria: texto,
      mensagem_erro: texto || "Resposta inválida do servidor TCP Java",
    };
  }

  return {
    status_servidor_tcp: "online",
    servidor: "Java Socket TCP (porta 5050)",
    telemetria: texto,
    usina: lerCampo("USINA"),
    status_operacao: lerCampo("STATUS"),
    geracao_atual: lerCampo("GERACAO_ATUAL"),
    tensao: lerCampo("TENSAO"),
    frequencia: lerCampo("FREQ"),
    consultado_em: new Date().toISOString(),
  };
}

export async function consultarTelemetriaUsinaTcp(
  enviarTcp: EnviarComandoTcpFn = enviarComandoTcp,
): Promise<TelemetriaUsinaTcp> {
  try {
    const respostaJava = await enviarTcp("STATUS_USINA");
    return interpretarTelemetriaUsina(respostaJava);
  } catch (erro) {
    const mensagemErro = erro instanceof Error ? erro.message : "Erro desconhecido";
    return {
      status_servidor_tcp: "offline",
      servidor: "Java Socket TCP (porta 5050)",
      telemetria: "",
      mensagem_erro: mensagemErro,
    };
  }
}

// converte um valor em um numero
// caso nao seja possivel, retorna o numero padrao 0
function paraNumero(valor: unknown, padrao = 0) {
  const numero = Number(valor);
  return Number.isFinite(numero) ? numero : padrao;
}
// gera uma string de formatacao AAAA-MM com o ano e mes (ex: 2026-05)
function chaveMes(ano: number, indiceMes: number) {
  return `${ano}-${String(indiceMes + 1).padStart(2, "0")}`;
}

// retorna o valor de um campo
export function idObjeto(valor: string | undefined, nomeCampo: string) {
  if (!valor || !mongoose.Types.ObjectId.isValid(valor)) {
    throw new Error(`${nomeCampo} invalido`);
  }

  return new mongoose.Types.ObjectId(valor);
}

// retorna o valor do consumo 
function lerConsumoKwh(consumo: DocumentoFlexivel | undefined) {
  if (!consumo) return 0;
  // usa diferentes nomes de campos de consumo 
  // para permitir a compatibilidade com outros documentos do tipo
  return paraNumero(
    consumo.consumo_kwh ??
    consumo.consumo_total_kwh ??
    consumo.total_consumo_kwh ??
    consumo.kwh,
  );
}

export function agruparConsumosPorMes(consumos: DocumentoFlexivel[]) {
  const consumoPorMes = new Map<string, number>();
  for (const consumo of consumos) {
    const referencia = consumo.mes_referencia?.toString();
    if (!referencia) continue;
    consumoPorMes.set(
      referencia,
      (consumoPorMes.get(referencia) ?? 0) + lerConsumoKwh(consumo),
    );
  }
  return consumoPorMes;
}

// monta e retorna o resumo dos dados da energia, conforme os parametros (ano, id usina e id membro)
// usados nos objetos ResumoEnergia e MesEnergia
export async function montarResumoEnergia(parametros: ParametrosResumoEnergia) {

  // atribui os valores as variaveis 
  const ano = paraNumero(parametros.ano, new Date().getFullYear());
  const usinaIdSolicitada = parametros.usinaId;
  const membroIdSolicitado = parametros.membroId;

  // request da cota mais recente 
  const cota = await buscarCotaMaisRecente({
    usinaId: usinaIdSolicitada,
    membroId: membroIdSolicitado,
  });

  // converte o id do usuario e da usina em string com o toString()
  // atribui o valor em variaveis 
  const usinaId =
    usinaIdSolicitada ??
    (cota?.usina_id instanceof mongoose.Types.ObjectId
      ? cota.usina_id.toString()
      : cota?.usina_id?.toString());
  const membroId =
    membroIdSolicitado ??
    (cota?.membro_id instanceof mongoose.Types.ObjectId
      ? cota.membro_id.toString()
      : cota?.membro_id?.toString());

  if (!usinaId) {
    throw new Error("Nenhuma usina encontrada para montar o resumo.");
  }

  // monta uma promisse com um array dos dados de geracao, credito e consumo 
  const [geracoes, creditos, consumos] = await Promise.all([
    buscarGeracoesMensais({ ano, usinaId }),
    // se o id existir, ele busca os dados no banco com os parametros, 
    // se nao, retorna uma promisse vazia
    membroId ? buscarCreditosMensais({ ano, usinaId, membroId }) : Promise.resolve([]),
    membroId ? buscarConsumosMensais({ ano, usinaId, membroId }) : Promise.resolve([]),
  ]);

  // cria maps com os todos os dados de geracao, credito e consumo 
  // pega o item do banco, transforma em string e coloca no map
  const geracaoPorMes = new Map(
    geracoes.map((item) => [item.mes_referencia?.toString(), item]),
  );
  const creditoPorMes = new Map(
    creditos.map((item) => [item.mes_referencia?.toString(), item]),
  );
  const consumoPorMes = agruparConsumosPorMes(consumos);

  // atribui e iniciliza os valores nas variaveis 
  const percentualCota = paraNumero(cota?.percentual);
  const tarifaKwh = paraNumero(cota?.tarifa_kwh);
  let totalConsumoKwh = 0;
  let totalGeracaoKwh = 0;
  let saldoAcumuladoKwh = 0;

  // cria e retorna o map do resumo dos dados mensais da energia 
  let tcpDisponivel = true;
  const meses = [];
  for (let indice = 0; indice < rotulosMeses.length; indice++) {
    const rotulo = rotulosMeses[indice];
    const referencia = chaveMes(ano, indice);
    const geracao = geracaoPorMes.get(referencia);
    const credito = creditoPorMes.get(referencia);
    const geracaoKwh = paraNumero(geracao?.geracao_kwh);

    let creditoCalculado =
      percentualCota > 0 ? geracaoKwh * (percentualCota / 100) : 0;

    // Se ainda não há crédito salvo no banco para este mês, consulta o cálculo via servidor TCP Java
    if (
      credito?.creditos_liquidos_kwh == null &&
      credito?.creditos_brutos_kwh == null &&
      geracaoKwh > 0 &&
      percentualCota > 0 &&
      tcpDisponivel
    ) {
      const resultadoTcp = await calcularCotasViaJavaTcp(
        geracaoKwh,
        [percentualCota],
        parametros.enviarTcp,
      );
      if (resultadoTcp && resultadoTcp[percentualCota] !== undefined) {
        creditoCalculado = resultadoTcp[percentualCota];
      } else {
        tcpDisponivel = false;
      }
    }

    const creditosLiquidosKwh = paraNumero(
      credito?.creditos_liquidos_kwh,
      paraNumero(credito?.creditos_brutos_kwh, creditoCalculado),
    );

    // le o consumo mensal e calcula o saldo do mes
    const consumoKwh = consumoPorMes.get(referencia) ?? 0;
    const saldoMesKwh = creditosLiquidosKwh - consumoKwh;

    // calculos da geracao, consumo e saldo totais
    totalGeracaoKwh += geracaoKwh;
    totalConsumoKwh += consumoKwh;
    saldoAcumuladoKwh += saldoMesKwh;

    // retorna os dados do mes 
    meses.push({
      mes: rotulo,
      mes_referencia: referencia,
      geracao_kwh: geracaoKwh,
      // toFixed() - retorna uma string de um numero com casa decimal
      creditos_liquidos_kwh: Number(creditosLiquidosKwh.toFixed(1)),
      consumo_kwh: consumoKwh,
      saldo_mes_kwh: Number(saldoMesKwh.toFixed(1)),
    });
  }

  // retorna os dados totais
  return {
    ano,
    usina_id: usinaId,
    membro_id: membroId,
    percentual_cota: percentualCota,
    tarifa_kwh: tarifaKwh,
    total_geracao_kwh: Number(totalGeracaoKwh.toFixed(1)),
    total_consumo_kwh: Number(totalConsumoKwh.toFixed(1)),
    saldo_acumulado_kwh: Number(saldoAcumuladoKwh.toFixed(1)),
    economia_estimada_reais: Number((saldoAcumuladoKwh * tarifaKwh).toFixed(2)),
    meses,
  };
}

// monta e retorna um mapa dos nomes dos membros, com suas cotas, percentual e tarifa 
export async function listarCotasDistribuicao(parametros: {
  usinaId?: string;
  membroId?: string;
}) {
  // espera retornar o mapa com as cotas e nomes dos membros
  const cotasComMembros = await buscarTodasCotasComMembros(
    parametros.usinaId,
    parametros.membroId,
  );
  // formata os dados 
  return cotasComMembros.map((item) => ({
    cota_id: (item.cota_id ?? item._id)?.toString(),
    membro_id: item.membro_id?.toString(),
    nome: item.nome_membro,
    percentual: paraNumero(item.percentual),
    tarifa_kwh: paraNumero(item.tarifa_kwh, 0.69),
  }));
}

// envia o calculo das cotas para o servidor Java via Socket TCP 
export async function calcularCotasViaJavaTcp(
  geracaoKwh: number,
  cotasPercentuais: number[],
  enviarTcp: EnviarComandoTcpFn = enviarComandoTcp,
): Promise<{ [percentual: number]: number } | null> {
  if (geracaoKwh <= 0 || cotasPercentuais.length === 0) {
    return null;
  }
  try {
    // junta as cotas com virgula ex: 20,35,15
    const cotasFormatadas = cotasPercentuais.join(",");
    // cria o comando que vai ser enviado para o servidor java 
    const comando = `CALCULAR_COTAS total=${geracaoKwh};cotas=${cotasFormatadas}`;

    // envia o comando e guarda a resposta na const 
    const respostaJava = await enviarTcp(comando);

    // se o java retornar com sucesso (comecando com OK)
    if (respostaJava.startsWith("OK")) {
      // cria um mapa de resultados com o percentual da cota = credito
      const mapaResultados: { [percentual: number]: number } = {};

      // divide a string de resposta depois do OK
      const partes = respostaJava.replace(/^OK\s*/, "").split(";");

      // percorre as partes da resposta e divide a cota do credito
      for (const parte of partes) {
        const [cotaStr, kwhStr] = parte.split("=");
        if (cotaStr && kwhStr) {
          const perc = parseFloat(cotaStr.replace("%", "").trim());
          const kwh = parseFloat(kwhStr.replace("kWh", "").trim());
          if (!isNaN(perc) && !isNaN(kwh)) {
            mapaResultados[perc] = kwh;
          }
        }
      }
      // retorna o mapa com os resultados 
      return mapaResultados;
    }

    // retorna null caso o servidor java nao esteja conectado 
    // usa o calculo local para gerar os creditos
    return null;
  } catch (erro) {
    console.warn("[Servidor TCP Java] Java offline ou ocupado, usando cálculo local.");
    return null;
  }
}

// registra o lancamento mensal da geracao e distribui os creditos entre os membros
export async function registrarLancamentoMensal(dados: {
  mesReferencia: string;
  geracaoKwh: number;
  usinaId?: string;
}) {
  // se o id da usina nao for passado nos parametros
  // busca no banco com as cotas
  const cotas = await buscarTodasCotasComMembros(dados.usinaId);
  if (cotas.length === 0) {
    throw new Error("Nenhuma cota de membro encontrada");
  }
  const usinaId = dados.usinaId ?? cotas[0].usina_id?.toString();
  if (!usinaId) {
    throw new Error("Usina não identificada");
  }
  // salva ou atualiza no banco
  await salvarOuAtualizarGeracao({
    usinaId,
    mesReferencia: dados.mesReferencia,
    geracaoKwh: dados.geracaoKwh,
  });

  // pega os percentuais de cada cota
  const percentuais = cotas.map((c) => paraNumero(c.percentual));

  // manda o calculo para ser feito pelo servidor java via socket tcp
  const resultadoJavaTcp = await calcularCotasViaJavaTcp(dados.geracaoKwh, percentuais);
  const motorUtilizado = resultadoJavaTcp ? "Java Socket TCP (porta 5050)" : "Fallback Local Node.js";

  // faz a distribuicao dos creditos entre os membros 
  const distribuicao = await Promise.all(
    // mapeia os membros com as suas cotas
    // usando cota (cota com membro) como parametro
    cotas.map(async (cota) => {
      const percentual = paraNumero(cota.percentual);

      // calcula os creditos
      const creditosCalculados = resultadoJavaTcp && resultadoJavaTcp[percentual] !== undefined ? resultadoJavaTcp[percentual] : Number((dados.geracaoKwh * (percentual / 100)).toFixed(1));

      // salva ou atualiza no banco
      await salvarOuAtualzarCredito({
        usinaId,
        membroId: cota.membro_id!.toString(),
        mesReferencia: dados.mesReferencia,
        geracaoTotalKwh: dados.geracaoKwh,
        percentualCota: percentual,
        creditosLiquidosKwh: creditosCalculados,
      });

      // retorna os dados do map
      return {
        membro_id: cota.membro_id!.toString(),
        nome: cota.nome_membro,
        percentual,
        creditos_kwh: creditosCalculados,
      };
    }),
  );

  // retorna os dados do lançamento mensal 
  return {
    mensagem: "Dados lançados e créditos distribuídos com sucesso!",
    mes_referencia: dados.mesReferencia,
    geracao_total_kwh: dados.geracaoKwh,
    motor_calculo: motorUtilizado,
    membros_atualizados: distribuicao.length,
    distribuicao,
  };
}