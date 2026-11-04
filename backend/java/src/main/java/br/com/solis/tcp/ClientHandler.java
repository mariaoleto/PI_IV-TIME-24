// autora: Lara Brondi
// significado do arquivo: 
// toda vez que alguém conecta no servidor, o java cria um ClientHandler (trata o cliente e o que ele envia)
// rodando em uma thread separada
// usa um BufferedReader para ler o que o cliente enviou (decodifica e le linha por linha)
// e um PrintWriter para enviar a resposta de volta pelo socket (codifica a mensagem e envia)

package br.com.solis.tcp;

import br.com.solis.tcp.protocol.MessageProtocol;
import br.com.solis.tcp.protocol.ProtocolMessage;
import br.com.solis.tcp.service.TcpService;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

public class ClientHandler implements Runnable {
    // atributos de socket, o serviço tcp e o construtor das mensagens
    private final Socket socket;
    private final TcpService service;
    private final MessageProtocol protocol = new MessageProtocol();

    // construtor que instancia o socket e o serviço
    public ClientHandler(Socket socket, TcpService service) {
        this.socket = socket;
        this.service = service;
    }

    // metodo run que é iniciado quando uma thread é criada
    @Override
    public void run() {
        // abre e fecha o socket
        // gerencia os buffers de leitura e escrita
        try (
                // abre o socket
                Socket client = socket;
                // cria o buffer de leitura
                BufferedReader input = new BufferedReader(new InputStreamReader(
                        client.getInputStream(), StandardCharsets.UTF_8));
                // cria o buffer de escrita
                PrintWriter output = new PrintWriter(client.getOutputStream(), true, StandardCharsets.UTF_8)) {
            String line;
            // le o que o cliente enviou
            while ((line = input.readLine()) != null) {
                // decodifica a mensagem
                ProtocolMessage message = protocol.parse(line);
                // envia a resposta
                output.println(service.process(message));
                // verifica caso deu erro ou se o cliente enviou o comando de encerramento
                if (protocol.isQuit(message) || output.checkError()) {
                    break;
                }
            }
            // caso de erro, manda mensagem de erro
        } catch (IOException e) {
            System.err.println("Erro ao atender cliente TCP: " + e.getMessage());
        }
    }
}
