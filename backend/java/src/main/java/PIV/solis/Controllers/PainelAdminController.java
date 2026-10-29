//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// endpoint agregador do painel administrativo
// reúne em uma chamada os dados da usina, das cotas e do registro mensal

package PIV.solis.Controllers;

import PIV.solis.Models.PainelAdminDTO;
import PIV.solis.Services.PainelAdminService;
import java.util.NoSuchElementException;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/admin")
public class PainelAdminController {

    private final PainelAdminService painelAdminService;

    public PainelAdminController(PainelAdminService painelAdminService) {
        this.painelAdminService = painelAdminService;
    }

    // retorna o painel da usina (usina_id opcional: usa a primeira usina ativa)
    @GetMapping("/painel")
    public PainelAdminDTO buscarPainel(@RequestParam(name = "usina_id", required = false) String usinaId) {
        try {
            return painelAdminService.montarPainel(usinaId);
        } catch (IllegalArgumentException erro) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, erro.getMessage());
        } catch (NoSuchElementException erro) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, erro.getMessage());
        }
    }
}
