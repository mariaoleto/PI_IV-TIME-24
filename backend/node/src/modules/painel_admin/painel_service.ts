//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// regras de negócio do painel administrativo
// agrega dados da usina, das cotas e do registro mensal (geração, créditos e consumo)
// mesmas regras e mesmo contrato JSON do backend Java (GET /admin/painel)

import {
  buscarUsina,
  buscarUsinaAtiva,
  buscarUsinaIdPelasCotas,
  Doc,
  listarConsumos,
  listarCotas,
  listarCreditos,
  listarGeracoes,
} from "./painel_repo";

// horas de sol pleno equivalentes por dia, usadas para estimar a geração esperada
// quando a usina só informa a capacidade instalada (kWp)
export const HORAS_SOL_DIA = 4;
// geração abaixo de 80% da média dos meses anteriores gera alerta de queda
export const LIMITE_QUEDA_GERACAO = 0.8;
export const TOLERANCIA_PERCENTUAL = 0.01;

const NOMES_MESES = [
  "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
  "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
];

export class UsinaNaoEncontrada extends Error {}

export type Alerta = {
  tipo: string;
  severidade: "erro" | "aviso" | "info";
  titulo: string;
  mensagem: string;
};

export type EntradaPainel = {
  usinaId: string;
  usina: Doc | null;
  cotas: Doc[];
  geracoes: Doc[];
  // carregam os dados que dependem do mês exibido
  buscarCreditos: (mes: string) => Promise<Doc[]>;
  buscarConsumos: (mes: string) => Promise<Doc[]>;
};

// ---------- utilitários ----------

function paraNumero(valor: unknown) {
  if (valor === null || valor === undefined || valor === "") return 0;
  const n = Number(valor);
  return Number.isFinite(n) ? n : 0;
}

function arredondar(valor: number, casas: number) {
  const f = 10 ** casas;
  return Math.round((valor + Number.EPSILON) * f) / f;
}

function formatarNumero(valor: number) {
  return Number.isInteger(valor) ? String(valor) : String(valor).replace(".", ",");
}

// "2026-10" -> índice absoluto de mês (ano*12 + mês-1); null se inválido
function lerMes(ref: unknown): number | null {
  const m = /^(\d{4})-(\d{2})$/.exec(String(ref ?? "").trim());
  if (!m) return null;
  const mes = Number(m[2]);
  return mes >= 1 && mes <= 12 ? Number(m[1]) * 12 + (mes - 1) : null;
}

function formatarMes(indice: number) {
  const ano = Math.floor(indice / 12);
  return `${ano}-${String((indice % 12) + 1).padStart(2, "0")}`;
}

function rotulo(indice: number) {
  return `${NOMES_MESES[indice % 12]}/${Math.floor(indice / 12)}`;
}

function diasNoMes(indice: number) {
  return new Date(Date.UTC(Math.floor(indice / 12), (indice % 12) + 1, 0)).getUTCDate();
}

// mês corrente no fuso de São Paulo
function mesDe(agora: Date) {
  const partes = new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Sao_Paulo",
    year: "numeric",
    month: "2-digit",
  }).formatToParts(agora);
  const ano = Number(partes.find((p) => p.type === "year")!.value);
  const mes = Number(partes.find((p) => p.type === "month")!.value);
  return ano * 12 + (mes - 1);
}

function lerConsumoKwh(c: Doc) {
  return paraNumero(c.consumo_kwh ?? c.consumo_total_kwh ?? c.total_consumo_kwh ?? c.kwh);
}

function mediaAnteriores(geracao: Map<number, number>, mesRef: number) {
  const valores = [...geracao.entries()]
    .filter(([m, v]) => m < mesRef && v > 0)
    .map(([, v]) => v);
  return valores.length === 0 ? 0 : valores.reduce((a, b) => a + b, 0) / valores.length;
}

// ---------- agregação (função pura + loaders injetados) ----------

