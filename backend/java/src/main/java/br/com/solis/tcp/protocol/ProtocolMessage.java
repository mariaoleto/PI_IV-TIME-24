// autora estrutura: Lara Brondi 
// adaptação: Maria Júlia Lazarini Oleto
// significado do arquivo: 
// classe que representa a mensagem enviada/recebida no protocolo TCP
// encapsula o nome do comando (command) e o conteúdo que veio após o comando (payload)

package br.com.solis.tcp.protocol;

import java.util.Objects;

public class ProtocolMessage {

    // atributos privados e imutáveis (encapsulamento)
    private final String command;
    private final String payload;

    // construtor da mensagem recebida
    public ProtocolMessage(String command, String payload) {
        this.command = command != null ? command : "";
        this.payload = payload != null ? payload : "";
    }

    // métodos getters para leitura dos atributos encapsulados
    public String getCommand() {
        return this.command;
    }

    public String command() {
        return this.command;
    }

    public String getPayload() {
        return this.payload;
    }

    public String payload() {
        return this.payload;
    }

    // equals que compara as mensagens pelo conteúdo
    @Override
    public boolean equals(Object o) {
        if (this == o)
            return true;
        if (o == null)
            return false;
        if (o.getClass() != this.getClass())
            return false;
        ProtocolMessage that = (ProtocolMessage) o;
        if (!command.equals(that.command))
            return false;
        if (!payload.equals(that.payload))
            return false;
        return true;
    }

    // gera o código hash baseado nos atributos da mensagem
    @Override
    public int hashCode() {
        int retorno = 1;
        retorno = 2 * retorno + command.hashCode();
        retorno = 2 * retorno + payload.hashCode();
        if (retorno < 0)
            retorno = -retorno;
        return retorno;
    }

    // representação em formato texto da mensagem para depuração e logs
    @Override
    public String toString() {
        return "ProtocolMessage[command=" + command + ", payload=" + payload + "]";
    }
}
