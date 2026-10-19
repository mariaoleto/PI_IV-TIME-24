// autora: Maria Júlia Lazarini Oleto
// significado do arquivo: modelo de documento do item de distribuição da geração

package PIV.solis.Models;

import com.fasterxml.jackson.annotation.JsonProperty;

public record DistribuicaoItemDTO(
                @JsonProperty("membro_id") String membroId,
                String nome,
                double percentual,
                @JsonProperty("creditos_kwh") double creditosKwh) {
}
