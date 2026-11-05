//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// regras de negócio de cadastro, login (membro e administrador) e recuperação de senha
// os acessos externos vêm por "deps" (padrão: banco real + e-mail real) para poderem ser trocados nos testes

import { gerarHashSenha, verificarSenha } from "../perfil/perfil_senha";
import { ehAdministrador } from "../perfil/perfil_service";
import { ErroHttp } from "../perfil/perfil_validacao";
import type { Doc } from "../perfil/perfil_repo";
import * as repoReal from "./auth_repo";
import { enviarEmailRecuperacao } from "./auth_email";
import { LimiteTentativas } from "./auth_limite";
import {
  codigoConfere,
  gerarCodigo,
  hashCodigo,
  INTERVALO_REENVIO_MS,
  MAXIMO_TENTATIVAS_CODIGO,
  VALIDADE_CODIGO_MS,
} from "./auth_recuperacao";
import { gerarToken } from "./auth_token";
import {
  validarCadastro,
  validarEmailRecuperacao,
  validarLogin,
  validarRedefinicao,
} from "./auth_validacao";

export type DepsAuth = {
  buscarMembroPorEmail: (email: string) => Promise<Doc | null>;
  buscarMembroPorCpf: (cpf: string) => Promise<Doc | null>;
  criarMembro: typeof repoReal.criarMembro;
  registrarLogin: typeof repoReal.registrarLogin;
  salvarRecuperacao: typeof repoReal.salvarRecuperacao;
  registrarTentativaRecuperacao: typeof repoReal.registrarTentativaRecuperacao;
  gravarNovaSenha: typeof repoReal.gravarNovaSenha;
  enviarEmailRecuperacao: (destino: string, nome: string, codigo: string) => Promise<void>;
  limite: LimiteTentativas;
  agora: () => Date;
};

export const depsPadrao: DepsAuth = {
  ...repoReal,
  enviarEmailRecuperacao,
  limite: new LimiteTentativas(),
  agora: () => new Date(),
};

export type RespostaAuth = {
  token: string;
  usuario: {
    id: string;
    nome: string;
    email: string;
    tipo_usuario: string;
    eh_admin: boolean;
  };
};

export const MENSAGEM_RECUPERACAO =
  "Se o e-mail estiver cadastrado, enviamos um código de 6 dígitos. Ele vale por 15 minutos.";

function montarResposta(membro: Doc): RespostaAuth {
  const admin = ehAdministrador(membro);
  return {
    token: gerarToken(String(membro._id), admin ? "admin" : "membro"),
    usuario: {
      id: String(membro._id),
      nome: String(membro.nome ?? ""),
      email: String(membro.email ?? ""),
      tipo_usuario: String(membro.tipo_usuario ?? "membro"),
      eh_admin: admin,
    },
  };
}

// usado quando o e-mail não existe, para o tempo de resposta não revelar se a conta existe
let hashFalso: Promise<string> | undefined;

// POST /auth/cadastro  (sempre cria conta de "membro": o tipo nunca vem do app)
export async function cadastrarMembro(
  entrada: Record<string, unknown>,
  deps: DepsAuth = depsPadrao,
): Promise<RespostaAuth> {
  const dados = validarCadastro(entrada);

  const jaExiste = new ErroHttp(409, "Este e-mail já está cadastrado", {
    email: "Este e-mail já está cadastrado",
  });
  const cpfJaExiste = new ErroHttp(409, "Este CPF já está cadastrado", {
    cpf: "Este CPF já está cadastrado",
  });
  if (dados.cpf === null) {
    throw new ErroHttp(400, "Dados inválidos", { cpf: "Informe seu CPF" });
  }
  if (await deps.buscarMembroPorEmail(dados.email)) throw jaExiste;
  if (await deps.buscarMembroPorCpf(dados.cpf)) throw cpfJaExiste;

  try {
    const membro = await deps.criarMembro({
      nome: dados.nome,
      email: dados.email,
      cpf: dados.cpf,
      telefone: dados.telefone,
      senha_hash: await gerarHashSenha(dados.senha),
      tipo_usuario: "membro",
      data_cadastro: deps.agora(),
    });
    return montarResposta(membro);
  } catch (erro) {
    // índice único no banco (se existir) acusando e-mail ou CPF repetido
    const duplicado = erro as { code?: number; keyPattern?: Record<string, unknown> };
    if (duplicado?.code === 11000) throw duplicado.keyPattern?.cpf ? cpfJaExiste : jaExiste;
    throw erro;
  }
}

