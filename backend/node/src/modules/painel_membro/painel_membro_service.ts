// autora: Maria Júlia Lazarini Oleto
// RA: 25006031

// significado do arquivo:
// regras de negócio e calculos 
// para o painel administrativo do membro (dashboard)

// nesse arquivo, se tem a criacao de dados mock
// caso nao tenha dados no banco referente ao mes, se utiliza:
// primeiro os dados de meses previos do banco (geracao, consumo, creditos etc.),
// se nao tiver, utiliza dados mockados para gerar os graficos e tabelas

import {
  buscarConsumosDoMembro,
  buscarCotaDoMembro,
  buscarCreditosDoMembro,
  buscarGeracoesDoAno,
  buscarMembroPorIdOuPrimeiro,
  DocumentoFlexivel,
} from "./painel_membro_repo";

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

const nomesMesesExtenso = [
  "janeiro",
  "fevereiro",
  "março",
  "abril",
  "maio",
  "junho",
  "julho",
  "agosto",
  "setembro",
  "outubro",
  "novembro",
  "dezembro",
];

// tipos dos dados que vao ser usados em elementos do painel 

export type ParametrosDashboard = {
  ano?: string;
  usinaId?: string;
  membroId?: string;
  email?: string;
};

export type ItemGeracaoMensal = {
  mes: string;
  mes_referencia: string;
  valor_kwh: number;
  mes_atual: boolean;
};

export type ItemLancamentoHistorico = {
  mes_rotulo: string;
  mes_referencia: string;
  gerado_kwh: number;
  consumo_kwh: number;
  credito_kwh: number;
  positivo: boolean;
};

export type RespostaDashboardMembro = {
  membro: {
    id?: string;
    nome: string;
    inicial: string;
    cota_percentual: number;
    saudacao: string;
  };
  resumo_mes: {
    mes_referencia: string;
    creditos_disponiveis_kwh: number;
    percentual_utilizado: number;
    gerado_mes_kwh: number;
    consumido_mes_kwh: number;
  };
  metricas: {
    co2_evitado_kg: number;
    economia_reais: number;
    mes_economia: string;
    media_diaria_kwh: number;
    pico_consumo_kwh: number;
    pico_consumo_data: string;
  };
  geracao_mensal: ItemGeracaoMensal[];
  ultimos_lancamentos: ItemLancamentoHistorico[];
};

// converte um valor para numero 
function paraNumero(valor: unknown, padrao = 0): number {
  const numero = Number(valor);
  return Number.isFinite(numero) ? numero : padrao;
}

// saudacao personalizada baseada na hora (bom dia, boa tarde e boa noite)
function obterSaudacao(): string {
  const hora = new Date().getHours();
  if (hora >= 5 && hora < 12) return "Bom dia,";
  if (hora >= 12 && hora < 18) return "Boa tarde,";
  return "Boa noite,";
}

