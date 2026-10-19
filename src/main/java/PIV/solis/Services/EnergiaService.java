package PIV.solis.Services;

import PIV.solis.Models.ConsumoMensal;
import PIV.solis.Models.Cota;
import PIV.solis.Models.Credito;
import PIV.solis.Models.GeracaoMensal;
import PIV.solis.Models.MesEnergia;
import PIV.solis.Models.ResumoEnergia;
import PIV.solis.Repositories.EnergiaRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Year;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class EnergiaService {

    private static final List<String> ROTULOS_MESES = List.of(
            "Jan", "Fev", "Mar", "Abr", "Mai", "Jun",
            "Jul", "Ago", "Set", "Out", "Nov", "Dez");

    private final EnergiaRepository energiaRepository;

    public EnergiaService(EnergiaRepository energiaRepository) {
        this.energiaRepository = energiaRepository;
    }

    public ResumoEnergia montarResumoEnergia(String anoSolicitado, String usinaIdSolicitada, String membroIdSolicitado) {
        int ano = paraAno(anoSolicitado);
        Cota cota = energiaRepository.buscarCotaMaisRecente(usinaIdSolicitada, membroIdSolicitado);

        String usinaId = usinaIdSolicitada != null
                ? usinaIdSolicitada
                : cota != null && cota.usinaId() != null ? cota.usinaId().toHexString() : null;
        String membroId = membroIdSolicitado != null
                ? membroIdSolicitado
                : cota != null && cota.membroId() != null ? cota.membroId().toHexString() : null;

        if (usinaId == null) {
            throw new IllegalArgumentException("Nenhuma usina encontrada para montar o resumo.");
        }

        List<GeracaoMensal> geracoes = energiaRepository.buscarGeracoesMensais(ano, usinaId);
        List<Credito> creditos = membroId == null
                ? List.of()
                : energiaRepository.buscarCreditosMensais(ano, usinaId, membroId);
        List<ConsumoMensal> consumos = membroId == null
                ? List.of()
                : energiaRepository.buscarConsumosMensais(ano, usinaId, membroId);

        Map<String, GeracaoMensal> geracaoPorMes = indexarPorMes(geracoes, GeracaoMensal::mesReferencia);
        Map<String, Credito> creditoPorMes = indexarPorMes(creditos, Credito::mesReferencia);
        Map<String, ConsumoMensal> consumoPorMes = indexarPorMes(consumos, ConsumoMensal::mesReferencia);

        double percentualCota = paraNumero(cota == null ? null : cota.percentual(), 0);
        double tarifaKwh = paraNumero(cota == null ? null : cota.tarifaKwh(), 0);
        double totalConsumoKwh = 0;
        double totalGeracaoKwh = 0;
        double saldoAcumuladoKwh = 0;
        List<MesEnergia> meses = new ArrayList<>(ROTULOS_MESES.size());

        for (int indice = 0; indice < ROTULOS_MESES.size(); indice++) {
            String referencia = chaveMes(ano, indice);
            GeracaoMensal geracao = geracaoPorMes.get(referencia);
            Credito credito = creditoPorMes.get(referencia);
            ConsumoMensal consumo = consumoPorMes.get(referencia);
            double geracaoKwh = paraNumero(geracao == null ? null : geracao.geracaoKwh(), 0);

            double creditoCalculado = percentualCota > 0
                    ? geracaoKwh * (percentualCota / 100)
                    : 0;
            double creditosLiquidosKwh = paraNumero(
                    credito == null ? null : credito.creditosLiquidosKwh(),
                    paraNumero(credito == null ? null : credito.creditosBrutosKwh(), creditoCalculado));

            double consumoKwh = lerConsumoKwh(consumo);
            double saldoMesKwh = creditosLiquidosKwh - consumoKwh;
            totalGeracaoKwh += geracaoKwh;
            totalConsumoKwh += consumoKwh;
            saldoAcumuladoKwh += saldoMesKwh;

            meses.add(new MesEnergia(
                    ROTULOS_MESES.get(indice),
                    referencia,
                    geracaoKwh,
                    arredondar(creditosLiquidosKwh, 1),
                    consumoKwh,
                    arredondar(saldoMesKwh, 1)));
        }

        return new ResumoEnergia(
                ano,
                usinaId,
                membroId,
                percentualCota,
                tarifaKwh,
                arredondar(totalGeracaoKwh, 1),
                arredondar(totalConsumoKwh, 1),
                arredondar(saldoAcumuladoKwh, 1),
                arredondar(saldoAcumuladoKwh * tarifaKwh, 2),
                meses);
    }

    private double lerConsumoKwh(ConsumoMensal consumo) {
        if (consumo == null) {
            return 0;
        }
        Object valor = consumo.consumoKwh();
        if (valor == null) {
            valor = consumo.consumoTotalKwh();
        }
        if (valor == null) {
            valor = consumo.totalConsumoKwh();
        }
        if (valor == null) {
            valor = consumo.kwh();
        }
        return paraNumero(valor, 0);
    }

    private <T> Map<String, T> indexarPorMes(List<T> documentos, java.util.function.Function<T, String> obterMes) {
        Map<String, T> documentosPorMes = new HashMap<>();
        for (T documento : documentos) {
            String mes = obterMes.apply(documento);
            if (mes != null) {
                documentosPorMes.put(mes, documento);
            }
        }
        return documentosPorMes;
    }

    private int paraAno(String valor) {
        if (valor == null) {
            return Year.now().getValue();
        }
        try {
            String numeroTexto = valor.trim();
            double numero = numeroTexto.isEmpty() ? 0 : Double.parseDouble(numeroTexto);
            return Double.isFinite(numero) ? (int) numero : Year.now().getValue();
        } catch (NumberFormatException erro) {
            return Year.now().getValue();
        }
    }

    private double paraNumero(Object valor, double padrao) {
        if (valor == null) {
            return padrao;
        }
        try {
            double numero = valor instanceof Number
                    ? ((Number) valor).doubleValue()
                    : valor.toString().trim().isEmpty() ? 0 : Double.parseDouble(valor.toString().trim());
            return Double.isFinite(numero) ? numero : padrao;
        } catch (NumberFormatException erro) {
            return padrao;
        }
    }

    private String chaveMes(int ano, int indiceMes) {
        return "%d-%02d".formatted(ano, indiceMes + 1);
    }

    private double arredondar(double valor, int casasDecimais) {
        return BigDecimal.valueOf(valor)
                .setScale(casasDecimais, RoundingMode.HALF_UP)
                .doubleValue();
    }
}
