// Autora: Marina Hehnes Espósito.
// Propósito: verifica as regras de negócio da gestão de usinas, membros, cotas e contratos.
package PIV.solis.Services;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import PIV.solis.Models.ContratoUsina;
import PIV.solis.Models.AtualizarCotasRequest;
import PIV.solis.Models.Cota;
import PIV.solis.Models.CotaAtualizacaoDTO;
import PIV.solis.Models.Membro;
import PIV.solis.Models.MembroRequest;
import PIV.solis.Models.Usina;
import PIV.solis.Models.UsinaRequest;
import PIV.solis.Repositories.GestaoRepository;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Year;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;
import org.bson.types.ObjectId;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class GestaoServiceTest {

    private static final String USINA_ID = "507f1f77bcf86cd799439011";
    private static final String MEMBRO_1_ID = "507f1f77bcf86cd799439012";
    private static final String MEMBRO_2_ID = "507f1f77bcf86cd799439013";

    @Mock
    private GestaoRepository gestaoRepository;

    @TempDir
    Path diretorioTemporario;

    private GestaoService service;

    @BeforeEach
    void configurarServico() {
        service = new GestaoService(
                gestaoRepository,
                diretorioTemporario.toString());
    }

    @Test
    void criaUsinaComCodigoEId() {
        when(gestaoRepository.listarUsinas()).thenReturn(List.of());
        when(gestaoRepository.salvarUsina(any(Usina.class)))
                .thenAnswer(invocacao -> invocacao.getArgument(0));

        var resultado = service.criarUsina(
                new UsinaRequest(" Solis Norte ", 42.0, " Enel ", " Campinas, SP "));

        assertTrue(ObjectId.isValid(resultado.id()));
        assertEquals("Solis Norte", resultado.nome());
        assertEquals("Enel", resultado.distribuidora());
        assertEquals("Campinas, SP", resultado.local());
        assertEquals("USN-" + Year.now().getValue() + "-001", resultado.codigo());
    }

    @Test
    void naoPermiteExcluirUsinaComDadosVinculados() {
        when(gestaoRepository.buscarUsina(USINA_ID)).thenReturn(usina());
        when(gestaoRepository.possuiDadosVinculados(new ObjectId(USINA_ID))).thenReturn(true);

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> service.excluirUsina(USINA_ID));

        assertEquals(HttpStatus.CONFLICT, erro.getStatusCode());
        verify(gestaoRepository, never()).excluirUsina(any(Usina.class));
    }

    @Test
    void adicionaMembroPendenteAUsina() {
        when(gestaoRepository.buscarUsina(USINA_ID)).thenReturn(usina());
        when(gestaoRepository.buscarMembroPorEmail("novo@email.com")).thenReturn(null);
        when(gestaoRepository.salvarMembro(any(Membro.class)))
                .thenAnswer(invocacao -> invocacao.getArgument(0));

        var resultado = service.adicionarMembro(
                new MembroRequest("Novo membro", "novo@email.com", USINA_ID));

        assertEquals("Novo membro", resultado.nome());
        assertEquals("novo@email.com", resultado.email());
        assertEquals("Pendente", resultado.status());
        assertEquals(0, resultado.cota());
    }

    @Test
    void rejeitaCotasAcimaDeCemPorCentoSemSalvar() {
        when(gestaoRepository.buscarUsina(USINA_ID)).thenReturn(usina());
        when(gestaoRepository.listarMembros(USINA_ID)).thenReturn(List.of(
                membro(MEMBRO_1_ID, "Ana"),
                membro(MEMBRO_2_ID, "Bia")));
        var dados = new AtualizarCotasRequest(List.of(
                new CotaAtualizacaoDTO(MEMBRO_1_ID, 60.0),
                new CotaAtualizacaoDTO(MEMBRO_2_ID, 41.0)));

        ResponseStatusException erro = assertThrows(
                ResponseStatusException.class,
                () -> service.atualizarCotas(USINA_ID, dados));

        assertEquals(HttpStatus.BAD_REQUEST, erro.getStatusCode());
        verify(gestaoRepository, never()).salvarCota(any(Cota.class));
    }

    @Test
    void salvaPdfComNomeSeguroEPermiteBaixar() throws Exception {
        when(gestaoRepository.buscarUsina(USINA_ID)).thenReturn(usina());
        AtomicReference<ContratoUsina> contratoSalvo = new AtomicReference<>();
        when(gestaoRepository.buscarContrato(USINA_ID)).thenAnswer(invocacao -> contratoSalvo.get());
        when(gestaoRepository.salvarContrato(any())).thenAnswer(invocacao -> {
            ContratoUsina contrato = invocacao.getArgument(0);
            contratoSalvo.set(contrato);
            return contrato;
        });
        byte[] conteudo = "%PDF-1.4\nconteudo de teste".getBytes(StandardCharsets.UTF_8);
        var arquivo = new MockMultipartFile(
                "arquivo",
                "..\\contrato.pdf",
                "application/pdf",
                conteudo);

        var contrato = service.salvarContrato(USINA_ID, arquivo);

        assertEquals("contrato.pdf", contrato.nomeArquivo());
        assertEquals(conteudo.length, contrato.tamanhoBytes());
        Path caminho = service.caminhoArquivoContrato(USINA_ID);
        assertTrue(Files.isRegularFile(caminho));
        assertTrue(java.util.Arrays.equals(conteudo, Files.readAllBytes(caminho)));
    }

    @Test
    void rejeitaArquivoQueNaoContemAssinaturaPdf() {
        when(gestaoRepository.buscarUsina(USINA_ID)).thenReturn(usina());
        var arquivo = new MockMultipartFile(
                "arquivo",
                "contrato.pdf",
                "application/pdf",
                "conteudo falso".getBytes(StandardCharsets.UTF_8));

        assertThrows(ResponseStatusException.class, () -> service.salvarContrato(USINA_ID, arquivo));
    }

    private Usina usina() {
        return new Usina(new ObjectId(USINA_ID), "Solis Norte", 42.0, "Enel", "USN-2026-001", "Campinas, SP");
    }

    private Membro membro(String id, String nome) {
        return new Membro(
                new ObjectId(id),
                nome,
                nome.toLowerCase() + "@email.com",
                "membro",
                new ObjectId(USINA_ID),
                "Ativo");
    }
}
