// autora: Maria Júlia Lazarini Oleto
// significado do arquivo: record que dita o formato da resposta do lançamento mensal

package PIV.solis.Models;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record RespostaLancamentoDTO(
                String mensagem,
                @JsonProperty("mes_referencia") String mesReferencia,
                @JsonProperty("geracao_total_kwh") double geracaoTotalKwh,
                @JsonProperty("membros_atualizados") int membrosAtualizados,
                List<DistribuicaoItemDTO> distribuicao) {
}
