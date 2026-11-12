//Autora: Ana Luísa Maso Mafra | RA: 25007997

// testes de cadastro, login (JWT), recuperação de senha e middlewares (rodar com: npm test)
import test from "node:test";
import assert from "node:assert/strict";
import jwt from "jsonwebtoken";
import { ErroHttp } from "../src/modules/perfil/perfil_validacao";
import { gerarHashSenha, verificarSenha } from "../src/modules/perfil/perfil_senha";
import { gerarToken, verificarToken } from "../src/modules/auth/auth_token";
import { exigirAdmin, exigirAutenticacao } from "../src/modules/auth/auth_middleware";
import { cpfValido, normalizarCpf } from "../src/modules/auth/auth_cpf";
import { LimiteTentativas } from "../src/modules/auth/auth_limite";
import { codigoConfere, gerarCodigo, hashCodigo } from "../src/modules/auth/auth_recuperacao";
import {
  cadastrarMembro,
  DepsAuth,
  entrar,
  MENSAGEM_RECUPERACAO,
  redefinirSenha,
  solicitarRecuperacao,
} from "../src/modules/auth/auth_service";

process.env.JWT_SECRET = "segredo-de-teste-com-mais-de-16-caracteres";

const ID = "507f1f77bcf86cd799439011";
const CPF_VALIDO = "529.982.247-25";

const status = async (promessa: Promise<unknown>) => {
  try {
    await promessa;
  } catch (erro) {
    return (erro as ErroHttp).status;
  }
  return 200;
};

// banco falso em memória com um único membro (ou nenhum)
function montarDeps(membroInicial: Record<string, any> | null, agora = () => new Date()) {
  const estado = { membro: membroInicial ? { ...membroInicial } : null, emails: [] as string[], codigoEnviado: "" };
  const deps: DepsAuth = {
    buscarMembroPorEmail: async (email) =>
      estado.membro && String(estado.membro.email).toLowerCase() === email ? { ...estado.membro } : null,
    buscarMembroPorCpf: async (cpf) =>
      estado.membro && estado.membro.cpf === cpf ? { ...estado.membro } : null,
    criarMembro: async (dados) => {
      estado.membro = { _id: ID, ...dados, cadastro_concluido: true };
      return { ...estado.membro };
    },
    completarPreCadastroMembro: async (membroId, dados) => {
      if (!estado.membro || String(estado.membro._id) !== membroId) return null;
      const hashAtual =
        typeof estado.membro.senha_hash === "string"
          ? estado.membro.senha_hash.trim()
          : "";
      if (hashAtual.length > 0) return null;
      const { telefone, ...resto } = dados;
      estado.membro = {
        ...estado.membro,
        ...resto,
        ...(telefone ? { telefone } : {}),
        atualizado_em: dados.ultimo_login_em,
        cadastro_concluido: true,
      };
      return { ...estado.membro };
    },
    registrarLogin: async () => {},
    salvarRecuperacao: async (_id, d) => {
      Object.assign(estado.membro!, {
        recuperacao_codigo_hash: d.codigoHash,
        recuperacao_expira_em: d.expiraEm,
        recuperacao_enviada_em: d.enviadaEm,
        recuperacao_tentativas: 0,
      });
    },
    registrarTentativaRecuperacao: async () => {
      estado.membro!.recuperacao_tentativas = Number(estado.membro!.recuperacao_tentativas ?? 0) + 1;
    },
    gravarNovaSenha: async (_id, hash) => {
      estado.membro!.senha_hash = hash;
      delete estado.membro!.recuperacao_codigo_hash;
      delete estado.membro!.recuperacao_expira_em;
      delete estado.membro!.recuperacao_tentativas;
    },
    enviarEmailRecuperacao: async (destino, _nome, codigo) => {
      estado.emails.push(destino);
      estado.codigoEnviado = codigo;
    },
    limite: new LimiteTentativas(),
    agora,
  };
  return { deps, estado };
}

async function membroComSenha(senha: string, extra: Record<string, any> = {}) {
  return {
    _id: ID,
    nome: "João Oliveira",
    email: "joao@email.com",
    tipo_usuario: "membro",
    senha_hash: await gerarHashSenha(senha),
    ...extra,
  };
}

