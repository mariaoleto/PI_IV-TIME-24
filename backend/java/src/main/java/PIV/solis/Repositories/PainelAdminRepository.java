//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// acesso ao banco para o painel administrativo (somente leitura)
// reaproveita os documentos de usina, cotas, geração mensal, créditos e consumos

package PIV.solis.Repositories;

import PIV.solis.Models.ConsumoMensal;
import PIV.solis.Models.Cota;
import PIV.solis.Models.Credito;
import PIV.solis.Models.GeracaoMensal;
import PIV.solis.Models.Usina;
import java.util.List;
import org.bson.types.ObjectId;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Repository;

@Repository
public class PainelAdminRepository {

    private final MongoTemplate mongoTemplate;

    public PainelAdminRepository(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    // busca uma usina pelo id; retorna null se não existir
    public Usina buscarUsina(String usinaId) {
        return mongoTemplate.findById(idObjeto(usinaId, "usina_id"), Usina.class);
    }

    // busca a primeira usina ativa (ativa ausente conta como ativa)
    public Usina buscarUsinaAtiva() {
        Query consulta = new Query(Criteria.where("ativa").ne(false));
        consulta.with(Sort.by(Sort.Order.asc("_id")));
        return mongoTemplate.findOne(consulta, Usina.class);
    }

    // descobre o id de uma usina a partir da primeira cota cadastrada
    // (fallback para bases que ainda não possuem a coleção de usinas)
    public String buscarUsinaIdPelasCotas() {
        Query consulta = new Query(Criteria.where("usina_id").ne(null));
        consulta.with(Sort.by(Sort.Order.asc("_id")));
        Cota cota = mongoTemplate.findOne(consulta, Cota.class);
        return cota != null && cota.usinaId() != null ? cota.usinaId().toHexString() : null;
    }

    public List<Cota> listarCotas(String usinaId) {
        Query consulta = new Query(Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id")));
        return mongoTemplate.find(consulta, Cota.class);
    }

    // todos os registros de geração da usina, em ordem cronológica
    public List<GeracaoMensal> listarGeracoes(String usinaId) {
        Query consulta = new Query(Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id")));
        consulta.with(Sort.by(Sort.Order.asc("mes_referencia")));
        return mongoTemplate.find(consulta, GeracaoMensal.class);
    }

    public List<Credito> listarCreditos(String usinaId, String mesReferencia) {
        Query consulta = new Query(Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id"))
                .and("mes_referencia").is(mesReferencia));
        return mongoTemplate.find(consulta, Credito.class);
    }

    // consumos do mês; aceita documentos antigos sem usina_id (mesmo critério do módulo de energia)
    public List<ConsumoMensal> listarConsumos(String usinaId, String mesReferencia) {
        Query consulta = new Query(Criteria.where("mes_referencia").is(mesReferencia))
                .addCriteria(new Criteria().orOperator(
                        Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id")),
                        Criteria.where("usina_id").exists(false),
                        Criteria.where("usina_id").is(null)));
        return mongoTemplate.find(consulta, ConsumoMensal.class);
    }

    private ObjectId idObjeto(String valor, String nomeCampo) {
        if (valor == null || !ObjectId.isValid(valor)) {
            throw new IllegalArgumentException(nomeCampo + " invalido");
        }
        return new ObjectId(valor);
    }
}
