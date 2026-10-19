package PIV.solis.Models;

import com.fasterxml.jackson.annotation.JsonProperty;

public record MesEnergia(
        String mes,
        @JsonProperty("mes_referencia") String mesReferencia,
        @JsonProperty("geracao_kwh") double geracaoKwh,
        @JsonProperty("creditos_liquidos_kwh") double creditosLiquidosKwh,
        @JsonProperty("consumo_kwh") double consumoKwh,
        @JsonProperty("saldo_mes_kwh") double saldoMesKwh) {
}
