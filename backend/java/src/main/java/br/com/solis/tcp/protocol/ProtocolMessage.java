// autora: Lara Brondi
// significado do arquivo: 
// guarda o nome do comando (command) e o conteúdo que veio depois do comando (payload)

package br.com.solis.tcp.protocol;

public record ProtocolMessage(String command, String payload) {
}
