// autora: Maria Júlia Lazarini Oleto RA: 25006031
// significado do arquivo:
// comunicado enviado pelo servidor para todos os clientes quando o servidor é desativado

package br.com.solis.tcp.protocol;

public class ComunicadoDeDesligamento extends Comunicado {

    public ComunicadoDeDesligamento() {
        super("DESLIGAMENTO");
    }

    @Override
    public String toString() {
        return "DESLIGAMENTO: Servidor finalizado.";
    }
}