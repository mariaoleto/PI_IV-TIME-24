// Autora: Marina Hehnes Espósito.
// Propósito: expõe os endpoints de gestão de usinas, membros, cotas e contratos.
package PIV.solis.Controllers;

import PIV.solis.Models.AtualizarCotasRequest;
import PIV.solis.Models.ContratoDTO;
import PIV.solis.Models.MembroGestaoDTO;
import PIV.solis.Models.MembroRequest;
import PIV.solis.Models.UsinaDTO;
import PIV.solis.Models.UsinaRequest;
import PIV.solis.Services.GestaoService;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/gestao")
public class GestaoController {

    private final GestaoService gestaoService;

    public GestaoController(GestaoService gestaoService) {
        this.gestaoService = gestaoService;
    }

    @GetMapping("/usinas")
    public List<UsinaDTO> listarUsinas() {
        return gestaoService.listarUsinas();
    }

    @PostMapping("/usinas")
    @ResponseStatus(HttpStatus.CREATED)
    public UsinaDTO criarUsina(@RequestBody UsinaRequest dados) {
        return gestaoService.criarUsina(dados);
    }

    @PutMapping("/usinas/{usinaId}")
    public UsinaDTO atualizarUsina(
            @PathVariable String usinaId,
            @RequestBody UsinaRequest dados) {
        return gestaoService.atualizarUsina(usinaId, dados);
    }

    @DeleteMapping("/usinas/{usinaId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void excluirUsina(@PathVariable String usinaId) {
        gestaoService.excluirUsina(usinaId);
    }

    @GetMapping("/membros")
    public List<MembroGestaoDTO> listarMembros(
            @RequestParam(name = "usina_id") String usinaId) {
        return gestaoService.listarMembros(usinaId);
    }

    @PostMapping("/membros")
    @ResponseStatus(HttpStatus.CREATED)
    public MembroGestaoDTO adicionarMembro(@RequestBody MembroRequest dados) {
        return gestaoService.adicionarMembro(dados);
    }

    @PutMapping("/usinas/{usinaId}/cotas")
    public List<MembroGestaoDTO> atualizarCotas(
            @PathVariable String usinaId,
            @RequestBody AtualizarCotasRequest dados) {
        return gestaoService.atualizarCotas(usinaId, dados);
    }

    @PostMapping("/usinas/{usinaId}/contrato")
    @ResponseStatus(HttpStatus.CREATED)
    public ContratoDTO salvarContrato(
            @PathVariable String usinaId,
            @RequestParam("arquivo") MultipartFile arquivo) {
        return gestaoService.salvarContrato(usinaId, arquivo);
    }

    @GetMapping("/usinas/{usinaId}/contrato")
    public ContratoDTO buscarContrato(@PathVariable String usinaId) {
        return gestaoService.buscarContrato(usinaId);
    }

    @GetMapping("/usinas/{usinaId}/contrato/arquivo")
    public ResponseEntity<Resource> baixarContrato(@PathVariable String usinaId) {
        Path caminho = gestaoService.caminhoArquivoContrato(usinaId);
        ContratoDTO contrato = gestaoService.buscarContrato(usinaId);
        try {
            FileSystemResource arquivo = new FileSystemResource(caminho);
            return ResponseEntity.ok()
                    .contentType(MediaType.APPLICATION_PDF)
                    .contentLength(Files.size(caminho))
                    .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment()
                            .filename(contrato.nomeArquivo())
                            .build()
                            .toString())
                    .body(arquivo);
        } catch (IOException erro) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Não foi possível preparar o download do contrato.",
                    erro);
        }
    }

    @DeleteMapping("/usinas/{usinaId}/contrato")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void excluirContrato(@PathVariable String usinaId) {
        gestaoService.excluirContrato(usinaId);
    }
}
