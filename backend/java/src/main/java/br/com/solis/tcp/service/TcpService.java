// autora original: Lara Brondi
// regras de energia e rateio de cotas: Maria Júlia Lazarini Oleto
// siginificado do arquivo:
// recebe o comando e decide a resposta

package br.com.solis.tcp.service;

import br.com.solis.tcp.protocol.ProtocolMessage;
import java.util.ArrayList;
import java.util.List;

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
            case "CALCULAR_COTAS" -> processarCalculoCotas(message.payload());
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
            // verifica se o payload tem o formato correto
            if (payload == null || !payload.contains("total=") || !payload.contains("cotas=")) {
                return "ERROR: formato invalido. Use: CALCULAR_COTAS total=1240;cotas=25,30,45";
            }
            // split que divide o payload em parte com ";"
            String[] partes = payload.split(";");
            double totalGeracao = 0;
            // split que divide a string de cotas c,m ";"
            String[] cotasStr = new String[0];

            // for para separar o payload em partes
            for (String parte : partes) {
                // separa o total da geração
                if (parte.startsWith("total=")) {
                    totalGeracao = Double.parseDouble(parte.replace("total=",
                            "").trim());
                    // separa as cotas
                } else if (parte.startsWith("cotas=")) {
                    cotasStr = parte.replace("cotas=", "").split(",");
                }
            }

            // monta uma lista de arrays
            // calcula o kwh de cada cota, baseado no percentual
            List<String> resultados = new ArrayList<>();
            for (String cota : cotasStr) {
                double perc = Double.parseDouble(cota.trim());
                double kwhCalculado = (totalGeracao * perc) / 100.0;
                resultados.add(perc + "%=" + String.format(java.util.Locale.US,
                        "%.1f", kwhCalculado) + "kWh");
            }

            // retorna os resultados
            return "OK " + String.join(";", resultados);
        } catch (Exception e) {
            return "ERRO: falha ao calcular cotas: " + e.getMessage();
        }
    }
}