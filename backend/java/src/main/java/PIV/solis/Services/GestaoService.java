// Autora: Marina Hehnes Espósito.
// Propósito: valida e executa as regras de negócio da gestão de usinas.
package PIV.solis.Services;

import PIV.solis.Models.ContratoDTO;
import PIV.solis.Models.ContratoUsina;
import PIV.solis.Models.AtualizarCotasRequest;
import PIV.solis.Models.Cota;
import PIV.solis.Models.CotaAtualizacaoDTO;
import PIV.solis.Models.Membro;
import PIV.solis.Models.MembroGestaoDTO;
import PIV.solis.Models.MembroRequest;
import PIV.solis.Models.Usina;
import PIV.solis.Models.UsinaDTO;
import PIV.solis.Models.UsinaRequest;
import PIV.solis.Repositories.GestaoRepository;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.time.Year;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;
import org.bson.types.ObjectId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

@Service
public class GestaoService {

    private static final long TAMANHO_MAXIMO_CONTRATO = 10 * 1024 * 1024;
    private static final double TARIFA_PADRAO = 0.69;

    private final GestaoRepository gestaoRepository;
    private final Path diretorioContratos;

    public GestaoService(
            GestaoRepository gestaoRepository,
            @Value("${solis.storage.contratos-dir:uploads/contratos}") String diretorioContratos) {
        this.gestaoRepository = gestaoRepository;
        this.diretorioContratos = Paths.get(diretorioContratos).toAbsolutePath().normalize();
    }

    public List<UsinaDTO> listarUsinas() {
        return gestaoRepository.listarUsinas().stream().map(UsinaDTO::new).toList();
    }

    public UsinaDTO criarUsina(UsinaRequest dados) {
        validarUsina(dados);
        Usina usina = new Usina(
                new ObjectId(),
                dados.nome().trim(),
                dados.potencia(),
                dados.distribuidora().trim(),
                gerarCodigoUsina(),
                textoOpcional(dados.local()));
        return new UsinaDTO(gestaoRepository.salvarUsina(usina));
    }

    public UsinaDTO atualizarUsina(String usinaId, UsinaRequest dados) {
        ObjectId id = idObjeto(usinaId, "usina_id");
        validarUsina(dados);
        Usina atual = buscarUsinaOuFalhar(usinaId);
        Usina atualizada = new Usina(
                id,
                dados.nome().trim(),
                dados.potencia(),
                dados.distribuidora().trim(),
                atual.codigo(),
                dados.local() == null ? atual.local() : textoOpcional(dados.local()));
        return new UsinaDTO(gestaoRepository.salvarUsina(atualizada));
    }

    public void excluirUsina(String usinaId) {
        ObjectId id = idObjeto(usinaId, "usina_id");
        Usina usina = buscarUsinaOuFalhar(usinaId);
        if (gestaoRepository.possuiDadosVinculados(id)
                || gestaoRepository.possuiMembrosVinculados(id)
                || gestaoRepository.buscarContrato(usinaId) != null) {
            throw falha(HttpStatus.CONFLICT,
                    "A usina possui membros, cotas, gerações ou contrato vinculados.");
        }
        gestaoRepository.excluirUsina(usina);
    }

    public List<MembroGestaoDTO> listarMembros(String usinaId) {
        buscarUsinaOuFalhar(usinaId);
        List<Membro> membros = gestaoRepository.listarMembros(usinaId);
        Map<String, Cota> cotasPorMembro = new HashMap<>();
        for (Cota cota : gestaoRepository.buscarCotasDosMembros(usinaId, membros)) {
            if (cota.membroId() != null) {
                cotasPorMembro.putIfAbsent(cota.membroId().toHexString(), cota);
            }
        }
        return membros.stream().map(membro -> {
            Cota cota = membro.id() == null
                    ? null
                    : cotasPorMembro.get(membro.id().toHexString());
            return new MembroGestaoDTO(
                    membro.id() == null ? null : membro.id().toHexString(),
                    membro.nome(),
                    membro.email(),
                    cota == null ? 0 : paraNumero(cota.percentual()),
                    membro.status() == null ? "Ativo" : membro.status());
        }).toList();
    }

