package PIV.solis.Controllers;

import PIV.solis.Models.ResumoEnergia;
import PIV.solis.Services.EnergiaService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class EnergiaController {

    private final EnergiaService energiaService;

    public EnergiaController(EnergiaService energiaService) {
        this.energiaService = energiaService;
    }

    @GetMapping("/energia")
    public ResumoEnergia buscarResumoEnergia(
            @RequestParam(required = false) String ano,
            @RequestParam(name = "usina_id", required = false) String usinaId,
            @RequestParam(name = "membro_id", required = false) String membroId) {
        return energiaService.montarResumoEnergia(ano, usinaId, membroId);
    }
}
