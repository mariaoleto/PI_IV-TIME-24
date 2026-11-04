// autora: Maria Júlia Lazarini Oleto RA: 25006031
// significado do arquivo:
// classe de pedido de solicitação do cliente para encerrar a conexão com o servidor

package br.com.solis.tcp.protocol;

public class PedidoParaSair extends Comunicado {

    public PedidoParaSair() {
        super("SAIR");
    }

    @Override
    public String toString() {
        return "SAIR";
    }
}
