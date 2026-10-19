// autora: Maria Júlia Lazarini Oleto
// significado do arquivo: record que dita o formato do resumo de energia

package PIV.solis.Models;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ResumoEnergia(
                int ano,
                @JsonProperty("usina_id") String usinaId,
                @JsonProperty("membro_id") String membroId,
                @JsonProperty("percentual_cota") double percentualCota,
                @JsonProperty("tarifa_kwh") double tarifaKwh,
                @JsonProperty("total_geracao_kwh") double totalGeracaoKwh,
                @JsonProperty("total_consumo_kwh") double totalConsumoKwh,
                @JsonProperty("saldo_acumulado_kwh") double saldoAcumuladoKwh,
                @JsonProperty("economia_estimada_reais") double economiaEstimadaReais,
                List<MesEnergia> meses) {
}
