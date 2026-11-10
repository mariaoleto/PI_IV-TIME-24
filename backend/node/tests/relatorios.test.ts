import test from "node:test";
import assert from "node:assert/strict";
import { agruparConsumosPorMes } from "../src/modules/geracao_creditos/energia_service";
import { gerarPdfRelatorio } from "../src/modules/relatorios/relatorios_pdf";

test("agrega todos os registros de consumo de cada mês e aceita campos legados", () => {
  const consumos = agruparConsumosPorMes([
    { mes_referencia: "2026-01", consumo_kwh: 100 },
    { mes_referencia: "2026-01", consumo_total_kwh: "50" },
    { mes_referencia: "2026-02", kwh: 25 },
    { consumo_kwh: 10 },
  ]);
  assert.deepEqual([...consumos], [["2026-01", 150], ["2026-02", 25]]);
});

test("gera um PDF com resumo e detalhamento mensal", async () => {
  const arquivo = await gerarPdfRelatorio({
    titulo: "Relatório mensal de energia",
    referencia: "setembro de 2026",
    nome_membro: "Ana Membro",
    percentual_cota: 25,
    tarifa_kwh: 0.69,
    total_geracao_kwh: 1000,
    total_creditos_kwh: 250,
    total_consumo_kwh: 180,
    saldo_kwh: 70,
    economia_estimada_reais: 48.3,
    meses: [{
      mes_referencia: "2026-09",
      geracao_kwh: 1000,
      creditos_liquidos_kwh: 250,
      consumo_kwh: 180,
      saldo_mes_kwh: 70,
    }],
  });
  assert.equal(arquivo.subarray(0, 5).toString(), "%PDF-");
  assert.ok(arquivo.length > 500);
});
