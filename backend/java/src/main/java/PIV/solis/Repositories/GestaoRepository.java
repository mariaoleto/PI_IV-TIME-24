// Autora: Marina Hehnes Espósito.
// Propósito: persiste e consulta os dados associados à gestão de usinas.
package PIV.solis.Repositories;

import PIV.solis.Models.ContratoUsina;
import PIV.solis.Models.ConsumoMensal;
import PIV.solis.Models.Cota;
import PIV.solis.Models.CotaComMembro;
import PIV.solis.Models.Credito;
import PIV.solis.Models.GeracaoMensal;
import PIV.solis.Models.Membro;
import PIV.solis.Models.Usina;
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
import org.springframework.stereotype.Repository;

@Repository
public class GestaoRepository {

    private final MongoTemplate mongoTemplate;

    public GestaoRepository(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    public List<Usina> listarUsinas() {
        return mongoTemplate.findAll(Usina.class);
    }

    public Usina buscarUsina(String id) {
        return mongoTemplate.findById(idObjeto(id, "usina_id"), Usina.class);
    }

    public Usina salvarUsina(Usina usina) {
        return mongoTemplate.save(usina);
    }

    public void excluirUsina(Usina usina) {
        mongoTemplate.remove(usina);
    }

    public boolean possuiDadosVinculados(ObjectId usinaId) {
        Query porUsina = new Query(Criteria.where("usina_id").is(usinaId));
        return mongoTemplate.exists(porUsina, Cota.class)
                || mongoTemplate.exists(porUsina, GeracaoMensal.class)
                || mongoTemplate.exists(porUsina, Credito.class)
                || mongoTemplate.exists(porUsina, ConsumoMensal.class);
    }

    public boolean possuiMembrosVinculados(ObjectId usinaId) {
        Query porUsina = new Query(Criteria.where("usina_id").is(usinaId));
        return mongoTemplate.exists(porUsina, Membro.class);
    }

    public List<Membro> listarMembros(String usinaId) {
        ObjectId idUsina = idObjeto(usinaId, "usina_id");
        List<ObjectId> membrosDasCotas = listarCotas(usinaId).stream()
                .map(Cota::membroId)
                .filter(Objects::nonNull)
                .toList();
        Criteria filtro = membrosDasCotas.isEmpty()
                ? Criteria.where("usina_id").is(idUsina)
                : new Criteria().orOperator(
                        Criteria.where("usina_id").is(idUsina),
                        Criteria.where("_id").in(membrosDasCotas));
        Query consulta = new Query(filtro);
        consulta.with(Sort.by(Sort.Order.asc("nome")));
        return mongoTemplate.find(consulta, Membro.class);
    }

    public Membro buscarMembroPorEmail(String email) {
        Query consulta = new Query(Criteria.where("email")
                .regex("^" + Pattern.quote(email) + "$", "i"));
        return mongoTemplate.findOne(consulta, Membro.class);
    }

    public Membro salvarMembro(Membro membro) {
        return mongoTemplate.save(membro);
    }

    public List<Cota> listarCotas(String usinaId) {
        Query consulta = new Query(
                Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id")));
        consulta.with(Sort.by(Sort.Order.desc("percentual"), Sort.Order.desc("data_inicio")));
        return mongoTemplate.find(consulta, Cota.class);
    }

    public Cota buscarCotaMaisRecente(String usinaId, String membroId) {
        Query consulta = new Query(
                Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id"))
                        .and("membro_id").is(idObjeto(membroId, "membro_id")));
        consulta.with(Sort.by(Sort.Order.desc("percentual"), Sort.Order.desc("data_inicio")));
        return mongoTemplate.findOne(consulta, Cota.class);
    }

    public Cota salvarCota(Cota cota) {
        return mongoTemplate.save(cota);
    }

    public List<Cota> buscarCotasDosMembros(String usinaId, List<Membro> membros) {
        if (membros.isEmpty()) {
            return List.of();
        }
        List<ObjectId> membrosIds = membros.stream()
                .map(Membro::id)
                .filter(Objects::nonNull)
                .toList();
        if (membrosIds.isEmpty()) {
            return List.of();
        }
        Query consulta = new Query(
                Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id"))
                        .and("membro_id").in(membrosIds));
        consulta.with(Sort.by(Sort.Order.desc("percentual"), Sort.Order.desc("data_inicio")));
        return mongoTemplate.find(consulta, Cota.class);
    }

    public List<CotaComMembro> listarCotasComMembros(String usinaId) {
        List<Cota> cotas = listarCotas(usinaId);
        List<ObjectId> membrosIds = cotas.stream()
                .map(Cota::membroId)
                .filter(Objects::nonNull)
                .distinct()
                .toList();
        Map<String, String> nomesPorMembro = new HashMap<>();
        if (!membrosIds.isEmpty()) {
            List<Membro> membros = mongoTemplate.find(
                    new Query(Criteria.where("_id").in(membrosIds)),
                    Membro.class);
            for (Membro membro : membros) {
                if (membro.id() != null) {
                    nomesPorMembro.put(
                            membro.id().toHexString(),
                            membro.nome() == null ? "Membro" : membro.nome());
                }
            }
        }
        return cotas.stream()
                .map(cota -> new CotaComMembro(
                        cota,
                        cota.membroId() == null
                                ? "Membro"
                                : nomesPorMembro.getOrDefault(
                                        cota.membroId().toHexString(),
                                        "Membro")))
                .toList();
    }

    public ContratoUsina buscarContrato(String usinaId) {
        Query consulta = new Query(Criteria.where("usina_id").is(idObjeto(usinaId, "usina_id")));
        return mongoTemplate.findOne(consulta, ContratoUsina.class);
    }

    public ContratoUsina salvarContrato(ContratoUsina contrato) {
        return mongoTemplate.save(contrato);
    }

    public void excluirContrato(ContratoUsina contrato) {
        mongoTemplate.remove(contrato);
    }

    private ObjectId idObjeto(String valor, String nomeCampo) {
        if (valor == null || !ObjectId.isValid(valor)) {
            throw new IllegalArgumentException(nomeCampo + " inválido.");
        }
        return new ObjectId(valor);
    }
}
