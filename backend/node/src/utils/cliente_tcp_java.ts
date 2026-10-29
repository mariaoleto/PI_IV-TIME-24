// autora: Maria Júlia Lazarini Oleto
// significado do arquivo:
// cliente TCP que conecta no Java
// envia comandos para o servidor Java Socket na porta 5050
// ouve as respostas e retorna o texto 


import net from "node:net";

const PORTA_TCP_JAVA = 5050;
const HOST_TCP_JAVA = "127.0.0.1";

export function enviarComandoTcp(comando: string, tempoLimiteMs = 3000): Promise<string> {
    return new Promise((resolve, reject) => {
        let resposta = "";
        const socket = new net.Socket();

        // define um tempo limite 
        socket.setTimeout(tempoLimiteMs);
        socket.connect(PORTA_TCP_JAVA, HOST_TCP_JAVA, () => {

            // envia o comando com \n do jeito que o java espera
            socket.write(`${comando.trim()}\n`);
        });

        // devolve a resposta com os dados
        socket.on("data", (dados) => {
            resposta += dados.toString();
            socket.end();
            resolve(resposta.trim());
        });

        // caso acabe o tempo limite
        socket.on("timeout", () => {
            socket.destroy();
            reject(new Error("Tempo limite esgotado ao aguardar resposta do servidor TCP Java"));
        });

        // caso de erro de conexão com o servidor
        socket.on("error", (erro: NodeJS.ErrnoException) => {
            socket.destroy();
            if (erro.code === "ECONNREFUSED") {
                reject(new Error("Servidor TCP Java não está ativo na porta 5050"));
            } else {
                reject(new Error(`Erro de comunicação TCP com Java: ${erro.message}`));
            }
        });
    });
}