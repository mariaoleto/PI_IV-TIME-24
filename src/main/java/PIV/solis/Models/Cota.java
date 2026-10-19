package PIV.solis.Models;

import java.util.Date;
import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;
import org.springframework.data.mongodb.core.index.Indexed;

@Document("cotas")
public record Cota(
        @Id ObjectId id,
        @Indexed
        @Field("membro_id") ObjectId membroId,
        @Indexed
        @Field("usina_id") ObjectId usinaId,
        @Field("percentual") Object percentual,
        @Field("tarifa_kwh") Object tarifaKwh,
        @Field("data_inicio") Date dataInicio) {
}
