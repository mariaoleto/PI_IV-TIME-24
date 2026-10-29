//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo: model do documento da usina (coleção "usinas"), usado somente para leitura no painel admin
// obs.: o cadastro da usina é feito em outro módulo; aqui todos os campos são tolerantes a ausência

package PIV.solis.Models;

import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

@Document("usinas")
public record Usina(
                @Id ObjectId id,
                @Field("nome") String nome,
                @Field("localizacao") String localizacao,
                @Field("capacidade_kwp") Object capacidadeKwp,
                @Field("geracao_esperada_kwh_mes") Object geracaoEsperadaKwhMes,
                @Field("ativa") Boolean ativa) {
}
