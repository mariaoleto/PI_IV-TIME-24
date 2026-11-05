// Autora: Marina Hehnes Espósito.
// Propósito: transfere os metadados do contrato de uma usina nas respostas da API.
package PIV.solis.Models;

import java.util.Date;

public record ContratoDTO(
        String usinaId,
        String nomeArquivo,
        long tamanhoBytes,
        Date dataEnvio) {

    public ContratoDTO(ContratoUsina contrato) {
        this(
                contrato.usinaId().toHexString(),
                contrato.nomeArquivo(),
                contrato.tamanhoBytes(),
                contrato.dataEnvio());
    }
}
