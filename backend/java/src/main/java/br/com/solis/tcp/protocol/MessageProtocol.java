// autora: Lara Brondi
// significado do arquivo:
// le e estrutura as linhas enviadas pelo cliente
// as transforma em objetos command e payload (mensagem com o que foi requisitado e resposta)
// identifica se o cliente mandou comando de encerramento 

package br.com.solis.tcp.protocol;

import java.util.Locale;

public class MessageProtocol {
    public ProtocolMessage parse(String line) {
        // "divide" a string em command e payload
        // baseado no primeiro espaço que encontrar na string
        String trimmed = line.trim();
        if (trimmed.isEmpty()) {
            return new ProtocolMessage("", "");
        }
        int separator = trimmed.indexOf(' ');
        if (separator < 0) {
            // se não achar o espaço, manda só o command
            return new ProtocolMessage(trimmed.toUpperCase(Locale.ROOT), "");
        }
        String command = trimmed.substring(0, separator).toUpperCase(Locale.ROOT);
        String payload = trimmed.substring(separator + 1).trim();
        return new ProtocolMessage(command, payload);
    }

    // caso o cliente mande "SAIR" ou "QUIT"
    // entende a mensagem como comando de encerramento do servidor
    public boolean isQuit(ProtocolMessage message) {
        return message.command().equals("SAIR") || message.command().equals("QUIT");
    }
}