// ---------- token ----------

test("token JWT: gera, confere e recusa adulterado/expirado/outro algoritmo", () => {
  const token = gerarToken(ID, "membro");
  assert.deepEqual(verificarToken(token), { id: ID, tipo: "membro" });
  assert.deepEqual(verificarToken(gerarToken(ID, "admin")), { id: ID, tipo: "admin" });

  assert.equal(verificarToken(token + "x"), null);
  assert.equal(verificarToken("lixo"), null);

  const outroSegredo = jwt.sign({ tipo: "admin" }, "outro-segredo-com-mais-de-16", { subject: ID });
  assert.equal(verificarToken(outroSegredo), null);

  const expirado = jwt.sign({ tipo: "membro" }, process.env.JWT_SECRET!, { subject: ID, expiresIn: -10 });
  assert.equal(verificarToken(expirado), null);

  const semAssinatura = jwt.sign({ tipo: "admin" }, "", { subject: ID, algorithm: "none" });
  assert.equal(verificarToken(semAssinatura), null);

  const tipoInvalido = jwt.sign({ tipo: "root" }, process.env.JWT_SECRET!, { subject: ID });
  assert.equal(verificarToken(tipoInvalido), null);
});

// ---------- middlewares ----------

function executarMiddleware(mid: Function, req: any) {
  const resultado: { status?: number; corpo?: any; passou: boolean } = { passou: false };
  const res: any = {
    status(c: number) {
      resultado.status = c;
      return res;
    },
    json(c: any) {
      resultado.corpo = c;
      return res;
    },
  };
  mid(req, res, () => {
    resultado.passou = true;
  });
  return resultado;
}

test("exigirAutenticacao: libera com token válido e bloqueia o resto", () => {
  const ok = { headers: { authorization: `Bearer ${gerarToken(ID, "membro")}` } } as any;
  assert.equal(executarMiddleware(exigirAutenticacao, ok).passou, true);
  assert.deepEqual(ok.usuario, { id: ID, tipo: "membro" });

  for (const authorization of [undefined, "", "Bearer", "Bearer lixo", `Basic ${gerarToken(ID, "membro")}`]) {
    const r = executarMiddleware(exigirAutenticacao, { headers: { authorization } });
    assert.equal(r.passou, false);
    assert.equal(r.status, 401);
  }
});

test("exigirAdmin: só deixa passar token de administrador", () => {
  assert.equal(executarMiddleware(exigirAdmin, { usuario: { id: ID, tipo: "admin" } }).passou, true);
  const negado = executarMiddleware(exigirAdmin, { usuario: { id: ID, tipo: "membro" } });
  assert.equal(negado.passou, false);
  assert.equal(negado.status, 403);
});

// ---------- limite de tentativas ----------

test("limite de tentativas bloqueia e libera depois da janela", () => {
  let agora = 0;
  const limite = new LimiteTentativas(3, 1000, () => agora);
  for (let i = 0; i < 3; i++) limite.registrarFalha("a@b.co");
  assert.equal(limite.bloqueado("a@b.co"), true);
  assert.equal(limite.bloqueado("outro@b.co"), false);
  agora = 1500;
  assert.equal(limite.bloqueado("a@b.co"), false);
  limite.registrarFalha("a@b.co");
  limite.limpar("a@b.co");
  assert.equal(limite.bloqueado("a@b.co"), false);
});

// ---------- cadastro ----------

test("cadastro: cria conta de membro com hash e devolve token", async () => {
  const { deps, estado } = montarDeps(null);
  const r = await cadastrarMembro(
    { nome: "  Ana  Maso ", email: " ANA@Gmail.com ", cpf: "529.982.247-25", telefone: "(19) 99999-8888", senha: "segredo123", confirmar_senha: "segredo123" },
    deps,
  );
  assert.equal(r.usuario.email, "ana@gmail.com");
  assert.equal(r.usuario.nome, "Ana Maso");
  assert.equal(r.usuario.eh_admin, false);
  assert.deepEqual(verificarToken(r.token), { id: ID, tipo: "membro" });
  assert.equal(estado.membro!.tipo_usuario, "membro");
  assert.equal(estado.membro!.telefone, "19999998888");
  assert.equal(estado.membro!.cpf, "52998224725"); // só dígitos
  assert.ok(!JSON.stringify(r).includes("52998224725")); // o CPF não volta na resposta
  assert.notEqual(estado.membro!.senha_hash, "segredo123");
  assert.equal(await verificarSenha("segredo123", estado.membro!.senha_hash), true);
  assert.ok(!JSON.stringify(r).includes("senha_hash"));
});

