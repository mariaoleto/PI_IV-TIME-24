// autora: Maria Júlia Lazarini Oleto RA: 25006031
// significado do arquivo:
// classe que transporta os dados de resposta 
// (resultado de cálculos ou status) de volta ao cliente

package br.com.solis.tcp.protocol;

import java.util.Objects;

public class Resultado extends Comunicado {

    private final String conteudo;

    public Resultado(String conteudo) {
        super("RESULTADO");
        this.conteudo = conteudo != null ? conteudo : "";
    }

    // getter
    public String getConteudo() {
        return this.conteudo;
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
        Resultado r = (Resultado) obj;
        if (!this.conteudo.equals(r.conteudo))
            return false;
        return true;
    }

    @Override
    public int hashCode() {
        int retorno = 1;
        retorno = 2 * retorno + this.conteudo.hashCode();
        if (retorno < 0)
            retorno = -retorno;
        return retorno;
    }

    @Override
    public String toString() {
        return this.conteudo;
    }

}
