// Autora: Marina Hehnes Espósito.
// Propósito: representa a lista de cotas enviada para atualização de uma usina.
package PIV.solis.Models;

import java.util.List;

public record AtualizarCotasRequest(List<CotaAtualizacaoDTO> cotas) {
}
