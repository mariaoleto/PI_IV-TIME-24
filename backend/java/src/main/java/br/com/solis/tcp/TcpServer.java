// autora: Lara Brondi
// significado do arquivo:
// cria o ServerSocket na porta 5050 (servidor socket)
// cria uma pool de threads para gerenciar clientes simultaneos 
// fica em loop aguardando conexões 

package br.com.solis.tcp;

import br.com.solis.tcp.service.TcpService;
import java.io.IOException;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class TcpServer {
    // porta padrao e máximo de clientes
    private static final int DEFAULT_PORT = 5050;
    private static final int MAX_CLIENTS = 10;

    public static void main(String[] args) {
        // define a porta
        int port = parsePort(args);
        // cria a pool de threads com o tamanho máximo de clientes
        ExecutorService clients = Executors.newFixedThreadPool(MAX_CLIENTS);
        // instancia um serviço tcp
        TcpService service = new TcpService();
        // atribui a porta informada
        try (ServerSocket server = new ServerSocket(
                port, 50, InetAddress.getLoopbackAddress())) {
            System.out.println("Servidor TCP ouvindo em localhost:" + port);
            // loop para aceitar novas conexões
            while (true) {
                Socket socket = server.accept();
                // cria um client handler e um service para atender o cliente
                clients.execute(new ClientHandler(socket, service));
            }
            // em caso de erro, lança exceção
        } catch (IOException e) {
            throw new IllegalStateException("Não foi possível iniciar o servidor TCP", e);
            // encerra a pool
        } finally {
            clients.shutdownNow();
        }
    }

    private static int parsePort(String[] args) {
        // converte o args no numero da porta
        if (args.length == 0) {
            return DEFAULT_PORT;
        }

        // verificações do args
        if (args.length > 1) {
            throw new IllegalArgumentException("Uso: TcpServer [porta]");
        }
        try {
            int port = Integer.parseInt(args[0]);
            if (port < 1 || port > 65535) {
                throw new IllegalArgumentException("A porta deve estar entre 1 e 65535.");
            }
            return port;
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("A porta informada não é válida.", e);
        }
    }
}