// funcao que busca os dados do dashboard
export async function obterDashboardMembro(
  parametros: ParametrosDashboard,
): Promise<RespostaDashboardMembro> {
  const ano = paraNumero(parametros.ano, 2026);
  const membroId = parametros.membroId;
  const usinaId = parametros.usinaId;

  // busca membro (por id ou email fornecido, ou o mais recente cadastrado)
  const membroDoc = await buscarMembroPorIdOuPrimeiro(membroId, parametros.email);
  const idMembroEncontrado = membroDoc?._id?.toString() || membroId;
  const nomeMembro = (membroDoc?.nome as string)?.trim() || "João Oliveira";
  const inicialMembro = nomeMembro.charAt(0).toUpperCase() || "J";

  // busca cota associada
  const idUsinaDoMembro = membroDoc?.usina_id?.toString() || usinaId;
  const cotaDoc = await buscarCotaDoMembro(idMembroEncontrado, idUsinaDoMembro);
  const cotaPercentual = paraNumero(cotaDoc?.percentual, 25);
  const tarifaKwh = paraNumero(cotaDoc?.tarifa_kwh, 0.69);
  const idUsina = idUsinaDoMembro || cotaDoc?.usina_id?.toString();

  // busca geracoes, creditos e consumos 
  const [geracoesBanco, creditosBanco, consumosBanco] = await Promise.all([
    buscarGeracoesDoAno(idUsina, ano),
    buscarCreditosDoMembro(idMembroEncontrado, idUsina, ano),
    buscarConsumosDoMembro(idMembroEncontrado, idUsina, ano),
  ]);

  // mapeia geracoes, creditos e consumos por mes de referencia 
  const mapaGeracao = new Map<string, DocumentoFlexivel>(
    geracoesBanco.map((g) => [g.mes_referencia?.toString() || "", g]),
  );
  const mapaCredito = new Map<string, DocumentoFlexivel>(
    creditosBanco.map((c) => [c.mes_referencia?.toString() || "", c]),
  );
  const mapaConsumo = new Map<string, DocumentoFlexivel>(
    consumosBanco.map((c) => [c.mes_referencia?.toString() || "", c]),
  );

  // valores padrao/mock para os meses (caso o banco esteja vazio ou parcial)
  const geracaoPadraoMock = [284, 312, 298, 340, 287, 310, 295, 325, 310];
  const consumoPadraoMock = [210, 225, 198, 245, 192, 218, 280, 210, 223];

  const temConsumoBanco = consumosBanco.length > 0;
  const temCreditoBanco = creditosBanco.length > 0;
  const temGeracaoBanco = geracoesBanco.length > 0;

  let ultimoMesNoBanco = 9;
  for (const registro of [...geracoesBanco, ...creditosBanco, ...consumosBanco]) {
    const ref = registro.mes_referencia?.toString() || "";
    const match = new RegExp(`^${ano}-(\\d{2})$`).exec(ref);
    if (match) {
      const mesNum = Number(match[1]);
      if (mesNum >= 1 && mesNum <= 12 && mesNum > ultimoMesNoBanco) {
        ultimoMesNoBanco = mesNum;
      }
    }
  }

  // indice do mes de referencia (setembro por padrão, ou último mês com dado real)
  const indiceMesAtual = Math.max(8, ultimoMesNoBanco - 1);
  const rotuloMesAtual = rotulosMeses[indiceMesAtual];

  // valores iniciais 
  let saldoAcumulado = 0;
  const listaGeracaoMensal: ItemGeracaoMensal[] = [];
  const listaTodosLancamentos: ItemLancamentoHistorico[] = [];

  // constroi os meses ate o mês de referência atual
  for (let i = 0; i <= indiceMesAtual; i++) {

    // cria uma chave para o mes de referencia
    const rotulo = rotulosMeses[i];
    const chave = `${ano}-${String(i + 1).padStart(2, "0")}`;

    // busca os dados 
    const docGeracao = mapaGeracao.get(chave);
    const docCredito = mapaCredito.get(chave);
    const docConsumo = mapaConsumo.get(chave);

    // converte a geracao mensal
    // caso nao tenha no banco um dado do mes, utiliza um do mock
    let geracaoKwh = paraNumero(docGeracao?.geracao_kwh);
    if (!docGeracao && !temGeracaoBanco && i < geracaoPadraoMock.length) {
      geracaoKwh = geracaoPadraoMock[i];
    }

    // calcula o credito
    let creditoMesKwh = paraNumero(
      docCredito?.creditos_liquidos_kwh,
      paraNumero(docCredito?.creditos_brutos_kwh),
    );
    if (!docCredito && geracaoKwh > 0) {
      creditoMesKwh = Math.round(geracaoKwh * (cotaPercentual / 100));
    }

    // calcula o consumo do membro
    // caso nao tenha nenhum consumo real salvo ainda, utiliza o mock de demonstração
    let consumoKwh = docConsumo
      ? paraNumero(
          docConsumo.consumo_kwh ??
            docConsumo.consumo_total_kwh ??
            docConsumo.total_consumo_kwh,
        )
      : 0;
    if (!docConsumo && !temConsumoBanco && i < consumoPadraoMock.length) {
      consumoKwh = consumoPadraoMock[i];
    }

    // calcula o saldo mensal e acumulado
    const saldoMes = creditoMesKwh - consumoKwh;
    saldoAcumulado += saldoMes;

    // lista que sera usada no grafico de barras
    listaGeracaoMensal.push({
      mes: rotulo,
      mes_referencia: chave,
      valor_kwh: creditoMesKwh,
      mes_atual: i === indiceMesAtual,
    });

    const usarMockLancamentoAtual =
      !temCreditoBanco && !temConsumoBanco && !temGeracaoBanco && i === indiceMesAtual;

    // lista que sera usada no historico de lancamento
    listaTodosLancamentos.push({
      mes_rotulo: `${rotulo}/${ano}`,
      mes_referencia: chave,
      gerado_kwh: creditoMesKwh,
      consumo_kwh: consumoKwh,
      credito_kwh: usarMockLancamentoAtual ? 287 : Math.round(saldoMes),
      positivo: (usarMockLancamentoAtual ? 287 : saldoMes) >= 0,
    });
  }

  // dados do mes
  const itemMesAtual = listaGeracaoMensal[indiceMesAtual];
  const geradoMesAtual = itemMesAtual?.valor_kwh ?? 0;
  const consumidoMesAtual =
    listaTodosLancamentos[indiceMesAtual]?.consumo_kwh ??
    (!temConsumoBanco ? 223 : 0);

  // percentual utilizado
  const percentualUtilizado =
    geradoMesAtual > 0
      ? Math.min(100, Math.round((consumidoMesAtual / geradoMesAtual) * 100))
      : 0;

  // creditos disponiveis
  const creditosDisponiveis =
    temCreditoBanco || temConsumoBanco || temGeracaoBanco
      ? Math.max(0, Math.round(saldoAcumulado))
      : saldoAcumulado > 0
        ? Math.round(saldoAcumulado)
        : 287;

  // co2 evitado
  const co2Evitado = Math.round(geradoMesAtual * 0.41);

  // economia em reais 
  const consumoAnterior = listaTodosLancamentos[indiceMesAtual - 1]?.consumo_kwh ?? 0;
  const consumoParaEconomia =
    consumidoMesAtual > 0 ? consumidoMesAtual : consumoAnterior;
  const economiaEstimada =
    temConsumoBanco || temCreditoBanco || temGeracaoBanco
      ? Math.round(consumoParaEconomia * tarifaKwh)
      : Math.round(consumoAnterior * tarifaKwh) || 186;

  const temDadosNoBanco = temCreditoBanco || temConsumoBanco || temGeracaoBanco;

  // media de consumo 
  const mediaDiaria =
    temDadosNoBanco
      ? Number((consumidoMesAtual / 23).toFixed(1))
      : Number((consumidoMesAtual / 23).toFixed(1)) || 9.7;

  // pico de consumo
  const picoConsumo =
    temDadosNoBanco
      ? Number(((consumidoMesAtual / 30) * 1.91).toFixed(1))
      : Number(((consumidoMesAtual / 30) * 1.91).toFixed(1)) || 14.2;
  const picoData = "13 set";

  // inverte a lista de lancamentos 
  // mostra os mais recentes 
  const ultimosLancamentos = [...listaTodosLancamentos]
    .reverse()
    .slice(0, 4);

  // ajuste dos dados somente quando toda a base ainda está sem lançamentos reais
  if (ultimosLancamentos.length >= 4 && !temDadosNoBanco) {
    ultimosLancamentos[0].credito_kwh = 287;
    ultimosLancamentos[0].positivo = true;

    ultimosLancamentos[1].credito_kwh = 85;
    ultimosLancamentos[1].positivo = true;

    ultimosLancamentos[2].credito_kwh = 45;
    ultimosLancamentos[2].positivo = true;

    ultimosLancamentos[3].credito_kwh = -92;
    ultimosLancamentos[3].positivo = false;
  }

  return {
    membro: {
      id: idMembroEncontrado,
      nome: nomeMembro,
      inicial: inicialMembro,
      cota_percentual: cotaPercentual,
      saudacao: obterSaudacao(),
    },
    resumo_mes: {
      mes_referencia: `${rotuloMesAtual}/${ano}`,
      creditos_disponiveis_kwh: creditosDisponiveis,
      percentual_utilizado: percentualUtilizado,
      gerado_mes_kwh: geradoMesAtual,
      consumido_mes_kwh: consumidoMesAtual,
    },
    metricas: {
      co2_evitado_kg: co2Evitado,
      economia_reais: economiaEstimada,
      mes_economia: nomesMesesExtenso[indiceMesAtual - 1] || "agosto",
      media_diaria_kwh: mediaDiaria,
      pico_consumo_kwh: picoConsumo,
      pico_consumo_data: picoData,
    },
    geracao_mensal: listaGeracaoMensal,
    ultimos_lancamentos: ultimosLancamentos,
  };
}
