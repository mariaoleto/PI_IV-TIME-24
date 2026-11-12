//Autora: Ana Luísa Maso Mafra | RA: 25007997

// testes do agregador do painel admin (rodar com: npm test)
import test from "node:test";
import assert from "node:assert/strict";
import { agregarPainel, EntradaPainel } from "../src/modules/painel_admin/painel_service";

const AGORA = new Date("2026-10-26T15:00:00Z"); // 26/10/2026 em São Paulo
const M1 = "507f1f77bcf86cd799439021";
const M2 = "507f1f77bcf86cd799439022";
const M3 = "507f1f77bcf86cd799439023";

const cota = (membro: string, percentual: number) => ({ membro_id: membro, percentual });
const geracao = (mes: string, kwh: number) => ({ mes_referencia: mes, geracao_kwh: kwh });

function entrada(parcial: Partial<EntradaPainel>): EntradaPainel {
  return {
    usinaId: "507f1f77bcf86cd799439011",
    usina: { nome: "Usina Solis", localizacao: "Campinas - SP" },
    cotas: [cota(M1, 100)],
    geracoes: [],
    buscarCreditos: async () => [],
    buscarConsumos: async () => [],
    ...parcial,
  };
}
const tem = (p: { alertas: { tipo: string }[] }, tipo: string) => p.alertas.some((a) => a.tipo === tipo);

test("agrega usina, cotas e registro mensal em dia", async () => {
  const p = await agregarPainel(
    entrada({
      usina: { nome: "Usina Solis", capacidade_kwp: 100 },
      cotas: [cota(M1, 50), cota(M2, 30), cota(M3, 20)],
      geracoes: [geracao("2026-08", 9000), geracao("2026-09", 10000), geracao("2026-10", 11160)],
    }),
    AGORA,
  );
  assert.equal(p.usina.nome, "Usina Solis");
  assert.equal(p.usina.capacidade_kwp, 100);
  assert.equal(p.resumo_mes.mes_referencia, "2026-10");
  assert.equal(p.resumo_mes.rotulo, "Outubro/2026");
  assert.equal(p.resumo_mes.geracao_kwh, 11160);
  assert.equal(p.resumo_mes.variacao_percentual, 11.6);
  assert.equal(p.resumo_mes.eficiencia_percentual, 90); // 11160 / (100*4*31)
  assert.equal(p.resumo_mes.eficiencia_base, "capacidade");
  assert.equal(p.membros.ativos, 3);
  assert.equal(p.membros.soma_percentual_cotas, 100);
  assert.deepEqual(p.alertas, []);
  assert.equal(p.proximo_lancamento.mes_referencia, "2026-11");
  assert.equal(p.proximo_lancamento.status, "em_dia");
  assert.equal(p.proximo_lancamento.data_abertura, "2026-11-01");
});

test("eficiência usa histórico sem capacidade e não inventa sem base", async () => {
  const h = await agregarPainel(
    entrada({ geracoes: [geracao("2026-08", 1000), geracao("2026-09", 1000), geracao("2026-10", 900)] }),
    AGORA,
  );
  assert.equal(h.resumo_mes.eficiencia_percentual, 90);
  assert.equal(h.resumo_mes.eficiencia_base, "historico");

  const s = await agregarPainel(entrada({ geracoes: [geracao("2026-10", 900)] }), AGORA);
  assert.equal(s.resumo_mes.eficiencia_percentual, null);
  assert.equal(s.resumo_mes.variacao_percentual, null);
});

test("lançamento atrasado e lacuna no meio do período", async () => {
  const a = await agregarPainel(
    entrada({ geracoes: [geracao("2026-07", 1000), geracao("2026-08", 1000)] }),
    AGORA,
  );
  assert.equal(a.resumo_mes.mes_referencia, "2026-08");
  assert.equal(a.proximo_lancamento.mes_referencia, "2026-09");
  assert.equal(a.proximo_lancamento.status, "atrasado");
  assert.equal(a.proximo_lancamento.meses_em_atraso, 1);
  assert.ok(tem(a, "LANCAMENTO_ATRASADO"));

  const l = await agregarPainel(
    entrada({ geracoes: [geracao("2026-07", 1000), geracao("2026-09", 1000), geracao("2026-10", 1000)] }),
    AGORA,
  );
  assert.equal(l.proximo_lancamento.mes_referencia, "2026-08");
  assert.equal(l.proximo_lancamento.status, "atrasado");
});

test("sem registros o mês corrente fica pendente", async () => {
  const p = await agregarPainel(entrada({}), AGORA);
  assert.equal(p.resumo_mes.registrado, false);
  assert.equal(p.proximo_lancamento.mes_referencia, "2026-10");
  assert.equal(p.proximo_lancamento.status, "pendente");
});

test("alertas de cotas", async () => {
  const g = [geracao("2026-10", 1000)];
  const inc = await agregarPainel(entrada({ cotas: [cota(M1, 60), cota(M2, 25)], geracoes: g }), AGORA);
  assert.ok(tem(inc, "COTAS_INCOMPLETAS"));
  assert.equal(inc.membros.percentual_disponivel, 15);

  const exc = await agregarPainel(entrada({ cotas: [cota(M1, 70), cota(M2, 50)], geracoes: g }), AGORA);
  assert.ok(tem(exc, "COTAS_EXCEDIDAS"));
  assert.equal(exc.alertas[0].severidade, "erro");

  const sem = await agregarPainel(entrada({ cotas: [], geracoes: g }), AGORA);
  assert.ok(tem(sem, "SEM_COTAS"));
});

test("queda de geração", async () => {
  const p = await agregarPainel(
    entrada({ geracoes: [geracao("2026-08", 1000), geracao("2026-09", 1000), geracao("2026-10", 700)] }),
    AGORA,
  );
  assert.ok(tem(p, "QUEDA_GERACAO"));
  assert.ok(p.alertas.some((a) => a.mensagem.includes("30%")));
});

test("consumo acima dos créditos (estimado pela cota e pelo crédito distribuído)", async () => {
  const p = await agregarPainel(
    entrada({
      cotas: [cota(M1, 50), cota(M2, 50)],
      geracoes: [geracao("2026-10", 1000)],
      buscarConsumos: async () => [
        { membro_id: M1, consumo_kwh: 600 },
        { membro_id: M2, consumo_total_kwh: "100" },
      ],
    }),
    AGORA,
  );
  assert.ok(tem(p, "CONSUMO_ACIMA_CREDITOS"));
  assert.ok(p.alertas.some((a) => a.mensagem.startsWith("1 membro ")));

  const q = await agregarPainel(
    entrada({
      cotas: [cota(M1, 50)],
      geracoes: [geracao("2026-10", 1000)],
      buscarCreditos: async () => [{ membro_id: M1, creditos_liquidos_kwh: 700 }],
      buscarConsumos: async () => [{ membro_id: M1, consumo_kwh: 600 }],
    }),
    AGORA,
  );
  assert.ok(!tem(q, "CONSUMO_ACIMA_CREDITOS"));
});

test("lê usina pré-definida com potencia_instalada_kwp e localizacao composta", async () => {
  const p = await agregarPainel(
    entrada({
      usina: {
        nome: "Consórcio Solis",
        potencia_instalada_kwp: 100,
        localizacao: { cidade: "Campinas", estado: "SP" },
      },
      geracoes: [geracao("2026-10", 11160)],
    }),
    AGORA,
  );
  assert.equal(p.usina.capacidade_kwp, 100);
  assert.equal(p.usina.localizacao, "Campinas - SP");
  assert.equal(p.resumo_mes.eficiencia_percentual, 90);
});
