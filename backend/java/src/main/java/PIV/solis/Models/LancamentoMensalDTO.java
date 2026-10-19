// autora: Maria Júlia Lazarini Oleto
// significado do arquivo: modelo de documento do lançamento mensal

package PIV.solis.Models;

import com.fasterxml.jackson.annotation.JsonProperty;

public record LancamentoMensalDTO(
                @JsonProperty("mes_referencia") String mesReferencia,
                @JsonProperty("geracao_kwh") Double geracaoKwh,
                @JsonProperty("usina_id") String usinaId) {
}
