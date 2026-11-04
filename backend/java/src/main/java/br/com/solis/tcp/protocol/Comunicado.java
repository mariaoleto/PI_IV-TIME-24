// autora: Maria Júlia Lazarini Oleto RA: 25006031
// significado do arquivo:
// classe base de todas as mensagens e comunicados que são enviadas e recebidas no servidor 
// define o comando base e implementa Serializable (pode ser transformada em bytes para envio) e Cloneable

package br.com.solis.tcp.protocol;

import java.io.Serializable;
import java.util.Objects;

public class Comunicado implements Serializable, Cloneable {

    private final String comando;

    public Comunicado(String comando) {
        this.comando = comando != null ? comando : "";
    }

    // getter
    public String getComando() {
        return this.comando;
    }

    // métodos obrigatórios
    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (obj.getClass() != this.getClass())
            return false;
        Comunicado o = (Comunicado) obj;
        if (!this.comando().equals(o.comando))
            return false;
        return true;
    }

    @Override
    public int hashCode() {
        int retorno = 1;
        retorno = 2 * retorno + this.comando.hashCode();
        if (retorno < 0)
            retorno = -retorno;
        return retorno;
    }

    @Override
    public String toString() {
        return "Comunicado[comando=" + comando + "]";
    }
}
