// autora: Maria Júlia Lazarini Oleto
// significado do arquivo: modelo de documento do membro

package PIV.solis.Models;

import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

@Document("membros")
public record Membro(
                @Id ObjectId id,
                @Field("nome") String nome,
                @Field("email") String email,
                @Field("tipo_usuario") String tipoUsuario,
                @Field("usina_id") ObjectId usinaId) {
}
