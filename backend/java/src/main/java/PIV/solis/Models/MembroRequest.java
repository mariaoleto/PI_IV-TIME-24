// Autora: Marina Hehnes Espósito.
// Propósito: recebe os dados necessários para vincular um membro a uma usina.
package PIV.solis.Models;

import com.fasterxml.jackson.annotation.JsonProperty;

public record MembroRequest(
        String nome,
        String email,
        @JsonProperty("usina_id") String usinaId) {
}
