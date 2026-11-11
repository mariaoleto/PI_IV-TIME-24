import PDFDocument from "pdfkit";

export type LinhaRelatorio = {
  mes_referencia: string;
  geracao_kwh: number;
  creditos_liquidos_kwh: number;
  consumo_kwh: number;
  saldo_mes_kwh: number;
};

export type TelemetriaPdf = {
  status_servidor: "online" | "offline";
  usina?: string;
  status_operacao?: string;
  geracao_atual?: string;
  tensao?: string;
  frequencia?: string;
  bruta?: string;
  mensagem_erro?: string;
};

export type DadosRelatorioPdf = {
  titulo: string;
  referencia: string;
  nome_membro: string;
  percentual_cota: number;
  tarifa_kwh: number;
  total_geracao_kwh: number;
  total_creditos_kwh: number;
  total_consumo_kwh: number;
  saldo_kwh: number;
  economia_estimada_reais: number;
  origem_dados_tcp?: string;
  telemetria_tcp?: TelemetriaPdf;
  meses: LinhaRelatorio[];
};

const numero = (valor: number, casas = 1) =>
  new Intl.NumberFormat("pt-BR", {
    minimumFractionDigits: casas,
    maximumFractionDigits: casas,
  }).format(valor);

export function gerarPdfRelatorio(dados: DadosRelatorioPdf): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const documento = new PDFDocument({ size: "A4", margin: 48 });
    const partes: Buffer[] = [];

    documento.on("data", (parte: Buffer) => partes.push(parte));
    documento.on("error", reject);
    documento.on("end", () => resolve(Buffer.concat(partes)));

    documento.fontSize(20).font("Helvetica-Bold").text("Solis", { continued: true });
    documento.fontSize(14).font("Helvetica").text(`  |  ${dados.titulo}`);
    documento.moveDown(0.5);
    documento.fontSize(10).text(`Membro: ${dados.nome_membro}`);
    documento.text(`Referência: ${dados.referencia}`);
    documento.text(`Cota: ${numero(dados.percentual_cota, 2)}%  |  Tarifa: R$ ${numero(dados.tarifa_kwh, 2)}/kWh`);
    documento.moveDown();

    documento.font("Helvetica-Bold").text("Resumo do período");
    documento.font("Helvetica");
    documento.text(`Geração da usina: ${numero(dados.total_geracao_kwh)} kWh`);
    documento.text(`Créditos líquidos: ${numero(dados.total_creditos_kwh)} kWh`);
    documento.text(`Consumo: ${numero(dados.total_consumo_kwh)} kWh`);
    documento.text(`Saldo de energia: ${numero(dados.saldo_kwh)} kWh`);
    documento.text(`Economia estimada: R$ ${numero(dados.economia_estimada_reais, 2)}`);
    if (dados.origem_dados_tcp) {
      documento.text(`Origem do cálculo de créditos: ${dados.origem_dados_tcp}`);
    }
    documento.moveDown();

    if (dados.telemetria_tcp) {
      documento.font("Helvetica-Bold").text("Telemetria da usina (Servidor TCP Java)");
      documento.font("Helvetica");
      if (dados.telemetria_tcp.status_servidor === "online") {
        const resumoTelemetria = [
          dados.telemetria_tcp.usina ? `Usina: ${dados.telemetria_tcp.usina}` : null,
          dados.telemetria_tcp.status_operacao ? `Status: ${dados.telemetria_tcp.status_operacao}` : null,
          dados.telemetria_tcp.geracao_atual ? `Geração atual: ${dados.telemetria_tcp.geracao_atual}` : null,
          dados.telemetria_tcp.tensao ? `Tensão: ${dados.telemetria_tcp.tensao}` : null,
          dados.telemetria_tcp.frequencia ? `Frequência: ${dados.telemetria_tcp.frequencia}` : null,
        ].filter(Boolean).join("  |  ");
        documento.text(resumoTelemetria || dados.telemetria_tcp.bruta || "Servidor TCP Java online");
      } else {
        documento.text(
          dados.telemetria_tcp.mensagem_erro ||
            "Servidor TCP Java (porta 5050) indisponível na geração deste relatório.",
        );
      }
      documento.moveDown();
    }

    documento.font("Helvetica-Bold").text("Detalhamento mensal");
    documento.moveDown(0.4);
    const colunas = [48, 150, 247, 344, 441];
    const cabecalhos = ["Mês", "Geração kWh", "Créditos kWh", "Consumo kWh", "Saldo kWh"];
    documento.fontSize(8);
    const yCabecalho = documento.y;
    cabecalhos.forEach((cabecalho, indice) => documento.text(cabecalho, colunas[indice], yCabecalho, {
      width: indice === 0 ? 95 : 90,
      align: indice === 0 ? "left" : "right",
    }));
    documento.moveDown(0.5);
    documento.moveTo(48, documento.y).lineTo(547, documento.y).stroke();
    documento.moveDown(0.3);

    for (const mes of dados.meses) {
      const y = documento.y;
      const valores = [
        mes.mes_referencia,
        numero(mes.geracao_kwh),
        numero(mes.creditos_liquidos_kwh),
        numero(mes.consumo_kwh),
        numero(mes.saldo_mes_kwh),
      ];
      valores.forEach((valor, indice) => documento.text(valor, colunas[indice], y, {
        width: indice === 0 ? 95 : 90,
        align: indice === 0 ? "left" : "right",
      }));
      documento.moveDown(0.35);
    }

    documento.moveDown();
    documento.fontSize(8).fillColor("#666666")
      .text(`Gerado em ${new Intl.DateTimeFormat("pt-BR", { dateStyle: "long", timeStyle: "short" }).format(new Date())}`);
    documento.end();
  });
}
