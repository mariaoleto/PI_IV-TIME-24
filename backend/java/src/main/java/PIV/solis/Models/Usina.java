// Autora: Marina Hehnes Espósito.
// Propósito: modelo de persistência dos dados de uma usina.
package PIV.solis.Models;

import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

@Document("usinas")
public record Usina(
        @Id ObjectId id,
        @Field("nome") String nome,
        @Field("potencia") Double potencia,
        @Field("distribuidora") String distribuidora,
        @Field("codigo") String codigo,
        @Field("local") String local) {
}
