package PIV.solis.Repositories;

import PIV.solis.Models.ConsumoMensal;
import PIV.solis.Models.Cota;
import PIV.solis.Models.Credito;
import PIV.solis.Models.GeracaoMensal;
import java.util.List;
import java.util.regex.Pattern;
import org.bson.types.ObjectId;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Repository;

@Repository
public class EnergiaRepository {

    private final MongoTemplate mongoTemplate;

    public EnergiaRepository(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    public Cota buscarCotaMaisRecente(String usinaId, String membroId) {
        Query consulta = new Query();
        if (usinaId != null) {
            consulta.addCriteria(Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id")));
        }
        if (membroId != null) {
            consulta.addCriteria(Criteria.where("membro_id").is(idObjeto(membroId, "membro_id")));
        }
        consulta.with(Sort.by(Sort.Order.desc("percentual"), Sort.Order.desc("data_inicio")));
        return mongoTemplate.findOne(consulta, Cota.class);
    }

    public List<GeracaoMensal> buscarGeracoesMensais(int ano, String usinaId) {
        Query consulta = new Query()
                .addCriteria(Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id")))
                .addCriteria(mesNoAno(ano));
        consulta.with(Sort.by(Sort.Order.asc("mes_referencia")));
        return mongoTemplate.find(consulta, GeracaoMensal.class);
    }

    public List<Credito> buscarCreditosMensais(int ano, String usinaId, String membroId) {
        Query consulta = new Query()
                .addCriteria(Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id")))
                .addCriteria(Criteria.where("membro_id").is(idObjeto(membroId, "membro_id")))
                .addCriteria(mesNoAno(ano));
        consulta.with(Sort.by(Sort.Order.asc("mes_referencia")));
        return mongoTemplate.find(consulta, Credito.class);
    }

    public List<ConsumoMensal> buscarConsumosMensais(int ano, String usinaId, String membroId) {
        Query consulta = new Query()
                .addCriteria(Criteria.where("membro_id").is(idObjeto(membroId, "membro_id")))
                .addCriteria(mesNoAno(ano));
        if (usinaId != null) {
            consulta.addCriteria(new Criteria().orOperator(
                    Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id")),
                    Criteria.where("usina_id").exists(false),
                    Criteria.where("usina_id").is(null)));
        }
        consulta.with(Sort.by(Sort.Order.asc("mes_referencia")));
        return mongoTemplate.find(consulta, ConsumoMensal.class);
    }

    private Criteria mesNoAno(int ano) {
        return Criteria.where("mes_referencia").regex(
                Pattern.compile("^" + ano + "-"));
    }

    private ObjectId idObjeto(String valor, String nomeCampo) {
        if (valor == null || !ObjectId.isValid(valor)) {
            throw new IllegalArgumentException(nomeCampo + " invalido");
        }
        return new ObjectId(valor);
    }
}
