// autora: Maria Júlia Lazarini Oleto
// significado do arquivo: 
// centraliza o acesso ao banco 
// auxilia na pesquisa e atualizacao de informacoes e construcao dos resultados

package PIV.solis.Repositories;

import PIV.solis.Models.ConsumoMensal;
import PIV.solis.Models.Cota;
import PIV.solis.Models.CotaComMembro;
import PIV.solis.Models.Credito;
import PIV.solis.Models.GeracaoMensal;
import PIV.solis.Models.Membro;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Pattern;
import org.bson.types.ObjectId;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Repository;

@Repository
public class EnergiaRepository {

    private final MongoTemplate mongoTemplate;

    public EnergiaRepository(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    // busca a cota mais recente do membro (usando id)
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

    // busca as geracoes mensais de uma usina
    public List<GeracaoMensal> buscarGeracoesMensais(int ano, String usinaId) {
        Query consulta = new Query()
                .addCriteria(Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id")))
                .addCriteria(mesNoAno(ano));
        consulta.with(Sort.by(Sort.Order.asc("mes_referencia")));
        return mongoTemplate.find(consulta, GeracaoMensal.class);
    }

    // busca os creditos de um membro da usina
    public List<Credito> buscarCreditosMensais(int ano, String usinaId, String membroId) {
        Query consulta = new Query()
                .addCriteria(Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id")))
                .addCriteria(Criteria.where("membro_id").is(idObjeto(membroId, "membro_id")))
                .addCriteria(mesNoAno(ano));
        consulta.with(Sort.by(Sort.Order.asc("mes_referencia")));
        return mongoTemplate.find(consulta, Credito.class);
    }

    // busca os consumos mensais de um membro
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

    // busca todas as cotas com os membros
    public List<CotaComMembro> buscarTodasCotasComMembros(String usinaId, String membroId) {
        Query consulta = new Query();
        if (usinaId != null && !usinaId.isBlank()) {
            consulta.addCriteria(Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id")));
        }
        if (membroId != null && !membroId.isBlank()) {
            consulta.addCriteria(Criteria.where("membro_id").is(idObjeto(membroId, "membro_id")));
        }
        consulta.with(Sort.by(Sort.Order.desc("percentual")));
        List<Cota> cotas = mongoTemplate.find(consulta, Cota.class);

        List<ObjectId> membrosIds = cotas.stream()
                .map(Cota::membroId)
                .filter(Objects::nonNull)
                .distinct()
                .toList();

        Map<String, String> nomesPorMembro = new HashMap<>();
        if (!membrosIds.isEmpty()) {
            Query queryMembros = new Query(Criteria.where("_id").in(membrosIds));
            List<Membro> membros = mongoTemplate.find(queryMembros, Membro.class);
            for (Membro m : membros) {
                if (m.id() != null) {
                    nomesPorMembro.put(m.id().toHexString(), m.nome() != null ? m.nome() : "Membro");
                }
            }
        }

        return cotas.stream().map(c -> {
            String mid = c.membroId() != null ? c.membroId().toHexString() : null;
            String nome = mid != null ? nomesPorMembro.getOrDefault(mid, "Membro") : "Membro";
            return new CotaComMembro(c, nome);
        }).toList();
    }

    // salva ou atualiza o dado de geracao mensal da usina
    public void salvarOuAtualizarGeracao(String usinaId, String mesReferencia, double geracaoKwh) {
        Query query = new Query(Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id"))
                .and("mes_referencia").is(mesReferencia));
        Update update = new Update()
                .set("geracao_kwh", geracaoKwh)
                .set("data_lancamento", new Date());
        mongoTemplate.upsert(query, update, GeracaoMensal.class);
    }

    // salva ou atualiza o dado do credito do membro
    public void salvarOuAtualizarCredito(
            String usinaId,
            String membroId,
            String mesReferencia,
            double geracaoTotalKwh,
            double percentualCota,
            double creditosLiquidosKwh) {
        Query query = new Query(Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id"))
                .and("membro_id").is(idObjeto(membroId, "membro_id"))
                .and("mes_referencia").is(mesReferencia));
        Update update = new Update()
                .set("geracao_total_kwh", geracaoTotalKwh)
                .set("percentual_cota", percentualCota)
                .set("creditos_brutos_kwh", creditosLiquidosKwh)
                .set("perdas_transmissao_kwh", 0)
                .set("creditos_liquidos_kwh", creditosLiquidosKwh);
        mongoTemplate.upsert(query, update, Credito.class);
    }

    // criterio para buscar o mes no ano
    private Criteria mesNoAno(int ano) {
        return Criteria.where("mes_referencia").regex(
                Pattern.compile("^" + ano + "-"));
    }

    // converte string em ObjectId
    private ObjectId idObjeto(String valor, String nomeCampo) {
        if (valor == null || !ObjectId.isValid(valor)) {
            throw new IllegalArgumentException(nomeCampo + " invalido");
        }
        return new ObjectId(valor);
    }
}