    public MembroGestaoDTO adicionarMembro(MembroRequest dados) {
        validarMembro(dados);
        buscarUsinaOuFalhar(dados.usinaId());
        String email = dados.email().trim();
        if (gestaoRepository.buscarMembroPorEmail(email) != null) {
            throw falha(HttpStatus.CONFLICT, "Já existe um membro com este e-mail.");
        }
        Membro membro = gestaoRepository.salvarMembro(new Membro(
                new ObjectId(),
                dados.nome().trim(),
                email,
                "membro",
                idObjeto(dados.usinaId(), "usina_id"),
                "Pendente"));
        return new MembroGestaoDTO(
                membro.id().toHexString(),
                membro.nome(),
                membro.email(),
                0,
                membro.status());
    }

    public List<MembroGestaoDTO> atualizarCotas(
            String usinaId,
            AtualizarCotasRequest dados) {
        ObjectId idUsina = idObjeto(usinaId, "usina_id");
        buscarUsinaOuFalhar(usinaId);
        if (dados == null || dados.cotas() == null) {
            throw falha(HttpStatus.BAD_REQUEST, "A lista de cotas é obrigatória.");
        }

        List<Membro> membros = gestaoRepository.listarMembros(usinaId);
        Set<String> membrosDaUsina = new HashSet<>();
        for (Membro membro : membros) {
            if (membro.id() != null) {
                membrosDaUsina.add(membro.id().toHexString());
            }
        }
        Set<String> membrosAtualizados = new HashSet<>();
        double soma = 0;
        for (CotaAtualizacaoDTO cota : dados.cotas()) {
            if (cota == null || cota.membroId() == null
                    || !ObjectId.isValid(cota.membroId())
                    || cota.percentual() == null
                    || !Double.isFinite(cota.percentual())
                    || cota.percentual() < 0 || cota.percentual() > 100) {
                throw falha(
                        HttpStatus.BAD_REQUEST,
                        "Cada cota deve ter um membro válido e percentual entre 0 e 100.");
            }
            String membroId = new ObjectId(cota.membroId()).toHexString();
            if (!membrosAtualizados.add(membroId)) {
                throw falha(HttpStatus.BAD_REQUEST, "A lista contém membros duplicados.");
            }
            if (!membrosDaUsina.contains(membroId)) {
                throw falha(
                        HttpStatus.BAD_REQUEST,
                        "Todos os membros informados devem pertencer à usina.");
            }
            soma += cota.percentual();
        }
        if (!membrosAtualizados.equals(membrosDaUsina)) {
            throw falha(
                    HttpStatus.BAD_REQUEST,
                    "Informe a cota de todos os membros da usina.");
        }
        if (soma > 100) {
            throw falha(HttpStatus.BAD_REQUEST, "A soma das cotas não pode ultrapassar 100%.");
        }

        for (CotaAtualizacaoDTO atualizacao : dados.cotas()) {
            Cota atual = gestaoRepository.buscarCotaMaisRecente(
                    usinaId,
                    atualizacao.membroId());
            gestaoRepository.salvarCota(new Cota(
                    atual == null ? new ObjectId() : atual.id(),
                    idObjeto(atualizacao.membroId(), "membro_id"),
                    idUsina,
                    atualizacao.percentual(),
                    atual == null ? TARIFA_PADRAO : atual.tarifaKwh(),
                    atual == null ? new Date() : atual.dataInicio()));
        }
        return listarMembros(usinaId);
    }

