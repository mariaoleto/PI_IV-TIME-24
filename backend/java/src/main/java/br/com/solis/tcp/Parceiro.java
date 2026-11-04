// autoras: 
// Maria Júlia Lazarini Oleto RA: 25006031 
// Lara Brondi
// significado do arquivo:
// encapsula a conexão socket do cliente com os métodos de envio e recepção sincronizados
// converte mensagens recebidas em instancias de Comunicado 

package br.com.solis.tcp;

import br.com.solis.tcp.protocol.*;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.concurrent.Semaphore;

public class Parceiro {

    private final Socket conexao;
    private final BufferedReader receptor;
    private final PrintWriter transmissor;

    private Comunicado proximoComunicado = null;

    private final Semaphore mutEx = new Semaphore(1, true);

    public Parceiro(Socket conexao, BufferedReader receptor, PrintWriter transmissor) throws Exception {

        // valida os parametros
        if (conexao == null)
            throw new Exception("Conexao ausente");
        if (receptor == null)
            throw new Exception("Receptor ausente");
        if (transmissor == null)
            throw new Exception("Transmissor ausente");

        // inicializa os atributos
        this.conexao = conexao;
        this.receptor = receptor;
        this.transmissor = transmissor;
    }

    // envia um comunicado para o cliente
    public void receba(Comunicado x) throws Exception {
        try {
            this.transmissor.println(x.toString());
            this.transmissor.flush();
        } catch (Exception erro) {
            throw new Exception("Erro de transmissao");
        }
    }

    // espia o proximo comunicado sem remover da fila
    public Comunicado espie() throws Exception {
        try {
            // pega o proximo comunicado sem interromper a fila
            this.mutEx.acquireUninterruptibly();
            // le o comunicado, se for null, le o próximo
            if (this.proximoComunicado == null) {
                this.proximoComunicado = lerProximoComunicado();
            }
            // faz o release e retorna o comunicado
            this.mutEx.release();
            return this.proximoComunicado;
        } catch (Exception erro) {
            throw new Exception("Erro de recepcao");
        }
    }

    // le e retorna o comunicado enviado pelo cliente
    public Comunicado envie() throws Exception {
        try {
            if (this.proximoComunicado == null) {
                this.proximoComunicado = lerProximoComunicado();
            }
            Comunicado ret = this.proximoComunicado;
            this.proximoComunicado = null;
            return ret;
        } catch (Exception erro) {
            throw new Exception("Erro de recepcao");
        }
    }

    // le o texto do socket e instancia o Pedido correspondente
    private Comunicado lerProximoComunicado() throws IOException {
        // le a linha do socket
        String linha = this.receptor.readLine();
        if (linha == null) {
            return null;
        }
        // tira os espaços em branco
        String comandoTrim = linha.trim();
        // retorna o pedido correspondente
        if (comandoTrim.isEmpty()) {
            return new Comunicado("");
        }
        if (comandoTrim.startsWith("CALCULAR_COTAS")) {
            String payload = comandoTrim.length() > 14 ? comandoTrim.substring(14).trim() : "";
            return new PedidoCalcularCotas(payload);
        }
        if (comandoTrim.equals("STATUS_USINA")) {
            return new PedidoStatusUsina();
        }
        if (comandoTrim.equalsIgnoreCase("SAIR") || comandoTrim.equalsIgnoreCase("QUIT")) {
            return new PedidoParaSair();
        }
        if (comandoTrim.equalsIgnoreCase("PING")) {
            return new Comunicado("PING");
        }
        return new Comunicado(comandoTrim);
    }

    // encerra a conexao e fecha os streams
    public void adeus() throws Exception {
        try {
            this.transmissor.close();
            this.receptor.close();
            this.conexao.close();
        } catch (Exception erro) {
            throw new Exception("Erro de desconexao");
        }
    }
}