export async function agregarPainel(entrada: EntradaPainel, agora: Date = new Date()) {
  const { usina, cotas } = entrada;
  const mesAtual = mesDe(agora);

  const geracaoPorMes = new Map<number, number>();
  for (const g of entrada.geracoes) {
    const m = lerMes(g.mes_referencia);
    if (m !== null) geracaoPorMes.set(m, paraNumero(g.geracao_kwh));
  }
  const mesesOrdenados = [...geracaoPorMes.keys()].sort((a, b) => a - b);

  // cotas
  const ativos = new Set<string>();
  let soma = 0;
  for (const c of cotas) {
    const p = paraNumero(c.percentual);
    if (p > 0 && c.membro_id) {
      ativos.add(String(c.membro_id));
      soma += p;
    }
  }
  const membros = {
    ativos: ativos.size,
    soma_percentual_cotas: arredondar(soma, 2),
    percentual_disponivel: arredondar(Math.max(0, 100 - soma), 2),
  };

  // mês exibido: o corrente, se já tiver registro; senão o último registrado
  const mesRef = geracaoPorMes.has(mesAtual)
    ? mesAtual
    : mesesOrdenados.length === 0
      ? mesAtual
      : mesesOrdenados[mesesOrdenados.length - 1];
  const registrado = geracaoPorMes.has(mesRef);
  const geracao = registrado ? geracaoPorMes.get(mesRef)! : 0;
  const anterior = geracaoPorMes.get(mesRef - 1);
  const variacao =
    registrado && anterior !== undefined && anterior > 0
      ? arredondar(((geracao - anterior) / anterior) * 100, 1)
      : null;

  let eficiencia: number | null = null;
  let base: string | null = null;
  if (registrado) {
    const esperadaInformada = paraNumero(usina?.geracao_esperada_kwh_mes);
    const capacidade = paraNumero(usina?.capacidade_kwp);
    const esperado =
      esperadaInformada > 0
        ? esperadaInformada
        : capacidade > 0
          ? capacidade * HORAS_SOL_DIA * diasNoMes(mesRef)
          : 0;
    if (esperado > 0) {
      eficiencia = arredondar((geracao / esperado) * 100, 1);
      base = "capacidade";
    } else {
      const media = mediaAnteriores(geracaoPorMes, mesRef);
      if (media > 0) {
        eficiencia = arredondar((geracao / media) * 100, 1);
        base = "historico";
      }
    }
  }
  const resumoMes = {
    mes_referencia: formatarMes(mesRef),
    rotulo: rotulo(mesRef),
    registrado,
    geracao_kwh: arredondar(geracao, 1),
    geracao_mes_anterior_kwh: anterior === undefined ? null : arredondar(anterior, 1),
    variacao_percentual: variacao,
    eficiencia_percentual: eficiencia,
    eficiencia_base: base,
  };

  // próximo lançamento: mês mais antigo sem registro entre o primeiro registro e o mês atual;
  // se tudo estiver em dia, o mês seguinte ao atual
  let proximo: {
    mes_referencia: string;
    rotulo: string;
    status: "atrasado" | "pendente" | "em_dia";
    meses_em_atraso: number;
    data_abertura: string | null;
  };
  if (mesesOrdenados.length === 0) {
    proximo = {
      mes_referencia: formatarMes(mesAtual),
      rotulo: rotulo(mesAtual),
      status: "pendente",
      meses_em_atraso: 0,
      data_abertura: null,
    };
  } else {
    let primeiroPendente: number | null = null;
    let emAtraso = 0;
    for (let m = mesesOrdenados[0]; m <= mesAtual; m++) {
      if (!geracaoPorMes.has(m)) {
        if (primeiroPendente === null) primeiroPendente = m;
        if (m < mesAtual) emAtraso++;
      }
    }
    if (primeiroPendente === null) {
      const prox = mesAtual + 1;
      proximo = {
        mes_referencia: formatarMes(prox),
        rotulo: rotulo(prox),
        status: "em_dia",
        meses_em_atraso: 0,
        data_abertura: `${formatarMes(prox)}-01`,
      };
    } else {
      proximo = {
        mes_referencia: formatarMes(primeiroPendente),
        rotulo: rotulo(primeiroPendente),
        status: primeiroPendente < mesAtual ? "atrasado" : "pendente",
        meses_em_atraso: emAtraso,
        data_abertura: null,
      };
    }
  }

  // alertas
  const alertas: Alerta[] = [];
  if (membros.ativos === 0) {
    alertas.push({
      tipo: "SEM_COTAS", severidade: "erro", titulo: "Nenhuma cota cadastrada",
      mensagem: "Cadastre as cotas dos membros para distribuir os créditos da usina.",
    });
  } else if (soma > 100 + TOLERANCIA_PERCENTUAL) {
    alertas.push({
      tipo: "COTAS_EXCEDIDAS", severidade: "erro", titulo: "Cotas acima de 100%",
      mensagem: `A soma das cotas é ${formatarNumero(membros.soma_percentual_cotas)}%. Ajuste as cotas para que não ultrapassem 100%.`,
    });
  } else if (soma < 100 - TOLERANCIA_PERCENTUAL) {
    alertas.push({
      tipo: "COTAS_INCOMPLETAS", severidade: "aviso", titulo: "Cotas abaixo de 100%",
      mensagem: `${formatarNumero(membros.percentual_disponivel)}% da usina ainda não foram distribuídos entre os membros.`,
    });
  }

  if (proximo.status === "atrasado") {
    const n = proximo.meses_em_atraso;
    alertas.push({
      tipo: "LANCAMENTO_ATRASADO", severidade: "aviso", titulo: "Lançamento em atraso",
      mensagem:
        n === 1
          ? `O registro de ${proximo.rotulo} ainda não foi lançado.`
          : `${n} meses sem registro de geração, a partir de ${proximo.rotulo}.`,
    });
  }

  if (registrado) {
    const media = mediaAnteriores(geracaoPorMes, mesRef);
    if (media > 0 && geracao < media * LIMITE_QUEDA_GERACAO) {
      const queda = arredondar((1 - geracao / media) * 100, 0);
      alertas.push({
        tipo: "QUEDA_GERACAO", severidade: "aviso", titulo: "Queda na geração",
        mensagem: `A geração de ${resumoMes.rotulo} está ${formatarNumero(queda)}% abaixo da média dos meses anteriores.`,
      });
    }

    const acima = await contarConsumoAcimaDosCreditos(entrada, resumoMes.mes_referencia, geracao);
    if (acima > 0) {
      alertas.push({
        tipo: "CONSUMO_ACIMA_CREDITOS", severidade: "aviso", titulo: "Consumo acima dos créditos",
        mensagem:
          acima === 1
            ? `1 membro consumiu mais do que os créditos de ${resumoMes.rotulo}.`
            : `${acima} membros consumiram mais do que os créditos de ${resumoMes.rotulo}.`,
      });
    }
  }

  const peso = { erro: 0, aviso: 1, info: 2 };
  alertas.sort((a, b) => peso[a.severidade] - peso[b.severidade]); // sort estável

  const capacidade = paraNumero(usina?.capacidade_kwp);
  return {
    usina: {
      id: entrada.usinaId,
      nome: usina?.nome ?? null,
      localizacao: usina?.localizacao ?? null,
      capacidade_kwp: capacidade > 0 ? capacidade : null,
      ativa: usina?.ativa !== false,
    },
    resumo_mes: resumoMes,
    membros,
    alertas,
    proximo_lancamento: proximo,
  };
}