    public ContratoDTO salvarContrato(String usinaId, MultipartFile arquivo) {
        buscarUsinaOuFalhar(usinaId);
        if (arquivo == null || arquivo.isEmpty()) {
            throw falha(HttpStatus.BAD_REQUEST, "Selecione um arquivo PDF.");
        }
        if (arquivo.getSize() > TAMANHO_MAXIMO_CONTRATO) {
            throw falha(HttpStatus.PAYLOAD_TOO_LARGE, "O arquivo PDF deve ter no máximo 10 MB.");
        }
        String nomeArquivo = nomeSeguro(arquivo.getOriginalFilename());
        if (!nomeArquivo.toLowerCase().endsWith(".pdf")) {
            throw falha(HttpStatus.BAD_REQUEST, "O contrato deve estar no formato PDF.");
        }

        byte[] conteudo;
        try {
            conteudo = arquivo.getBytes();
        } catch (IOException erro) {
            throw falha(HttpStatus.INTERNAL_SERVER_ERROR, "Não foi possível ler o arquivo enviado.");
        }
        if (!ehPdf(conteudo)) {
            throw falha(HttpStatus.BAD_REQUEST, "O conteúdo enviado não é um arquivo PDF válido.");
        }

        ContratoUsina atual = gestaoRepository.buscarContrato(usinaId);
        String arquivoArmazenado = UUID.randomUUID() + ".pdf";
        Path destino = diretorioContratos.resolve(arquivoArmazenado).normalize();
        if (!destino.startsWith(diretorioContratos)) {
            throw falha(HttpStatus.INTERNAL_SERVER_ERROR, "Diretório de contratos inválido.");
        }
        try {
            Files.createDirectories(diretorioContratos);
            Files.write(destino, conteudo, StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE);
        } catch (IOException erro) {
            throw falha(HttpStatus.INTERNAL_SERVER_ERROR, "Não foi possível armazenar o contrato.");
        }

        ContratoUsina contrato = new ContratoUsina(
                atual == null ? new ObjectId() : atual.id(),
                idObjeto(usinaId, "usina_id"),
                nomeArquivo,
                arquivoArmazenado,
                conteudo.length,
                new Date());
        try {
            gestaoRepository.salvarContrato(contrato);
        } catch (RuntimeException erro) {
            removerArquivo(destino);
            throw erro;
        }
        if (atual != null) {
            removerArquivo(diretorioContratos.resolve(atual.arquivoArmazenado()).normalize());
        }
        return new ContratoDTO(contrato);
    }

    public ContratoDTO buscarContrato(String usinaId) {
        buscarUsinaOuFalhar(usinaId);
        ContratoUsina contrato = gestaoRepository.buscarContrato(usinaId);
        if (contrato == null) {
            throw falha(HttpStatus.NOT_FOUND, "A usina não possui contrato cadastrado.");
        }
        return new ContratoDTO(contrato);
    }

    public Path caminhoArquivoContrato(String usinaId) {
        buscarUsinaOuFalhar(usinaId);
        ContratoUsina contrato = gestaoRepository.buscarContrato(usinaId);
        if (contrato == null) {
            throw falha(HttpStatus.NOT_FOUND, "A usina não possui contrato cadastrado.");
        }
        Path arquivo = diretorioContratos.resolve(contrato.arquivoArmazenado()).normalize();
        if (!arquivo.startsWith(diretorioContratos) || !Files.isRegularFile(arquivo)) {
            throw falha(HttpStatus.NOT_FOUND, "O arquivo do contrato não está disponível.");
        }
        return arquivo;
    }

    public void excluirContrato(String usinaId) {
        buscarUsinaOuFalhar(usinaId);
        ContratoUsina contrato = gestaoRepository.buscarContrato(usinaId);
        if (contrato == null) {
            throw falha(HttpStatus.NOT_FOUND, "A usina não possui contrato cadastrado.");
        }
        gestaoRepository.excluirContrato(contrato);
        removerArquivo(diretorioContratos.resolve(contrato.arquivoArmazenado()).normalize());
    }

    private Usina buscarUsinaOuFalhar(String usinaId) {
        idObjeto(usinaId, "usina_id");
        Usina usina = gestaoRepository.buscarUsina(usinaId);
        if (usina == null) {
            throw falha(HttpStatus.NOT_FOUND, "Usina não encontrada.");
        }
        return usina;
    }

