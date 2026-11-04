// autora: Maria Júlia Lazarini Oleto RA: 25006031
// significado do arquivo:
// classe da solicitação de cálculo e rateio de cotas de energia enviada ao servidor

package br.com.solis.tcp.protocol;

import java.util.Objects;

public class PedidoCalcularCotas extends Comunicado {

    private final String payload;

    public PedidoCalcularCotas(String payload) {
        super("CALCULAR_COTAS");
        this.payload = payload != null ? payload : "";
    }

    // getter
    public String getPayload() {
        return this.payload;
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
        PedidoCalcularCotas o = (PedidoCalcularCotas) obj;
        if (!this.payload().equals(o.payload()))
            return false;
        return true;
    }

    @Override
    public int hashCode() {
        int retorno = 1;
        retorno = retorno * 2 + this.payload.hashCode();
        if (retorno < 0)
            retorno = -retorno;
        return retorno;
    }

    // representação textual do pedido de cálculo
    @Override
    public String toString() {
        return "PedidoCalcularCotas[comando=" + getComando() + ", payload=" + payload + "]";
    }
}