// compara, por membro, o consumo do mês com os créditos recebidos
// (usa os créditos já distribuídos; se não houver, estima pela cota)
async function contarConsumoAcimaDosCreditos(entrada: EntradaPainel, mes: string, geracao: number) {
  const consumos = await entrada.buscarConsumos(mes);
  if (consumos.length === 0) return 0;

  const consumoPorMembro = new Map<string, number>();
  for (const c of consumos) {
    if (c.membro_id) {
      const id = String(c.membro_id);
      consumoPorMembro.set(id, (consumoPorMembro.get(id) ?? 0) + lerConsumoKwh(c));
    }
  }

  const creditoPorMembro = new Map<string, number>();
  for (const c of await entrada.buscarCreditos(mes)) {
    if (c.membro_id) {
      const id = String(c.membro_id);
      const valor = paraNumero(c.creditos_liquidos_kwh ?? c.creditos_brutos_kwh);
      creditoPorMembro.set(id, (creditoPorMembro.get(id) ?? 0) + valor);
    }
  }
  for (const cota of entrada.cotas) {
    if (cota.membro_id && !creditoPorMembro.has(String(cota.membro_id))) {
      creditoPorMembro.set(String(cota.membro_id), (geracao * paraNumero(cota.percentual)) / 100);
    }
  }

  let acima = 0;
  for (const [id, consumo] of consumoPorMembro) {
    if (consumo > (creditoPorMembro.get(id) ?? 0) + 0.05) acima++;
  }
  return acima;
}

// ---------- entrada pública ----------

// monta o painel da usina informada ou, se não informada, da primeira usina ativa
export async function montarPainelAdmin(usinaIdSolicitada?: string) {
  let usina: Doc | null;
  let usinaId: string | undefined;

  if (usinaIdSolicitada && usinaIdSolicitada.trim()) {
    usinaId = usinaIdSolicitada.trim();
    usina = await buscarUsina(usinaId);
  } else {
    usina = await buscarUsinaAtiva();
    usinaId = usina?._id?.toString() ?? (await buscarUsinaIdPelasCotas());
    if (!usinaId) throw new UsinaNaoEncontrada("Nenhuma usina cadastrada.");
  }

  const [cotas, geracoes] = await Promise.all([listarCotas(usinaId), listarGeracoes(usinaId)]);
  if (!usina && cotas.length === 0 && geracoes.length === 0) {
    throw new UsinaNaoEncontrada("Usina não encontrada.");
  }

  return agregarPainel({
    usinaId,
    usina,
    cotas,
    geracoes,
    buscarCreditos: (mes) => listarCreditos(usinaId!, mes),
    buscarConsumos: (mes) => listarConsumos(usinaId!, mes),
  });
}
