// autoras: Lara Brondi e Maria Júlia Lazarini Oleto RA: 25006031
// significado do arquivo:
// classe principal do servidor Socket TCP
// inicializa a lista de usuarios, a AceitadoraDeConexao e gerencia o encerramento do servidor

package br.com.solis.tcp;

import br.com.solis.tcp.protocol.ComunicadoDeDesligamento;
import br.com.solis.tcp.service.TcpService;
import java.util.ArrayList;
import java.util.Scanner;

public class Servidor {

    // atribui a porta padrão
    public static final String PORTA_PADRAO = "5050";

    public static void main(String[] args) {

        // valida a porta passada como parametro
        if (args.length > 1) {
            System.err.println("Uso esperado: java Servidor [PORTA]\n");
            return;
        }

        // incializa a porta como a padrão
        String porta = Servidor.PORTA_PADRAO;

        // inicializa a porta informada como parametro
        if (args.length == 1) {
            porta = args[0];
        }

        // cria a lista de usuários
        ArrayList<Parceiro> usuarios = new ArrayList<>();
        // inicializa o servidor TCP
        TcpService service = new TcpService();
        // incializa a aceitadora
        AceitadoraDeConexao aceitadoraDeConexao;

        try {
            // inicializa a aceitadora com os parametros
            aceitadoraDeConexao = new AceitadoraDeConexao(porta, usuarios, service);
            aceitadoraDeConexao.start();
            System.out.println("Servidor TCP do Solis ouvindo na porta " + porta);
        } catch (Exception erro) {
            System.err.println("Erro ao iniciar o servidor: " + erro.getMessage());
            return;
        }

        // escaneia o que é digitado no teclado, para verificar quando é enviado o
        // comando de desativar
        Scanner teclado = new Scanner(System.in);
        for (;;) {
            System.out.println("O servidor esta ativo! Para desativa-lo, digite \"desativar\":");
            System.out.print("> ");
            String comando = null;
            if (teclado.hasNextLine()) {
                comando = teclado.nextLine();
            }
            if (comando != null && comando.trim().equalsIgnoreCase("desativar")) {
                synchronized (usuarios) {
                    ComunicadoDeDesligamento desligamento = new ComunicadoDeDesligamento();
                    for (Parceiro usuario : usuarios) {
                        try {
                            // envia a mensagem de desligamento para todos os usuários
                            usuario.receba(desligamento);
                            // desconecta
                            usuario.adeus();
                        } catch (Exception erro) {
                        }
                    }
                }
                System.out.println("O servidor foi desativado com sucesso!");
                System.exit(0);
            } else {
                System.err.println("Comando invalido!\n");
            }
        }
    }
}
