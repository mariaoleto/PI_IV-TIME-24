// autora: Maria Júlia Lazarini Oleto
// significado do arquivo:
// recebe a requisicao HTTP, chama o service e devolve a resposta.

package PIV.solis.Controllers;

import PIV.solis.Models.CotaMembroDTO;
import PIV.solis.Models.LancamentoMensalDTO;
import PIV.solis.Models.RespostaLancamentoDTO;
import PIV.solis.Models.ResumoEnergia;
import PIV.solis.Services.EnergiaService;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/energia")
public class EnergiaController {

    private final EnergiaService energiaService;

    public EnergiaController(EnergiaService energiaService) {
        this.energiaService = energiaService;
    }

    // retorna o resumo anual de geração, consumo, créditos e economia do membro
    @GetMapping
    public ResumoEnergia buscarResumoEnergia(
            @RequestParam(required = false) String ano,
            @RequestParam(name = "usina_id", required = false) String usinaId,
            @RequestParam(name = "membro_id", required = false) String membroId) {
        return energiaService.montarResumoEnergia(ano, usinaId, membroId);
    }

    @GetMapping("/cotas")
    // busca as cotas de cada membro, para realizar a distribuição dos créditos
    public List<CotaMembroDTO> buscarCotasDistribuicao(
            @RequestParam(name = "usina_id", required = false) String usinaId,
            @RequestParam(name = "membro_id", required = false) String membroId) {
        return energiaService.listarCotasDistribuicao(usinaId, membroId);
    }

    // salva a geração mensal da usina e distribui os créditos para os membros
    @PostMapping("/lancamento")
    @ResponseStatus(HttpStatus.CREATED)
    public RespostaLancamentoDTO salvarLancamentoMensal(@RequestBody LancamentoMensalDTO dados) {
        if (dados.mesReferencia() == null || dados.mesReferencia().isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "O período de referência (mes_referencia) é obrigatório.");
        }
        if (dados.geracaoKwh() == null || dados.geracaoKwh() <= 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "A geração total da usina (geracao_kwh) deve ser maior que zero.");
        }
        return energiaService.registrarLancamentoMensal(
                dados.mesReferencia(),
                dados.geracaoKwh(),
                dados.usinaId());
    }
}
