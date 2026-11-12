// autora: Maria Júlia Lazarini Oleto
// significado do arquivo:
// cliente TCP que conecta no Java
// envia comandos para o servidor Java Socket na porta 5050
// ouve as respostas e retorna o texto 


import net from "node:net";

const PORTA_TCP_JAVA = Number(process.env.PORTA_TCP_JAVA) || 5050;
const HOST_TCP_JAVA = process.env.HOST_TCP_JAVA || "127.0.0.1";

export function enviarComandoTcp(comando: string, tempoLimiteMs = 3000): Promise<string> {
    return new Promise((resolve, reject) => {
        let resposta = "";
        let finalizado = false;
        const socket = new net.Socket();

        const concluirComSucesso = () => {
            if (finalizado) return;
            finalizado = true;
            socket.end();
            resolve(resposta.trim());
        };

        const concluirComErro = (erro: Error) => {
            if (finalizado) return;
            finalizado = true;
            socket.destroy();
            reject(erro);
        };

        // define um tempo limite 
        socket.setTimeout(tempoLimiteMs);
        socket.connect(PORTA_TCP_JAVA, HOST_TCP_JAVA, () => {
            // envia o comando com \n do jeito que o java espera
            socket.write(`${comando.trim()}\n`);
        });

        // acumula os dados e conclui assim que a linha completa de resposta chegar
        socket.on("data", (dados) => {
            resposta += dados.toString("utf8");
            if (resposta.includes("\n") || resposta.includes("\r")) {
                concluirComSucesso();
            }
        });

        socket.on("end", () => {
            if (resposta.trim().length > 0) {
                concluirComSucesso();
            } else {
                concluirComErro(new Error("Servidor TCP Java encerrou a conexão sem responder"));
            }
        });

        // caso acabe o tempo limite
        socket.on("timeout", () => {
            concluirComErro(new Error("Tempo limite esgotado ao aguardar resposta do servidor TCP Java"));
        });

        // caso de erro de conexão com o servidor
        socket.on("error", (erro: NodeJS.ErrnoException) => {
            if (erro.code === "ECONNREFUSED") {
                concluirComErro(new Error("Servidor TCP Java não está ativo na porta 5050"));
            } else {
                concluirComErro(new Error(`Erro de comunicação TCP com Java: ${erro.message}`));
            }
        });
    });
}