// POST /auth/login   { email, senha, perfil?: "membro" | "admin" }
export async function entrar(
  entrada: Record<string, unknown>,
  deps: DepsAuth = depsPadrao,
): Promise<RespostaAuth> {
  const { email, senha, comoAdmin } = validarLogin(entrada);

  if (deps.limite.bloqueado(email)) {
    throw new ErroHttp(429, "Muitas tentativas. Tente novamente em alguns minutos.");
  }

  const membro = await deps.buscarMembroPorEmail(email);
  const hash = typeof membro?.senha_hash === "string" ? membro.senha_hash : "";

  // confere sempre um hash (mesmo sem conta) para o tempo ser parecido nos dois casos
  hashFalso ??= gerarHashSenha("senha-falsa-para-igualar-o-tempo");
  const senhaCorreta = await verificarSenha(senha, hash || (await hashFalso));

  if (!membro || hash === "" || !senhaCorreta) {
    deps.limite.registrarFalha(email);
    throw new ErroHttp(401, "E-mail ou senha incorretos");
  }

  if (comoAdmin && !ehAdministrador(membro)) {
    throw new ErroHttp(403, "Este acesso é restrito a administradores");
  }

  deps.limite.limpar(email);
  await deps.registrarLogin(String(membro._id));
  return montarResposta(membro);
}

// POST /auth/recuperar-senha   { email }
// sempre responde igual, exista a conta ou não (não revela quem é cadastrado)
export async function solicitarRecuperacao(
  entrada: Record<string, unknown>,
  deps: DepsAuth = depsPadrao,
): Promise<{ mensagem: string }> {
  const email = validarEmailRecuperacao(entrada);
  const membro = await deps.buscarMembroPorEmail(email);

  if (membro) {
    const agora = deps.agora();
    const ultimoEnvio = membro.recuperacao_enviada_em
      ? new Date(membro.recuperacao_enviada_em as string | Date).getTime()
      : 0;

    // no máximo 1 código por minuto
    if (agora.getTime() - ultimoEnvio >= INTERVALO_REENVIO_MS) {
      const id = String(membro._id);
      const codigo = gerarCodigo();
      try {
        await deps.salvarRecuperacao(id, {
          codigoHash: hashCodigo(id, codigo),
          expiraEm: new Date(agora.getTime() + VALIDADE_CODIGO_MS),
          enviadaEm: agora,
        });
        await deps.enviarEmailRecuperacao(String(membro.email), String(membro.nome ?? ""), codigo);
      } catch (erro) {
        // falha de e-mail só vai para o log do servidor (a resposta continua igual)
        console.error("Falha ao enviar e-mail de recuperação:", erro);
      }
    }
  }
  return { mensagem: MENSAGEM_RECUPERACAO };
}

// POST /auth/redefinir-senha   { email, codigo, nova_senha }
export async function redefinirSenha(
  entrada: Record<string, unknown>,
  deps: DepsAuth = depsPadrao,
): Promise<{ mensagem: string }> {
  const { email, codigo, novaSenha } = validarRedefinicao(entrada);
  const invalido = new ErroHttp(400, "Código inválido ou expirado", {
    codigo: "Código inválido ou expirado",
  });

  const membro = await deps.buscarMembroPorEmail(email);
  const hashGuardado = membro?.recuperacao_codigo_hash;
  const expiraEm = membro?.recuperacao_expira_em
    ? new Date(membro.recuperacao_expira_em as string | Date).getTime()
    : 0;
  const tentativas = Number(membro?.recuperacao_tentativas ?? 0);

  if (
    !membro ||
    typeof hashGuardado !== "string" ||
    expiraEm < deps.agora().getTime() ||
    tentativas >= MAXIMO_TENTATIVAS_CODIGO
  ) {
    throw invalido;
  }

  const id = String(membro._id);
  if (!codigoConfere(id, codigo, hashGuardado)) {
    await deps.registrarTentativaRecuperacao(id);
    throw invalido;
  }

  await deps.gravarNovaSenha(id, await gerarHashSenha(novaSenha));
  deps.limite.limpar(email); // se estava bloqueado por tentativas de login, libera
  return { mensagem: "Senha redefinida com sucesso" };
}
