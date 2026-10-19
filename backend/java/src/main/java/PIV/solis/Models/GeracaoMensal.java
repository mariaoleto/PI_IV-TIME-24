// autora: Maria Júlia Lazarini Oleto
// significado do arquivo: modelo de documento da geração mensal

package PIV.solis.Models;

import java.util.Date;
import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

@Document("geracao_mensal")
public record GeracaoMensal(
                @Id ObjectId id,
                @Indexed @Field("usina_id") ObjectId usinaId,
                @Indexed @Field("mes_referencia") String mesReferencia,
                @Field("geracao_kwh") Object geracaoKwh,
                @Field("data_lancamento") Date dataLancamento) {
}
