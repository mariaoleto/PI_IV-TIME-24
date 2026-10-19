package PIV.solis.Services;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import PIV.solis.Models.ConsumoMensal;
import PIV.solis.Models.Cota;
import PIV.solis.Models.Credito;
import PIV.solis.Models.GeracaoMensal;
import PIV.solis.Models.ResumoEnergia;
import PIV.solis.Repositories.EnergiaRepository;
import java.util.List;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

class EnergiaServiceTest {

    private static final String USINA_ID = "507f1f77bcf86cd799439011";
    private static final String MEMBRO_ID = "507f1f77bcf86cd799439012";

    @Test
    void calculaResumoAnualEDevolveNomesJsonCompatíveis() throws Exception {
        ObjectId usinaId = new ObjectId(USINA_ID);
        ObjectId membroId = new ObjectId(MEMBRO_ID);
        EnergiaRepository repositorio = new RepositorioFalso(
                new Cota(null, membroId, usinaId, 25.0, 0.4, null),
                List.of(
                        new GeracaoMensal(null, usinaId, "2026-01", 100.5, null),
                        new GeracaoMensal(null, usinaId, "2026-02", 200.0, null)),
                List.of(new Credito(null, membroId, usinaId, "2026-02",
                        null, null, 50.0, null, null)),
                List.of(
                        new ConsumoMensal(null, membroId, usinaId, "2026-01",
                                null, "5", null, null),
                        new ConsumoMensal(null, membroId, usinaId, "2026-02",
                                7.0, null, null, null)));

        ResumoEnergia resumo = new EnergiaService(repositorio)
                .montarResumoEnergia("2026", USINA_ID, MEMBRO_ID);

        assertEquals(2026, resumo.ano());
        assertEquals(300.5, resumo.totalGeracaoKwh());
        assertEquals(12.0, resumo.totalConsumoKwh());
        assertEquals(63.1, resumo.saldoAcumuladoKwh());
        assertEquals(25.25, resumo.economiaEstimadaReais());
        assertEquals(12, resumo.meses().size());
        assertEquals(20.1, resumo.meses().get(0).saldoMesKwh());
        assertEquals(43.0, resumo.meses().get(1).saldoMesKwh());

        String json = new ObjectMapper().writeValueAsString(resumo);
        assertTrue(json.contains("\"usina_id\":\"" + USINA_ID + "\""));
        assertTrue(json.contains("\"membro_id\":\"" + MEMBRO_ID + "\""));
        assertTrue(json.contains("\"mes_referencia\":\"2026-01\""));
        assertTrue(json.contains("\"economia_estimada_reais\":25.25"));
    }

    private static class RepositorioFalso extends EnergiaRepository {

        private final Cota cota;
        private final List<GeracaoMensal> geracoes;
        private final List<Credito> creditos;
        private final List<ConsumoMensal> consumos;

        RepositorioFalso(
                Cota cota,
                List<GeracaoMensal> geracoes,
                List<Credito> creditos,
                List<ConsumoMensal> consumos) {
            super(null);
            this.cota = cota;
            this.geracoes = geracoes;
            this.creditos = creditos;
            this.consumos = consumos;
        }

        @Override
        public Cota buscarCotaMaisRecente(String usinaId, String membroId) {
            return cota;
        }

        @Override
        public List<GeracaoMensal> buscarGeracoesMensais(int ano, String usinaId) {
            return geracoes;
        }

        @Override
        public List<Credito> buscarCreditosMensais(int ano, String usinaId, String membroId) {
            return creditos;
        }

        @Override
        public List<ConsumoMensal> buscarConsumosMensais(int ano, String usinaId, String membroId) {
            return consumos;
        }
    }
}
