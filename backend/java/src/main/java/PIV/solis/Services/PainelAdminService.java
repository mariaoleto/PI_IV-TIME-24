//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// regras de negócio do painel administrativo
// agrega dados da usina, das cotas e do registro mensal (geração, créditos e consumo)

package PIV.solis.Services;

import PIV.solis.Models.ConsumoMensal;
import PIV.solis.Models.Cota;
import PIV.solis.Models.Credito;
import PIV.solis.Models.GeracaoMensal;
import PIV.solis.Models.PainelAdminDTO;
import PIV.solis.Models.PainelAdminDTO.AlertaDTO;
import PIV.solis.Models.PainelAdminDTO.MembrosDTO;
import PIV.solis.Models.PainelAdminDTO.ProximoLancamentoDTO;
import PIV.solis.Models.PainelAdminDTO.ResumoMesDTO;
import PIV.solis.Models.PainelAdminDTO.UsinaDTO;
import PIV.solis.Models.Usina;
import PIV.solis.Repositories.PainelAdminRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.TreeMap;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class PainelAdminService {

    static final ZoneId FUSO = ZoneId.of("America/Sao_Paulo");

    // horas de sol pleno equivalentes por dia, usadas para estimar a geração esperada
    // quando a usina só informa a capacidade instalada (kWp)
    static final double HORAS_SOL_DIA = 4.0;

    // geração abaixo de 80% da média dos meses anteriores gera alerta de queda
    static final double LIMITE_QUEDA_GERACAO = 0.8;

    // tolerância para comparar a soma das cotas com 100%
    static final double TOLERANCIA_PERCENTUAL = 0.01;

    private static final List<String> NOMES_MESES = List.of(
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro");

    private final PainelAdminRepository repositorio;
    private final Clock relogio;

    @Autowired
    public PainelAdminService(PainelAdminRepository repositorio) {
        this(repositorio, Clock.system(FUSO));
    }

    PainelAdminService(PainelAdminRepository repositorio, Clock relogio) {
        this.repositorio = repositorio;
        this.relogio = relogio;
    }

    // monta o painel da usina informada ou, se não informada, da primeira usina ativa
    public PainelAdminDTO montarPainel(String usinaIdSolicitada) {
        Usina usina;
        String usinaId;
        if (usinaIdSolicitada != null && !usinaIdSolicitada.isBlank()) {
            usinaId = usinaIdSolicitada.trim();
            usina = repositorio.buscarUsina(usinaId);
        } else {
            usina = repositorio.buscarUsinaAtiva();
            usinaId = usina != null && usina.id() != null
                    ? usina.id().toHexString()
                    : repositorio.buscarUsinaIdPelasCotas();
            if (usinaId == null) {
                throw new NoSuchElementException("Nenhuma usina cadastrada.");
            }
        }

        List<Cota> cotas = repositorio.listarCotas(usinaId);
        List<GeracaoMensal> geracoes = repositorio.listarGeracoes(usinaId);
        if (usina == null && cotas.isEmpty() && geracoes.isEmpty()) {
            throw new NoSuchElementException("Usina não encontrada.");
        }

        YearMonth mesAtual = YearMonth.from(LocalDate.now(relogio));
        TreeMap<YearMonth, Double> geracaoPorMes = indexarGeracao(geracoes);

        // cotas
        MembrosDTO membros = resumirMembros(cotas);

        // mês exibido: o corrente, se já tiver registro; senão o último registrado
        YearMonth mesRef = geracaoPorMes.containsKey(mesAtual)
                ? mesAtual
                : geracaoPorMes.isEmpty() ? mesAtual : geracaoPorMes.lastKey();
        ResumoMesDTO resumoMes = montarResumoMes(usina, mesRef, geracaoPorMes);

        ProximoLancamentoDTO proximo = calcularProximoLancamento(geracaoPorMes, mesAtual);

        List<AlertaDTO> alertas = new ArrayList<>();
        montarAlertas(alertas, usinaId, cotas, membros, resumoMes, mesRef, geracaoPorMes, proximo);

        return new PainelAdminDTO(
                montarUsina(usina, usinaId),
                resumoMes,
                membros,
                alertas,
                proximo);
    }

    // ---------- usina ----------

    private UsinaDTO montarUsina(Usina usina, String usinaId) {
        if (usina == null) {
            return new UsinaDTO(usinaId, null, null, null, true);
        }
        double capacidade = paraNumero(usina.capacidadeKwp());
        return new UsinaDTO(
                usinaId,
                usina.nome(),
                usina.localizacao(),
                capacidade > 0 ? capacidade : null,
                usina.ativa() == null || usina.ativa());
    }

    // ---------- cotas ----------

    private MembrosDTO resumirMembros(List<Cota> cotas) {
        Set<String> ativos = new HashSet<>();
        double soma = 0;
        for (Cota cota : cotas) {
            double percentual = paraNumero(cota.percentual());
            if (percentual > 0 && cota.membroId() != null) {
                ativos.add(cota.membroId().toHexString());
                soma += percentual;
            }
        }
        double disponivel = Math.max(0, 100 - soma);
        return new MembrosDTO(ativos.size(), arredondar(soma, 2), arredondar(disponivel, 2));
    }

    // ---------- registro mensal ----------

    private TreeMap<YearMonth, Double> indexarGeracao(List<GeracaoMensal> geracoes) {
        TreeMap<YearMonth, Double> mapa = new TreeMap<>();
        for (GeracaoMensal g : geracoes) {
            YearMonth mes = lerMes(g.mesReferencia());
            if (mes != null) {
                mapa.put(mes, paraNumero(g.geracaoKwh()));
            }
        }
        return mapa;
    }

    private ResumoMesDTO montarResumoMes(Usina usina, YearMonth mesRef, TreeMap<YearMonth, Double> geracaoPorMes) {
        boolean registrado = geracaoPorMes.containsKey(mesRef);
        double geracao = registrado ? geracaoPorMes.get(mesRef) : 0;

        Double anterior = geracaoPorMes.get(mesRef.minusMonths(1));
        Double variacao = registrado && anterior != null && anterior > 0
                ? arredondar((geracao - anterior) / anterior * 100, 1)
                : null;

        Double eficiencia = null;
        String base = null;
        if (registrado) {
            double esperado = geracaoEsperada(usina, mesRef);
            if (esperado > 0) {
                eficiencia = arredondar(geracao / esperado * 100, 1);
                base = "capacidade";
            } else {
                double media = mediaAnteriores(geracaoPorMes, mesRef);
                if (media > 0) {
                    eficiencia = arredondar(geracao / media * 100, 1);
                    base = "historico";
                }
            }
        }

        return new ResumoMesDTO(
                formatarMes(mesRef),
                rotulo(mesRef),
                registrado,
                arredondar(geracao, 1),
                anterior == null ? null : arredondar(anterior, 1),
                variacao,
                eficiencia,
                base);
    }

    // geração esperada no mês: valor informado na usina ou estimativa pela capacidade instalada
    private double geracaoEsperada(Usina usina, YearMonth mes) {
        if (usina == null) {
            return 0;
        }
        double informada = paraNumero(usina.geracaoEsperadaKwhMes());
        if (informada > 0) {
            return informada;
        }
        double capacidade = paraNumero(usina.capacidadeKwp());
        return capacidade > 0 ? capacidade * HORAS_SOL_DIA * mes.lengthOfMonth() : 0;
    }

    private double mediaAnteriores(TreeMap<YearMonth, Double> geracaoPorMes, YearMonth mesRef) {
        double soma = 0;
        int quantidade = 0;
        for (Double valor : geracaoPorMes.headMap(mesRef).values()) {
            if (valor > 0) {
                soma += valor;
                quantidade++;
            }
        }
        return quantidade == 0 ? 0 : soma / quantidade;
    }

    // o próximo lançamento é o mês mais antigo sem registro entre o primeiro registro e o mês atual;
    // se tudo estiver em dia, é o mês seguinte ao atual
    private ProximoLancamentoDTO calcularProximoLancamento(TreeMap<YearMonth, Double> geracaoPorMes,
            YearMonth mesAtual) {
        if (geracaoPorMes.isEmpty()) {
            return new ProximoLancamentoDTO(formatarMes(mesAtual), rotulo(mesAtual), "pendente", 0, null);
        }
        YearMonth primeiroPendente = null;
        int emAtraso = 0;
        for (YearMonth m = geracaoPorMes.firstKey(); !m.isAfter(mesAtual); m = m.plusMonths(1)) {
            if (!geracaoPorMes.containsKey(m)) {
                if (primeiroPendente == null) {
                    primeiroPendente = m;
                }
                if (m.isBefore(mesAtual)) {
                    emAtraso++;
                }
            }
        }
        if (primeiroPendente == null) {
            YearMonth proximo = mesAtual.plusMonths(1);
            return new ProximoLancamentoDTO(
                    formatarMes(proximo), rotulo(proximo), "em_dia", 0, proximo.atDay(1).toString());
        }
        String status = primeiroPendente.isBefore(mesAtual) ? "atrasado" : "pendente";
        return new ProximoLancamentoDTO(
                formatarMes(primeiroPendente), rotulo(primeiroPendente), status, emAtraso, null);
    }

    // ---------- alertas ----------

    private void montarAlertas(List<AlertaDTO> alertas, String usinaId, List<Cota> cotas, MembrosDTO membros,
            ResumoMesDTO resumoMes, YearMonth mesRef, TreeMap<YearMonth, Double> geracaoPorMes,
            ProximoLancamentoDTO proximo) {

        if (membros.ativos() == 0) {
            alertas.add(new AlertaDTO("SEM_COTAS", "erro", "Nenhuma cota cadastrada",
                    "Cadastre as cotas dos membros para distribuir os créditos da usina."));
        } else if (membros.somaPercentualCotas() > 100 + TOLERANCIA_PERCENTUAL) {
            alertas.add(new AlertaDTO("COTAS_EXCEDIDAS", "erro", "Cotas acima de 100%",
                    "A soma das cotas é %s%%. Ajuste as cotas para que não ultrapassem 100%%."
                            .formatted(formatarNumero(membros.somaPercentualCotas()))));
        } else if (membros.somaPercentualCotas() < 100 - TOLERANCIA_PERCENTUAL) {
            alertas.add(new AlertaDTO("COTAS_INCOMPLETAS", "aviso", "Cotas abaixo de 100%",
                    "%s%% da usina ainda não foram distribuídos entre os membros."
                            .formatted(formatarNumero(membros.percentualDisponivel()))));
        }

        if ("atrasado".equals(proximo.status())) {
            int n = proximo.mesesEmAtraso();
            alertas.add(new AlertaDTO("LANCAMENTO_ATRASADO", "aviso", "Lançamento em atraso",
                    n == 1
                            ? "O registro de %s ainda não foi lançado.".formatted(proximo.rotulo())
                            : "%d meses sem registro de geração, a partir de %s.".formatted(n, proximo.rotulo())));
        }

        if (resumoMes.registrado()) {
            double media = mediaAnteriores(geracaoPorMes, mesRef);
            if (media > 0 && resumoMes.geracaoKwh() < media * LIMITE_QUEDA_GERACAO) {
                double queda = (1 - resumoMes.geracaoKwh() / media) * 100;
                alertas.add(new AlertaDTO("QUEDA_GERACAO", "aviso", "Queda na geração",
                        "A geração de %s está %s%% abaixo da média dos meses anteriores."
                                .formatted(resumoMes.rotulo(), formatarNumero(arredondar(queda, 0)))));
            }

            int acima = contarMembrosConsumoAcimaDosCreditos(usinaId, cotas, resumoMes);
            if (acima > 0) {
                alertas.add(new AlertaDTO("CONSUMO_ACIMA_CREDITOS", "aviso", "Consumo acima dos créditos",
                        acima == 1
                                ? "1 membro consumiu mais do que os créditos de %s.".formatted(resumoMes.rotulo())
                                : "%d membros consumiram mais do que os créditos de %s."
                                        .formatted(acima, resumoMes.rotulo())));
            }
        }

        alertas.sort((a, b) -> Integer.compare(pesoSeveridade(a.severidade()), pesoSeveridade(b.severidade())));
    }

    private int pesoSeveridade(String severidade) {
        return switch (severidade) {
            case "erro" -> 0;
            case "aviso" -> 1;
            default -> 2;
        };
    }

    // compara, por membro, o consumo do mês com os créditos recebidos
    // (usa os créditos já distribuídos; se não houver, estima pela cota)
    private int contarMembrosConsumoAcimaDosCreditos(String usinaId, List<Cota> cotas, ResumoMesDTO resumoMes) {
        String mes = resumoMes.mesReferencia();
        List<ConsumoMensal> consumos = repositorio.listarConsumos(usinaId, mes);
        if (consumos.isEmpty()) {
            return 0;
        }

        Map<String, Double> consumoPorMembro = new HashMap<>();
        for (ConsumoMensal c : consumos) {
            if (c.membroId() != null) {
                consumoPorMembro.merge(c.membroId().toHexString(), lerConsumoKwh(c), Double::sum);
            }
        }

        Map<String, Double> creditoPorMembro = new HashMap<>();
        for (Credito c : repositorio.listarCreditos(usinaId, mes)) {
            if (c.membroId() != null) {
                double valor = paraNumero(c.creditosLiquidosKwh() != null
                        ? c.creditosLiquidosKwh()
                        : c.creditosBrutosKwh());
                creditoPorMembro.merge(c.membroId().toHexString(), valor, Double::sum);
            }
        }
        for (Cota cota : cotas) {
            if (cota.membroId() != null) {
                creditoPorMembro.putIfAbsent(cota.membroId().toHexString(),
                        resumoMes.geracaoKwh() * paraNumero(cota.percentual()) / 100);
            }
        }

        int acima = 0;
        for (Map.Entry<String, Double> e : consumoPorMembro.entrySet()) {
            double credito = creditoPorMembro.getOrDefault(e.getKey(), 0.0);
            if (e.getValue() > credito + 0.05) {
                acima++;
            }
        }
        return acima;
    }

    private double lerConsumoKwh(ConsumoMensal consumo) {
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
        return paraNumero(valor);
    }

    // ---------- utilitários ----------

    private double paraNumero(Object valor) {
        if (valor == null) {
            return 0;
        }
        try {
            double numero = valor instanceof Number n
                    ? n.doubleValue()
                    : valor.toString().trim().isEmpty() ? 0 : Double.parseDouble(valor.toString().trim());
            return Double.isFinite(numero) ? numero : 0;
        } catch (NumberFormatException erro) {
            return 0;
        }
    }

    private double arredondar(double valor, int casas) {
        return BigDecimal.valueOf(valor).setScale(casas, RoundingMode.HALF_UP).doubleValue();
    }

    // 25.0 -> "25"; 12.5 -> "12,5"
    private String formatarNumero(double valor) {
        return valor == Math.rint(valor)
                ? String.valueOf((long) valor)
                : String.valueOf(valor).replace('.', ',');
    }

    private YearMonth lerMes(String referencia) {
        try {
            return referencia == null ? null : YearMonth.parse(referencia.trim());
        } catch (Exception erro) {
            return null;
        }
    }

    private String formatarMes(YearMonth mes) {
        return mes.toString(); // AAAA-MM
    }

    private String rotulo(YearMonth mes) {
        return NOMES_MESES.get(mes.getMonthValue() - 1) + "/" + mes.getYear();
    }
}
