// autora: Maria Júlia Lazarini Oleto 
// RA: 25006031
// significado do arquivo:
// classe de pedido da telemetria e status operacional da usina

package br.com.solis.tcp.protocol;

public class PedidoStatusUsina extends Comunicado {

    public PedidoStatusUsina() {
        super("STATUS_USINA");
    }

    @Override
    public String toString() {
        return "STATUS_USINA";
    }

}