test("cadastro: ignora tipo_usuario enviado pelo app (não vira admin)", async () => {
  const { deps, estado } = montarDeps(null);
  await cadastrarMembro(
    { nome: "Ana Maso", email: "a@b.co", cpf: CPF_VALIDO, senha: "segredo123", tipo_usuario: "admin" } as any,
    deps,
  );
  assert.equal(estado.membro!.tipo_usuario, "membro");
});

test("cadastro: valida campos e recusa e-mail repetido (sem diferenciar maiúsculas)", async () => {
  const { deps } = montarDeps(await membroComSenha("x12345"));
  assert.equal(await status(cadastrarMembro({ nome: "Ana Maso", email: "JOAO@email.com", cpf: CPF_VALIDO, senha: "segredo123" }, deps)), 409);
  assert.equal(await status(cadastrarMembro({ nome: "Ana", email: "x", cpf: CPF_VALIDO, senha: "1" }, deps)), 400);
  assert.equal(
    await status(cadastrarMembro({ nome: "Ana Maso", email: "a@b.co", cpf: CPF_VALIDO, senha: "segredo123", confirmar_senha: "outra123" }, deps)),
    400,
  );
});

test("cpf: valida dígitos verificadores, tamanho e sequências repetidas", () => {
  assert.equal(cpfValido("529.982.247-25"), true);
  assert.equal(cpfValido("52998224725"), true);
  assert.equal(cpfValido("529.982.247-24"), false); // dígito errado
  assert.equal(cpfValido("111.111.111-11"), false); // sequência repetida
  assert.equal(cpfValido("1234567890"), false); // 10 dígitos
  assert.equal(cpfValido(""), false);
  assert.equal(cpfValido(undefined), false);
  assert.equal(normalizarCpf("529.982.247-25"), "52998224725");
});

test("cadastro: CPF é obrigatório e precisa ser válido", async () => {
  const { deps } = montarDeps(null);
  const campos = async (entrada: Record<string, unknown>) => {
    try {
      await cadastrarMembro({ nome: "Ana Maso", email: "a@b.co", senha: "segredo123", ...entrada }, deps);
    } catch (erro) {
      return (erro as ErroHttp).campos;
    }
    return {} as Record<string, string>;
  };
  assert.equal((await campos({})).cpf, "Informe seu CPF");
  assert.equal((await campos({ cpf: "123.456.789-00" })).cpf, "CPF inválido");
  assert.equal((await campos({ cpf: CPF_VALIDO })).cpf, undefined);
});

test("cadastro: recusa CPF já cadastrado (409) mesmo com outro e-mail", async () => {
  const { deps } = montarDeps(await membroComSenha("x12345", { cpf: "52998224725" }));
  assert.equal(
    await status(cadastrarMembro({ nome: "Ana Maso", email: "outra@pessoa.com", cpf: "529.982.247-25", senha: "segredo123" }, deps)),
    409,
  );
});

// ---------- login ----------

test("login de membro: ok, token de membro", async () => {
  const { deps } = montarDeps(await membroComSenha("segredo123"));
  const r = await entrar({ email: "JOAO@email.com", senha: "segredo123" }, deps);
  assert.deepEqual(verificarToken(r.token), { id: ID, tipo: "membro" });
  assert.equal(r.usuario.eh_admin, false);
});

test("login: senha errada, e-mail inexistente e conta sem senha dão a mesma resposta 401", async () => {
  const { deps } = montarDeps(await membroComSenha("segredo123"));
  const mensagem = async (entrada: object) => {
    try {
      await entrar(entrada as any, deps);
    } catch (e) {
      return [(e as ErroHttp).status, (e as ErroHttp).message];
    }
    return [200, ""];
  };
  const errada = await mensagem({ email: "joao@email.com", senha: "errada1" });
  const inexistente = await mensagem({ email: "nao@existe.com", senha: "segredo123" });
  assert.deepEqual(errada, [401, "E-mail ou senha incorretos"]);
  assert.deepEqual(inexistente, errada);

  const { deps: semSenha } = montarDeps({ _id: ID, nome: "Antigo Membro", email: "antigo@email.com" });
  assert.equal(await status(entrar({ email: "antigo@email.com", senha: "qualquer1" }, semSenha)), 401);
});

