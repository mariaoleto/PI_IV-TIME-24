// autora: Maria Júlia Lazarini Oleto
// significado do arquivo: modelo de documento do crédito

package PIV.solis.Models;

import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import org.springframework.data.mongodb.core.index.Indexed;

@Document("creditos")
public record Credito(
                @Id ObjectId id,
                @Indexed @Field("membro_id") ObjectId membroId,
                @Indexed @Field("usina_id") ObjectId usinaId,
                @Indexed @Field("mes_referencia") String mesReferencia,
                @Field("geracao_total_kwh") Object geracaoTotalKwh,
                @Field("percentual_cota") Object percentualCota,
                @Field("creditos_brutos_kwh") Object creditosBrutosKwh,
                @Field("perdas_transmissao_kwh") Object perdasTransmissaoKwh,
                @Field("creditos_liquidos_kwh") Object creditosLiquidosKwh) {
}
