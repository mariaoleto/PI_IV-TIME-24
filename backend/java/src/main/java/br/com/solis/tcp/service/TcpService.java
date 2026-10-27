// autora original: Lara Brondi
// regras de energia e rateio de cotas: Maria Júlia Lazarini Oleto
// siginificado do arquivo:
// recebe o comando e decide a resposta

package br.com.solis.tcp.service;

import br.com.solis.tcp.protocol.ProtocolMessage;

public class TcpService {

    public String process(ProtocolMessage message) {
        return switch (message.command()) {
            case "PING" -> "PONG";
            case "ECHO" -> message.payload().isEmpty()
                    ? "ERROR: use ECHO <texto>"
                    : "OK: " + message.payload();
            // status usina
            case "STATUS_USINA" -> "OK USINA=Solis_1 STATUS=OPERANDO GERACAO_ATUAL=14.2kW TENSAO=220V FREQ=60Hz";
            // calculo de créditos por cota
            case "CALCULAR_COTAS" -> processarCalculoCOtas(message.payload());
            case "HELP" -> "Comandos: PING, ECHO <texto>, HELP, SAIR";
            case "SAIR", "QUIT" -> "BYE";
            case "" -> "ERROR: mensagem vazia";
            default -> "ERROR: comando desconhecido. Envie HELP.";
        };
    }

    // calcula a quantidade de kwh de cada membro
    // com base na cota percentual
    private String processarCalculoCotas(String payload) {
        try {
            if (payload == null || !payload.contains("total=") || !payload.contains("cotas=")) {
                return "ERROR: formato invalido. Use: CALCULAR_COTAS total=1240;cotas=25,30,45";
            }

            String[] partes = payload.split(";");
            double totalGeracao = 0;
            String[] cotasStr = new String[0];

            for (String parte : partes) {
                if (parte.startsWith("total=")) {
                    totalGeracao = Double.parseDouble(parte.replace("total=",
                            "").trim());
                } else if (parte.startsWith("cotas=")) {
                    cotasStr = parte.replace("cotas=", "").split(",");
                }
            }

            List<String> resultados = new ArrayList<>();
            for (String cota : cotasStr) {
                double perc = Double.parseDouble(cota.trim());
                double kwhCalculado = (totalGeracao * perc) / 100.0;
                resultados.add(perc + "%=" + String.format(java.util.Locale.US,
                        "%.1f", kwhCalculado + "kWh"));
            }

            return "OK" + String.join(";", resultados);
        } catch (Exception e) {
            return "ERRO: falha ao calcular cotas: " + e.getMessage();
        }
    }
}