test("login: exige e-mail e senha preenchidos", async () => {
  const { deps } = montarDeps(null);
  assert.equal(await status(entrar({ email: "", senha: "" }, deps)), 400);
});

test("login de administrador: só entra quem é admin; membro recebe 403", async () => {
  const { deps: dMembro } = montarDeps(await membroComSenha("segredo123"));
  assert.equal(await status(entrar({ email: "joao@email.com", senha: "segredo123", perfil: "admin" }, dMembro)), 403);

  const { deps: dAdmin } = montarDeps(await membroComSenha("segredo123", { tipo_usuario: "admin" }));
  const r = await entrar({ email: "joao@email.com", senha: "segredo123", perfil: "admin" }, dAdmin);
  assert.deepEqual(verificarToken(r.token), { id: ID, tipo: "admin" });
  assert.equal(r.usuario.eh_admin, true);

  // admin entrando pela tela de membro também recebe token de admin (a conta é admin)
  const rMembro = await entrar({ email: "joao@email.com", senha: "segredo123" }, dAdmin);
  assert.equal(verificarToken(rMembro.token)?.tipo, "admin");
});

test("login: bloqueia depois de 5 senhas erradas (mesmo com a senha certa)", async () => {
  const { deps } = montarDeps(await membroComSenha("segredo123"));
  for (let i = 0; i < 5; i++) {
    assert.equal(await status(entrar({ email: "joao@email.com", senha: "errada1" }, deps)), 401);
  }
  assert.equal(await status(entrar({ email: "joao@email.com", senha: "segredo123" }, deps)), 429);
});

// ---------- recuperação de senha ----------

test("código de recuperação: 6 dígitos e só confere o HMAC certo", () => {
  const codigo = gerarCodigo();
  assert.match(codigo, /^\d{6}$/);
  const hash = hashCodigo(ID, codigo);
  assert.notEqual(hash, codigo);
  assert.equal(codigoConfere(ID, codigo, hash), true);
  assert.equal(codigoConfere(ID, "000000" === codigo ? "111111" : "000000", hash), false);
  assert.equal(codigoConfere("507f1f77bcf86cd799439099", codigo, hash), false);
});

test("recuperação: mesma resposta exista a conta ou não; só envia se existir", async () => {
  const { deps, estado } = montarDeps(await membroComSenha("segredo123"));
  const existe = await solicitarRecuperacao({ email: "joao@email.com" }, deps);
  const naoExiste = await solicitarRecuperacao({ email: "ninguem@email.com" }, deps);
  assert.deepEqual(existe, { mensagem: MENSAGEM_RECUPERACAO });
  assert.deepEqual(naoExiste, existe);
  assert.deepEqual(estado.emails, ["joao@email.com"]);
  assert.match(estado.codigoEnviado, /^\d{6}$/);
  assert.notEqual(estado.membro!.recuperacao_codigo_hash, estado.codigoEnviado); // só o hash fica salvo
  assert.equal(await status(solicitarRecuperacao({ email: "invalido" }, deps)), 400);
});

test("recuperação: no máximo um código por minuto e falha de e-mail não vaza", async () => {
  let agora = new Date("2026-11-04T12:00:00Z");
  const { deps, estado } = montarDeps(await membroComSenha("segredo123"), () => agora);
  await solicitarRecuperacao({ email: "joao@email.com" }, deps);
  await solicitarRecuperacao({ email: "joao@email.com" }, deps); // < 1 min: ignora
  assert.equal(estado.emails.length, 1);
  agora = new Date("2026-11-04T12:01:01Z");
  await solicitarRecuperacao({ email: "joao@email.com" }, deps);
  assert.equal(estado.emails.length, 2);

  const falha = { ...deps, enviarEmailRecuperacao: async () => { throw new Error("SMTP fora do ar"); } };
  const silenciar = console.error;
  console.error = () => {};
  try {
    agora = new Date("2026-11-04T13:00:00Z");
    assert.deepEqual(await solicitarRecuperacao({ email: "joao@email.com" }, falha), { mensagem: MENSAGEM_RECUPERACAO });
  } finally {
    console.error = silenciar;
  }
});

