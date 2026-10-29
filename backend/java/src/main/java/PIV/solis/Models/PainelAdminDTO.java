//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo: resposta do endpoint agregador do painel administrativo (GET /admin/painel)
// reúne dados da usina, das cotas e do registro mensal em uma única chamada

package PIV.solis.Models;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record PainelAdminDTO(
                UsinaDTO usina,
                @JsonProperty("resumo_mes") ResumoMesDTO resumoMes,
                MembrosDTO membros,
                List<AlertaDTO> alertas,
                @JsonProperty("proximo_lancamento") ProximoLancamentoDTO proximoLancamento) {

        public record UsinaDTO(
                        String id,
                        String nome,
                        String localizacao,
                        @JsonProperty("capacidade_kwp") Double capacidadeKwp,
                        boolean ativa) {
        }

        // dados do mês exibido no card da usina ativa
        // eficienciaBase: "capacidade" (geração / esperada pela capacidade instalada)
        // ou "historico" (geração / média dos meses anteriores); null quando não há base de comparação
        public record ResumoMesDTO(
                        @JsonProperty("mes_referencia") String mesReferencia,
                        String rotulo,
                        boolean registrado,
                        @JsonProperty("geracao_kwh") double geracaoKwh,
                        @JsonProperty("geracao_mes_anterior_kwh") Double geracaoMesAnteriorKwh,
                        @JsonProperty("variacao_percentual") Double variacaoPercentual,
                        @JsonProperty("eficiencia_percentual") Double eficienciaPercentual,
                        @JsonProperty("eficiencia_base") String eficienciaBase) {
        }

        public record MembrosDTO(
                        int ativos,
                        @JsonProperty("soma_percentual_cotas") double somaPercentualCotas,
                        @JsonProperty("percentual_disponivel") double percentualDisponivel) {
        }

        // severidade: "erro" | "aviso" | "info"
        public record AlertaDTO(String tipo, String severidade, String titulo, String mensagem) {
        }

        // status: "atrasado" (mês já encerrado sem registro) | "pendente" (mês corrente) | "em_dia"
        public record ProximoLancamentoDTO(
                        @JsonProperty("mes_referencia") String mesReferencia,
                        String rotulo,
                        String status,
                        @JsonProperty("meses_em_atraso") int mesesEmAtraso,
                        @JsonProperty("data_abertura") String dataAbertura) {
        }
}
