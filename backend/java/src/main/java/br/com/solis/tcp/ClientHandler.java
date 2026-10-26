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
    private final Socket socket;
    private final TcpService service;
    private final MessageProtocol protocol = new MessageProtocol();

    public ClientHandler(Socket socket, TcpService service) {
        this.socket = socket;
        this.service = service;
    }

    @Override
    public void run() {
        try (
            Socket client = socket;
            BufferedReader input = new BufferedReader(new InputStreamReader(
                    client.getInputStream(), StandardCharsets.UTF_8));
            PrintWriter output = new PrintWriter(client.getOutputStream(), true, StandardCharsets.UTF_8)
        ) {
            String line;
            while ((line = input.readLine()) != null) {
                ProtocolMessage message = protocol.parse(line);
                output.println(service.process(message));

                if (protocol.isQuit(message) || output.checkError()) {
                    break;
                }
            }
        } catch (IOException e) {
            System.err.println("Erro ao atender cliente TCP: " + e.getMessage());
        }
    }
}
