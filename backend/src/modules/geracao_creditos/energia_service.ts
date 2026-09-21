// autora: Maria Julia Lazarini Oleto

// significado do arquivo:
// criacao das regras de negocio e calculos de geracao, consumo e créditos

import mongoose from "mongoose";
import {
  buscarConsumosMensais,
  buscarCotaMaisRecente,
  buscarCreditosMensais,
  buscarGeracoesMensais,
  DocumentoFlexivel,
} from "./energia_repo";

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
type ParametrosResumoEnergia = {
  ano?: string;
  usinaId?: string;
  membroId?: string;
};

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

  return paraNumero(
    consumo.consumo_kwh ??
      consumo.consumo_total_kwh ??
      consumo.total_consumo_kwh ??
      consumo.kwh,
  );
}

// monta e retorna o resumo dos dados da energia, conforme os parametros (ano, id usina e id membro)
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
    const consumoPorMes = new Map(
        consumos.map((item) => [item.mes_referencia?.toString(), item]),
    );
    // atribui os valores nas variaveis 
    const percentualCota = paraNumero(cota?.percentual);
    const tarifaKwh = paraNumero(cota?.tarifa_kwh);
    let totalGeracaoKwh = 0;
    let saldoAcumuladoKwh = 0;
    // cria e retorna o map do resumo dos dados da energia 
    const meses = rotulosMeses.map((rotulo, indice) => {
        const referencia = chaveMes(ano, indice);
        const geracao = geracaoPorMes.get(referencia);
        const credito = creditoPorMes.get(referencia);
        const consumo = consumoPorMes.get(referencia);
        const geracaoKwh = paraNumero(geracao?.geracao_kwh);
        // calculo do credito do usuario 
        const creditoCalculado =
        percentualCota > 0 ? geracaoKwh * (percentualCota / 100) : 0;
        const creditosLiquidosKwh = paraNumero(
        credito?.creditos_liquidos_kwh,
        paraNumero(credito?.creditos_brutos_kwh, creditoCalculado),
        );
        const consumoKwh = lerConsumoKwh(consumo);
        const saldoMesKwh = creditosLiquidosKwh - consumoKwh;

        totalGeracaoKwh += geracaoKwh;
        saldoAcumuladoKwh += saldoMesKwh;

        return {
        mes: rotulo,
        mes_referencia: referencia,
        geracao_kwh: geracaoKwh,
        // toFixed() - retorna uma string de um numero com casa decimal
        creditos_liquidos_kwh: Number(creditosLiquidosKwh.toFixed(1)),
        consumo_kwh: consumoKwh,
        saldo_mes_kwh: Number(saldoMesKwh.toFixed(1)),
        };
    });

    // retorna os dados 
    return {
        ano,
        usina_id: usinaId,
        membro_id: membroId,
        percentual_cota: percentualCota,
        tarifa_kwh: tarifaKwh,
        total_geracao_kwh: Number(totalGeracaoKwh.toFixed(1)),
        saldo_acumulado_kwh: Number(saldoAcumuladoKwh.toFixed(1)),
        economia_estimada_reais: Number((saldoAcumuladoKwh * tarifaKwh).toFixed(2)),
        meses,
    };
}