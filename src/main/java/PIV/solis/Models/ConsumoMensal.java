package PIV.solis.Models;

import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import org.springframework.data.mongodb.core.index.Indexed;

@Document("consumos_mensal")
public record ConsumoMensal(
        @Id ObjectId id,
        @Indexed
        @Field("membro_id") ObjectId membroId,
        @Indexed
        @Field("usina_id") ObjectId usinaId,
        @Indexed
        @Field("mes_referencia") String mesReferencia,
        @Field("consumo_kwh") Object consumoKwh,
        @Field("consumo_total_kwh") Object consumoTotalKwh,
        @Field("total_consumo_kwh") Object totalConsumoKwh,
        @Field("kwh") Object kwh) {
}
