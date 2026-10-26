package br.com.solis.tcp.service;

import br.com.solis.tcp.protocol.ProtocolMessage;

public class TcpService {
    public String process(ProtocolMessage message) {
        return switch (message.command()) {
            case "PING" -> "PONG";
            case "ECHO" -> message.payload().isEmpty()
                    ? "ERROR: use ECHO <texto>"
                    : "OK: " + message.payload();
            case "HELP" -> "Comandos: PING, ECHO <texto>, HELP, SAIR";
            case "SAIR", "QUIT" -> "BYE";
            case "" -> "ERROR: mensagem vazia";
            default -> "ERROR: comando desconhecido. Envie HELP.";
        };
    }
}
