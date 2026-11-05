// Autora: Marina Hehnes Espósito.
// Propósito: representa a identificação do membro e o percentual da cota atualizada.
package PIV.solis.Models;

import com.fasterxml.jackson.annotation.JsonProperty;

public record CotaAtualizacaoDTO(
        @JsonProperty("membro_id") String membroId,
        Double percentual) {
}
