// autora: Maria Júlia Lazarini Oleto
// significado do arquivo: modelo de docuemnto da cota de cada membro apos a distribuicao da geracao

package PIV.solis.Models;

import com.fasterxml.jackson.annotation.JsonProperty;

public record CotaMembroDTO(
                @JsonProperty("cota_id") String cotaId,
                @JsonProperty("membro_id") String membroId,
                String nome,
                double percentual,
                @JsonProperty("tarifa_kwh") double tarifaKwh) {
}