test("redefinir senha: fluxo completo, código só vale uma vez e senha nova entra", async () => {
  const { deps, estado } = montarDeps(await membroComSenha("antiga123"));
  await solicitarRecuperacao({ email: "joao@email.com" }, deps);
  const codigo = estado.codigoEnviado;

  const r = await redefinirSenha({ email: "joao@email.com", codigo, nova_senha: "nova12345" }, deps);
  assert.equal(r.mensagem, "Senha redefinida com sucesso");
  assert.equal(await verificarSenha("nova12345", estado.membro!.senha_hash), true);
  assert.equal(estado.membro!.recuperacao_codigo_hash, undefined);

  // o mesmo código não funciona de novo
  assert.equal(await status(redefinirSenha({ email: "joao@email.com", codigo, nova_senha: "outra12345" }, deps)), 400);
  // e a nova senha já loga
  const login = await entrar({ email: "joao@email.com", senha: "nova12345" }, deps);
  assert.ok(login.token);
});

test("redefinir senha: código errado, expirado, e-mail sem pedido ou senha fraca => 400", async () => {
  let agora = new Date("2026-11-04T12:00:00Z");
  const { deps, estado } = montarDeps(await membroComSenha("antiga123"), () => agora);
  await solicitarRecuperacao({ email: "joao@email.com" }, deps);
  const certo = estado.codigoEnviado;
  const errado = certo === "123456" ? "654321" : "123456";

  assert.equal(await status(redefinirSenha({ email: "joao@email.com", codigo: errado, nova_senha: "nova12345" }, deps)), 400);
  assert.equal(await status(redefinirSenha({ email: "nao@existe.com", codigo: certo, nova_senha: "nova12345" }, deps)), 400);
  assert.equal(await status(redefinirSenha({ email: "joao@email.com", codigo: "12", nova_senha: "nova12345" }, deps)), 400);
  assert.equal(await status(redefinirSenha({ email: "joao@email.com", codigo: certo, nova_senha: "123" }, deps)), 400);

  agora = new Date("2026-11-04T12:16:00Z"); // 16 min depois: expirou
  assert.equal(await status(redefinirSenha({ email: "joao@email.com", codigo: certo, nova_senha: "nova12345" }, deps)), 400);
  assert.equal(await verificarSenha("antiga123", estado.membro!.senha_hash), true); // senha não mudou
});

test("redefinir senha: 5 códigos errados queimam o código (mesmo o certo falha depois)", async () => {
  const { deps, estado } = montarDeps(await membroComSenha("antiga123"));
  await solicitarRecuperacao({ email: "joao@email.com" }, deps);
  const certo = estado.codigoEnviado;
  const errado = certo === "123456" ? "654321" : "123456";

  for (let i = 0; i < 5; i++) {
    assert.equal(await status(redefinirSenha({ email: "joao@email.com", codigo: errado, nova_senha: "nova12345" }, deps)), 400);
  }
  assert.equal(await status(redefinirSenha({ email: "joao@email.com", codigo: certo, nova_senha: "nova12345" }, deps)), 400);
  assert.equal(await verificarSenha("antiga123", estado.membro!.senha_hash), true);
});

// ---------- cadastro como administrador (escolhido no seletor do cadastro) ----------

const dadosAdmin = (extra: Record<string, unknown> = {}) => ({
  nome: "Carla Admin",
  email: "carla@solis.com",
  cpf: CPF_VALIDO,
  senha: "segredo123",
  tipo_conta: "admin",
  ...extra,
});

test("cadastro como administrador: conta nasce admin e recebe token de admin", async () => {
  const { deps, estado } = montarDeps(null);
  const r = await cadastrarMembro(dadosAdmin(), deps);
  assert.equal(estado.membro!.tipo_usuario, "admin");
  assert.equal(r.usuario.eh_admin, true);
  assert.deepEqual(verificarToken(r.token), { id: ID, tipo: "admin" });
});

