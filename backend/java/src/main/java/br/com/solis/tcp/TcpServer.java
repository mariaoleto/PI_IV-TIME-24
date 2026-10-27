// autora: Lara Brondi
// significado do arquivo:
// cria o ServerSocket na porta 5050
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
    private static final int DEFAULT_PORT = 5050;
    private static final int MAX_CLIENTS = 10;

    public static void main(String[] args) {
        int port = parsePort(args);
        ExecutorService clients = Executors.newFixedThreadPool(MAX_CLIENTS);
        TcpService service = new TcpService();
        try (ServerSocket server = new ServerSocket(
                port, 50, InetAddress.getLoopbackAddress())) {
            System.out.println("Servidor TCP ouvindo em localhost:" + port);
            while (true) {
                Socket socket = server.accept();
                clients.execute(new ClientHandler(socket, service));
            }
        } catch (IOException e) {
            throw new IllegalStateException("Não foi possível iniciar o servidor TCP", e);
        } finally {
            clients.shutdownNow();
        }
    }

    private static int parsePort(String[] args) {
        if (args.length == 0) {
            return DEFAULT_PORT;
        }
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
