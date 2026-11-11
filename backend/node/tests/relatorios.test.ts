import test from "node:test";
import assert from "node:assert/strict";
import { agruparConsumosPorMes } from "../src/modules/geracao_creditos/energia_service";
import { gerarPdfRelatorio } from "../src/modules/relatorios/relatorios_pdf";
import {
  gerarTicketDownloadRelatorio,
  obterDadosPdf,
  validarTicketDownloadRelatorio,
} from "../src/modules/relatorios/relatorios_service";
import { baixarRelatorio } from "../src/modules/relatorios/relatorios_controller";

process.env.JWT_SECRET = process.env.JWT_SECRET || "segredo-de-teste-com-mais-de-16-caracteres";

test("agrega todos os registros de consumo de cada mês e aceita campos legados", () => {
  const consumos = agruparConsumosPorMes([
    { mes_referencia: "2026-01", consumo_kwh: 100 },
    { mes_referencia: "2026-01", consumo_total_kwh: "50" },
    { mes_referencia: "2026-02", kwh: 25 },
    { consumo_kwh: 10 },
  ]);
  assert.deepEqual([...consumos], [["2026-01", 150], ["2026-02", 25]]);
});

test("gera um PDF com resumo, telemetria TCP e detalhamento mensal", async () => {
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
    origem_dados_tcp: "Java Socket TCP (porta 5050)",
    telemetria_tcp: {
      status_servidor: "online",
      usina: "Solis_1",
      status_operacao: "OPERANDO",
      geracao_atual: "14.2kW",
      tensao: "220V",
      frequencia: "60Hz",
    },
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

test("obterDadosPdf obtém telemetria (STATUS_USINA) e créditos (CALCULAR_COTAS) do servidor TCP", async () => {
  const comandos: string[] = [];
  const dados = await obterDadosPdf(
    "507f1f77bcf86cd799439011",
    "relatorio_mensal",
    "2026-09",
    {
      buscarMembroPorId: async () => ({ nome: "Maria Solis", usina_id: "507f1f77bcf86cd799439099" }),
      montarResumo: async () => ({
        ano: 2026,
        usina_id: "507f1f77bcf86cd799439099",
        membro_id: "507f1f77bcf86cd799439011",
        percentual_cota: 25,
        tarifa_kwh: 0.7,
        total_geracao_kwh: 1200,
        total_consumo_kwh: 200,
        saldo_acumulado_kwh: 0,
        economia_estimada_reais: 0,
        meses: [{
          mes: "Set",
          mes_referencia: "2026-09",
          geracao_kwh: 1200,
          creditos_liquidos_kwh: 0,
          consumo_kwh: 200,
          saldo_mes_kwh: -200,
        }],
      }),
      enviarTcp: async (comando) => {
        comandos.push(comando);
        if (comando === "STATUS_USINA") {
          return "OK USINA=Solis_1 STATUS=OPERANDO GERACAO_ATUAL=14.2kW TENSAO=220V FREQ=60Hz";
        }
        if (comando.startsWith("CALCULAR_COTAS")) {
          return "OK 25.0%=300.0kWh";
        }
        return "ERROR";
      },
    },
  );

  assert.deepEqual(comandos, [
    "STATUS_USINA",
    "CALCULAR_COTAS total=1200;cotas=25",
  ]);
  assert.equal(dados.origem_dados_tcp, "Java Socket TCP (porta 5050)");
  assert.equal(dados.telemetria_tcp?.status_servidor, "online");
  assert.equal(dados.telemetria_tcp?.geracao_atual, "14.2kW");
  assert.equal(dados.total_creditos_kwh, 300);
  assert.equal(dados.saldo_kwh, 100);
  assert.equal(dados.economia_estimada_reais, 70);
});

test("obterDadosPdf usa fallback seguro quando o servidor TCP Java está offline", async () => {
  const dados = await obterDadosPdf(
    "507f1f77bcf86cd799439011",
    "relatorio_mensal",
    "2026-09",
    {
      buscarMembroPorId: async () => ({ nome: "Maria Solis", usina_id: "507f1f77bcf86cd799439099" }),
      montarResumo: async () => ({
        ano: 2026,
        usina_id: "507f1f77bcf86cd799439099",
        membro_id: "507f1f77bcf86cd799439011",
        percentual_cota: 25,
        tarifa_kwh: 0.8,
        total_geracao_kwh: 1000,
        total_consumo_kwh: 150,
        saldo_acumulado_kwh: 100,
        economia_estimada_reais: 80,
        meses: [{
          mes: "Set",
          mes_referencia: "2026-09",
          geracao_kwh: 1000,
          creditos_liquidos_kwh: 250,
          consumo_kwh: 150,
          saldo_mes_kwh: 100,
        }],
      }),
      enviarTcp: async () => {
        throw new Error("Servidor TCP Java não está ativo na porta 5050");
      },
    },
  );

  assert.equal(dados.telemetria_tcp?.status_servidor, "offline");
  assert.match(dados.origem_dados_tcp ?? "", /Fallback/i);
  assert.equal(dados.total_creditos_kwh, 250);
  assert.equal(dados.saldo_kwh, 100);
});

test("ticket temporário de download valida membro, relatório, expiração e assinatura", () => {
  const membroId = "507f1f77bcf86cd799439011";
  const relatorioId = "507f1f77bcf86cd799439022";
  const agora = 1_700_000_000_000;
  const ticket = gerarTicketDownloadRelatorio(membroId, relatorioId, 120, agora);

  assert.equal(validarTicketDownloadRelatorio(ticket, relatorioId, agora + 30_000), membroId);
  assert.equal(validarTicketDownloadRelatorio(ticket, "507f1f77bcf86cd799439033", agora + 30_000), null);
  assert.equal(validarTicketDownloadRelatorio(ticket, relatorioId, agora + 121_000), null);
  assert.equal(validarTicketDownloadRelatorio(`${ticket.slice(0, -1)}x`, relatorioId, agora + 10_000), null);
});

test("baixarRelatorio bloqueia requisição sem Bearer token e sem ticket válido (401)", async () => {
  let statusResposta = 0;
  let corpoResposta: unknown = null;
  const req = {
    params: { id: "507f1f77bcf86cd799439022" },
    headers: {},
    query: {},
  } as any;
  const res = {
    status(code: number) {
      statusResposta = code;
      return this;
    },
    json(body: unknown) {
      corpoResposta = body;
      return this;
    },
  } as any;

  await baixarRelatorio(req, res, () => {});
  assert.equal(statusResposta, 401);
  assert.deepEqual(corpoResposta, { mensagem: "Sessão inválida ou expirada. Entre novamente." });
});