    private String gerarCodigoUsina() {
        int ano = Year.now().getValue();
        Set<String> codigos = new HashSet<>();
        for (Usina usina : gestaoRepository.listarUsinas()) {
            if (usina.codigo() != null) {
                codigos.add(usina.codigo());
            }
        }
        for (int sequencia = 1; sequencia <= codigos.size() + 1; sequencia++) {
            String codigo = "USN-" + ano + "-" + String.format("%03d", sequencia);
            if (!codigos.contains(codigo)) {
                return codigo;
            }
        }
        throw falha(HttpStatus.CONFLICT, "Não foi possível gerar um código para a usina.");
    }

    private void validarUsina(UsinaRequest dados) {
        if (dados == null || emBranco(dados.nome()) || emBranco(dados.distribuidora())
                || dados.potencia() == null || !Double.isFinite(dados.potencia()) || dados.potencia() <= 0) {
            throw falha(HttpStatus.BAD_REQUEST, "Informe nome, distribuidora e potência maior que zero.");
        }
    }

    private void validarMembro(MembroRequest dados) {
        if (dados == null || emBranco(dados.nome()) || emBranco(dados.email())
                || dados.usinaId() == null || !ObjectId.isValid(dados.usinaId())) {
            throw falha(HttpStatus.BAD_REQUEST, "Informe nome, e-mail e uma usina válida.");
        }
        if (!Pattern.matches(
                "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$",
                dados.email().trim())) {
            throw falha(HttpStatus.BAD_REQUEST, "Informe um e-mail válido.");
        }
    }

    private String nomeSeguro(String nomeOriginal) {
        if (nomeOriginal == null || nomeOriginal.isBlank()) {
            throw falha(HttpStatus.BAD_REQUEST, "O arquivo precisa ter um nome.");
        }
        String nome = nomeOriginal.replace('\\', '/');
        nome = nome.substring(nome.lastIndexOf('/') + 1)
                .replaceAll("[\\r\\n\\t]", "_")
                .trim();
        if (nome.isEmpty() || nome.length() > 150) {
            throw falha(HttpStatus.BAD_REQUEST, "O nome do arquivo é inválido.");
        }
        return nome;
    }

    private boolean ehPdf(byte[] conteudo) {
        return conteudo.length >= 5
                && conteudo[0] == '%'
                && conteudo[1] == 'P'
                && conteudo[2] == 'D'
                && conteudo[3] == 'F'
                && conteudo[4] == '-';
    }

    private void removerArquivo(Path arquivo) {
        if (!arquivo.normalize().startsWith(diretorioContratos)) {
            throw falha(HttpStatus.INTERNAL_SERVER_ERROR, "Caminho de contrato inválido.");
        }
        try {
            Files.deleteIfExists(arquivo);
        } catch (IOException erro) {
            throw falha(HttpStatus.INTERNAL_SERVER_ERROR, "Não foi possível remover o arquivo do contrato.");
        }
    }

    private ObjectId idObjeto(String valor, String campo) {
        if (valor == null || !ObjectId.isValid(valor)) {
            throw falha(HttpStatus.BAD_REQUEST, campo + " inválido.");
        }
        return new ObjectId(valor);
    }

    private double paraNumero(Object valor) {
        if (valor == null) {
            return 0;
        }
        if (valor instanceof Number numero) {
            return numero.doubleValue();
        }
        if (valor instanceof String texto) {
            try {
                double numero = Double.parseDouble(texto);
                if (Double.isFinite(numero)) {
                    return numero;
                }
            } catch (NumberFormatException erro) {
                throw falha(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "Foi encontrado um valor numérico inválido no banco.");
            }
        }
        throw falha(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "Foi encontrado um valor numérico incompatível no banco.");
    }

    private boolean emBranco(String valor) {
        return valor == null || valor.isBlank();
    }

    private String textoOpcional(String valor) {
        return valor == null || valor.isBlank() ? null : valor.trim();
    }

    private ResponseStatusException falha(HttpStatus status, String mensagem) {
        return new ResponseStatusException(status, mensagem);
    }
}
