import test from "node:test";
import assert from "node:assert/strict";
import {
  consultarTelemetriaUsinaTcp,
  interpretarTelemetriaUsina,
  montarResumoEnergia,
  registrarConsumoMensal,
} from "../src/modules/geracao_creditos/energia_service";

const USINA_ID = "507f1f77bcf86cd799439011";
const MEMBRO_ID = "507f1f77bcf86cd799439022";

test("interpretarTelemetriaUsina interpreta resposta OK do servidor TCP Java", () => {
  const telemetria = interpretarTelemetriaUsina(
    "OK USINA=Solis_1 STATUS=OPERANDO GERACAO_ATUAL=14.2kW TENSAO=220V FREQ=60Hz",
  );

  assert.equal(telemetria.status_servidor_tcp, "online");
  assert.equal(telemetria.usina, "Solis_1");
  assert.equal(telemetria.status_operacao, "OPERANDO");
  assert.equal(telemetria.geracao_atual, "14.2kW");
  assert.equal(telemetria.tensao, "220V");
  assert.equal(telemetria.frequencia, "60Hz");
});

test("consultarTelemetriaUsinaTcp retorna offline quando o servidor TCP falha", async () => {
  const telemetria = await consultarTelemetriaUsinaTcp(async () => {
    throw new Error("Servidor TCP Java não está ativo na porta 5050");
  });

  assert.equal(telemetria.status_servidor_tcp, "offline");
  assert.match(telemetria.mensagem_erro ?? "", /5050/);
});

test("montarResumoEnergia resolve membro por email e inclui seu consumo sem misturar outra cota", async () => {
  let cotaBuscadaParaMembro: string | undefined;

  const resumo = await montarResumoEnergia({
    ano: "2026",
    email: "juliana@solis.com",
    deps: {
      buscarMembro: async ({ email }) => {
        assert.equal(email, "juliana@solis.com");
        return { _id: MEMBRO_ID, nome: "Juliana", usina_id: USINA_ID };
      },
      buscarCota: async ({ membroId }) => {
        cotaBuscadaParaMembro = membroId;
        return null;
      },
      buscarUsinaFallback: async () => null,
      buscarGeracoes: async () => [{ mes_referencia: "2026-10", geracao_kwh: 120 }],
      buscarCreditos: async () => [
        { mes_referencia: "2026-10", creditos_liquidos_kwh: 24 },
      ],
      buscarConsumos: async () => [
        { mes_referencia: "2026-10", consumo_kwh: 18 },
      ],
    },
  });

  assert.equal(cotaBuscadaParaMembro, MEMBRO_ID);
  assert.equal(resumo.membro_id, MEMBRO_ID);
  assert.equal(resumo.usina_id, USINA_ID);
  assert.equal(resumo.percentual_cota, 0);
  assert.equal(resumo.total_consumo_kwh, 18);
  assert.equal(resumo.saldo_acumulado_kwh, 6);
  const out = resumo.meses.find((m) => m.mes_referencia === "2026-10");
  assert.equal(out?.consumo_kwh, 18);
  assert.equal(out?.saldo_mes_kwh, 6);
});

test("registrarConsumoMensal valida parâmetros e persiste consumo do membro", async () => {
  await assert.rejects(
    () =>
      registrarConsumoMensal({
        mesReferencia: "10/2026",
        consumoKwh: 150,
        membroId: MEMBRO_ID,
      }),
    /AAAA-MM/,
  );

  await assert.rejects(
    () =>
      registrarConsumoMensal({
        mesReferencia: "2026-10",
        consumoKwh: -5,
        membroId: MEMBRO_ID,
      }),
    /maior ou igual a zero/,
  );

  let salvo: Record<string, unknown> | undefined;
  const resposta = await registrarConsumoMensal(
    {
      mesReferencia: "2026-10",
      consumoKwh: 185.5,
      email: "juliana@solis.com",
    },
    {
      buscarMembro: async () => ({ _id: MEMBRO_ID, usina_id: USINA_ID }),
      buscarCota: async () => ({
        usina_id: USINA_ID,
        membro_id: MEMBRO_ID,
        tarifa_kwh: 0.7,
      }),
      buscarUsinaFallback: async () => null,
      salvarConsumo: async (dados) => {
        salvo = dados;
        return dados;
      },
    },
  );

  assert.equal(resposta.membro_id, MEMBRO_ID);
  assert.equal(resposta.usina_id, USINA_ID);
  assert.equal(resposta.mes_referencia, "2026-10");
  assert.equal(resposta.consumo_kwh, 185.5);
  assert.equal(resposta.economia_estimada_reais, 129.85);
  assert.deepEqual(salvo, {
    usinaId: USINA_ID,
    membroId: MEMBRO_ID,
    mesReferencia: "2026-10",
    consumoKwh: 185.5,
    economiaEstimadaReais: 129.85,
  });
});

