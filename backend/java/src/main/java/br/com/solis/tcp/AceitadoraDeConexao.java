// autoras: Lara Brondi e Maria Júlia Lazarini Oleto RA: 25006031
// significado do arquivo:
// thread que gerencia o ServerSocket, aguardando novas conexões de clientes
// para cada novo cliente aceito, inicia uma SupervisoraDeConexao dedicada

package br.com.solis.tcp;

import br.com.solis.tcp.service.TcpService;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;

public class AceitadoraDeConexao extends Thread {

    private final ServerSocket pedido;
    private final ArrayList<Parceiro> usuarios;
    private final TcpService service;

    public AceitadoraDeConexao(String porta, ArrayList<Parceiro> usuarios, TcpService service) throws Exception {

        // valida os parametros
        if (porta == null)
            throw new Exception("Porta ausente");
        if (usuarios == null)
            throw new Exception("Usuarios ausentes");

        // inicializa o ServerSocket com a porta informada
        try {
            this.pedido = new ServerSocket(Integer.parseInt(porta));
        } catch (Exception erro) {
            throw new Exception("Porta invalida ou em uso");
        }

        // inicializa os atributos
        this.usuarios = usuarios;
        this.service = service;
    }

    @Override
    public void run() {
        for (;;) {
            Socket conexao;
            try {
                // aceita a conexão com o cliente
                conexao = this.pedido.accept();
            } catch (Exception erro) {
                continue;
            }
            try {
                // cria uma supervisora para o novo cliente
                SupervisoraDeConexao supervisora = new SupervisoraDeConexao(conexao, this.usuarios, this.service);
                supervisora.start();
            } catch (Exception erro) {
                // erro ao iniciar supervisora
            }
        }
    }
}
