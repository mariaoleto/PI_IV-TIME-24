// Autora: Marina Hehnes Espósito.
// Propósito: persiste os metadados do contrato vinculado a uma usina.
package PIV.solis.Models;

import java.util.Date;
import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

@Document("contratos_usina")
public record ContratoUsina(
        @Id ObjectId id,
        @Indexed @Field("usina_id") ObjectId usinaId,
        @Field("nome_arquivo") String nomeArquivo,
        @Field("arquivo_armazenado") String arquivoArmazenado,
        @Field("tamanho_bytes") long tamanhoBytes,
        @Field("data_envio") Date dataEnvio) {
}
