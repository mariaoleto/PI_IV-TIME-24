// autoras: Lara Brondi e Maria Júlia Lazarini Oleto RA: 25006031
// significado do arquivo:
// thread responsável por supervisionar a comunicação com um cliente específico
// recebe comunicados do Parceiro, identifica o Pedido e envia a resposta Resultado

package br.com.solis.tcp;

import br.com.solis.tcp.protocol.*;
import br.com.solis.tcp.service.TcpService;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;

public class SupervisoraDeConexao extends Thread {

    private Parceiro usuario;
    private final Socket conexao;
    private final ArrayList<Parceiro> usuarios;
    private final TcpService service;

    public SupervisoraDeConexao(Socket conexao, ArrayList<Parceiro> usuarios, TcpService service) throws Exception {
        // valida os parametros
        if (conexao == null)
            throw new Exception("Conexao ausente");
        if (usuarios == null)
            throw new Exception("Usuarios ausentes");
        // inicializa os atributos
        this.conexao = conexao;
        this.usuarios = usuarios;
        this.service = service != null ? service : new TcpService();
    }

    @Override
    public void run() {

        PrintWriter transmissor;
        BufferedReader receptor;

        // inicializa os atributos
        try {
            transmissor = new PrintWriter(this.conexao.getOutputStream(), true, StandardCharsets.UTF_8);
            receptor = new BufferedReader(new InputStreamReader(this.conexao.getInputStream(), StandardCharsets.UTF_8));
            this.usuario = new Parceiro(this.conexao, receptor, transmissor);
        } catch (Exception erro) {
            return;
        }

        try {
            // adiciona o usuario novo a lista de usuarios
            synchronized (this.usuarios) {
                this.usuarios.add(this.usuario);
            }
            // loop que recebe e processa os comunicados dos usuarios
            for (;;) {
                // recebe o comunicado
                Comunicado comunicado = this.usuario.envie();
                if (comunicado == null) {
                    break;
                }
                // processos de cada tipo de pedido

                // pedido de cálculo dos créditos pelas cotas
                if (comunicado instanceof PedidoCalcularCotas) {
                    // cria uma variavel pedido do tipo PedidoCalcularCotas, que recebe o comunicado
                    PedidoCalcularCotas pedido = (PedidoCalcularCotas) comunicado;
                    // cria a string de resposta
                    // chama o método, com o pedido de parametro
                    String resposta = this.service.pedidoProcessarCalculoCotas(pedido);
                    // envia a resposta ao usuário
                    this.usuario.receba(new Resultado(resposta));

                    // pedido da telemetria e status da usina
                } else if (comunicado instanceof PedidoStatusUsina) {
                    this.usuario.receba(new Resultado(
                            "OK USINA=Solis_1 STATUS=OPERANDO GERACAO_ATUAL=14.2kW TENSAO=220V FREQ=60Hz"));

                    // pedido de encerramento da conexão
                } else if (comunicado instanceof PedidoParaSair) {
                    // retira o usuário da lista
                    synchronized (this.usuarios) {
                        this.usuarios.remove(this.usuario);
                    }
                    // envia mensagem de encerramento e fecha a conexão
                    this.usuario.receba(new Resultado("BYE"));
                    this.usuario.adeus();
                    return;

                    // outros tipos de pedidos
                } else if (comunicado.getComando().equalsIgnoreCase("PING")) {
                    this.usuario.receba(new Resultado("PONG"));
                } else if (comunicado.getComando().equalsIgnoreCase("HELP")) {
                    this.usuario.receba(new Resultado("Comandos: PING, STATUS_USINA, CALCULAR_COTAS, SAIR"));
                } else {
                    this.usuario.receba(new Resultado("ERROR: comando desconhecido. Envie HELP."));
                }
            }
        } catch (Exception erro) {
            try {
                this.usuario.adeus();
            } catch (Exception falha) {
            }
        } finally {
            synchronized (this.usuarios) {
                this.usuarios.remove(this.usuario);
            }
        }
    }
}