test("cadastro: sem tipo_conta (ou 'membro') cria membro; tipo inválido é recusado", async () => {
  const { deps, estado } = montarDeps(null);
  await cadastrarMembro(dadosAdmin({ tipo_conta: undefined }), deps);
  assert.equal(estado.membro!.tipo_usuario, "membro");

  const outro = montarDeps(null);
  await cadastrarMembro(dadosAdmin({ tipo_conta: "membro" }), outro.deps);
  assert.equal(outro.estado.membro!.tipo_usuario, "membro");

  assert.equal(await status(cadastrarMembro(dadosAdmin({ tipo_conta: "dono" }), montarDeps(null).deps)), 400);
});

test("cadastro: completa pré-cadastro de membro adicionado pelo admin mantendo _id, usina_id e tipo_usuario", async () => {
  const agoraFixa = new Date("2026-11-11T23:00:00Z");
  const usinaId = "6af4f37b19e679e0391938bf";
  const { deps, estado } = montarDeps(
    {
      _id: ID,
      nome: "Juliana",
      email: "juliana@solis.com",
      tipo_usuario: "membro",
      usina_id: usinaId,
    },
    () => agoraFixa,
  );

  const resposta = await cadastrarMembro(
    {
      nome: "Juliana Silva",
      email: "  JULIANA@solis.com ",
      cpf: CPF_VALIDO,
      telefone: "(19) 99888-7766",
      senha: "segredo123",
      tipo_conta: "admin",
    },
    deps,
  );

  assert.equal(resposta.usuario.id, ID);
  assert.equal(resposta.usuario.nome, "Juliana Silva");
  assert.equal(resposta.usuario.email, "juliana@solis.com");
  assert.equal(resposta.usuario.tipo_usuario, "membro");
  assert.equal(resposta.usuario.eh_admin, false);
  assert.deepEqual(verificarToken(resposta.token), { id: ID, tipo: "membro" });

  assert.equal(estado.membro!._id, ID);
  assert.equal(estado.membro!.usina_id, usinaId);
  assert.equal(estado.membro!.cpf, "52998224725");
  assert.equal(estado.membro!.telefone, "19998887766");
  assert.equal(estado.membro!.tipo_usuario, "membro");
  assert.equal(estado.membro!.cadastro_concluido, true);
  assert.deepEqual(estado.membro!.data_cadastro, agoraFixa);
  assert.deepEqual(estado.membro!.ultimo_login_em, agoraFixa);
  assert.equal(await verificarSenha("segredo123", estado.membro!.senha_hash), true);

  // após concluir, novo cadastro com o mesmo e-mail passa a ser bloqueado (409)
  assert.equal(
    await status(
      cadastrarMembro(
        { nome: "Outra Pessoa", email: "juliana@solis.com", cpf: CPF_VALIDO, senha: "segredo123" },
        deps,
      ),
    ),
    409,
  );

  // login funciona normalmente com a senha recém-cadastrada
  const login = await entrar({ email: "juliana@solis.com", senha: "segredo123" }, deps);
  assert.equal(login.usuario.id, ID);
});

test("cadastro: recusa pré-cadastro se o CPF já pertencer a outro membro ou se houver corrida", async () => {
  const { deps } = montarDeps({
    _id: ID,
    nome: "João Lucas",
    email: "joao@solis.com",
    tipo_usuario: "membro",
    usina_id: "6af4f37b19e679e0391938bf",
  });

  const depsCpfDeOutro: DepsAuth = {
    ...deps,
    buscarMembroPorCpf: async () => ({ _id: "507f1f77bcf86cd799439099", cpf: "52998224725" }),
  };
  assert.equal(
    await status(
      cadastrarMembro(
        { nome: "João Lucas", email: "joao@solis.com", cpf: CPF_VALIDO, senha: "segredo123" },
        depsCpfDeOutro,
      ),
    ),
    409,
  );

  const depsCorrida: DepsAuth = {
    ...deps,
    completarPreCadastroMembro: async () => null,
  };
  assert.equal(
    await status(
      cadastrarMembro(
        { nome: "João Lucas", email: "joao@solis.com", cpf: CPF_VALIDO, senha: "segredo123" },
        depsCorrida,
      ),
    ),
    409,
  );
});
