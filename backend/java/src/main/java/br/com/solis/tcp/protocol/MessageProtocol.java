package br.com.solis.tcp.protocol;

import java.util.Locale;

public class MessageProtocol {
    public ProtocolMessage parse(String line) {
        String trimmed = line.trim();
        if (trimmed.isEmpty()) {
            return new ProtocolMessage("", "");
        }

        int separator = trimmed.indexOf(' ');
        if (separator < 0) {
            return new ProtocolMessage(trimmed.toUpperCase(Locale.ROOT), "");
        }

        String command = trimmed.substring(0, separator).toUpperCase(Locale.ROOT);
        String payload = trimmed.substring(separator + 1).trim();
        return new ProtocolMessage(command, payload);
    }

    public boolean isQuit(ProtocolMessage message) {
        return message.command().equals("SAIR") || message.command().equals("QUIT");
    }
}
