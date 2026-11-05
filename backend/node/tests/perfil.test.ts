//Autora: Ana Luísa Maso Mafra | RA: 25007997

// testes do módulo de perfil do membro (rodar com: npm test)
import test from "node:test";
import assert from "node:assert/strict";
import {
  ErroHttp,
  normalizarTelefone,
  validarDadosPerfil,
  validarDadosSenha,
} from "../src/modules/perfil/perfil_validacao";
import { gerarHashSenha, verificarSenha } from "../src/modules/perfil/perfil_senha";
import {
  alterarSenha,
  DepsPerfil,
  editarPerfil,
  escolherContrato,
  montarContrato,
  montarPerfil,
  obterContrato,
  obterPerfil,
} from "../src/modules/perfil/perfil_service";

const ID = "507f1f77bcf86cd799439011";

// ---------- validação ----------

test("normaliza telefone para somente dígitos", () => {
  assert.equal(normalizarTelefone("(19) 99999-8888"), "19999998888");
  assert.equal(normalizarTelefone("+55 19 99999-8888"), "19999998888");
  assert.equal(normalizarTelefone("(19) 3333-4444"), "1933334444");
  assert.equal(normalizarTelefone("   "), null);
  assert.equal(normalizarTelefone(undefined), null);
  assert.equal(normalizarTelefone("12345"), "invalido");
  assert.equal(normalizarTelefone("19 89999-8888"), "invalido"); // celular precisa começar com 9
});

test("valida dados do perfil e normaliza nome/e-mail", () => {
  const dados = validarDadosPerfil({
    nome: "  João   Oliveira ",
    email: " Joao@Email.com ",
    telefone: "(19) 99999-8888",
  });
  assert.deepEqual(dados, {
    nome: "João Oliveira",
    email: "joao@email.com",
    telefone: "19999998888",
  });
});

test("telefone vazio remove o telefone (null)", () => {
  const dados = validarDadosPerfil({ nome: "Ana Maso", email: "a@b.co", telefone: "" });
  assert.equal(dados.telefone, null);
});

test("devolve o erro de cada campo inválido", () => {
  assert.throws(
    () => validarDadosPerfil({ nome: "João", email: "sem-arroba", telefone: "123" }),
    (erro: unknown) => {
      assert.ok(erro instanceof ErroHttp);
      assert.equal(erro.status, 400);
      assert.deepEqual(Object.keys(erro.campos).sort(), ["email", "nome", "telefone"]);
      return true;
    },
  );
});

test("valida troca de senha", () => {
  assert.deepEqual(
    validarDadosSenha({ senha_atual: "antiga1", nova_senha: "nova123", confirmar_senha: "nova123" }),
    { senhaAtual: "antiga1", novaSenha: "nova123" },
  );
  const campos = (entrada: object) => {
    try {
      validarDadosSenha(entrada);
    } catch (erro) {
      return (erro as ErroHttp).campos;
    }
    return {};
  };
  assert.ok(campos({ nova_senha: "nova123" }).senha_atual);
  assert.ok(campos({ senha_atual: "x", nova_senha: "123" }).nova_senha);
  assert.ok(campos({ senha_atual: "igual12", nova_senha: "igual12" }).nova_senha);
  assert.ok(
    campos({ senha_atual: "a", nova_senha: "nova123", confirmar_senha: "outra12" }).confirmar_senha,
  );
});

// ---------- hash de senha ----------

test("hash de senha confere a senha certa e recusa a errada", async () => {
  const hash = await gerarHashSenha("segredo123");
  assert.notEqual(hash, "segredo123");
  assert.ok(hash.startsWith("scrypt$"));
  assert.equal(await verificarSenha("segredo123", hash), true);
  assert.equal(await verificarSenha("segredo124", hash), false);
  assert.equal(await verificarSenha("x", "formato-invalido"), false);
  assert.notEqual(await gerarHashSenha("segredo123"), hash); // salt diferente a cada vez
});

// ---------- montagem das respostas ----------

const membro = {
  _id: ID,
  nome: "João Oliveira",
  email: "joao@email.com",
  telefone: "19999998888",
  tipo_usuario: "membro",
  usina_id: "507f1f77bcf86cd799439022",
  senha_hash: "nunca-pode-vazar",
};
const cota = { percentual: 25, tarifa_kwh: 0.69, data_inicio: new Date("2025-03-10T00:00:00Z") };
const usina = { _id: "507f1f77bcf86cd799439022", nome: "Usina Solis", localizacao: "Campinas - SP" };

test("monta o perfil com card do consórcio e sem expor senha", () => {
  const perfil = montarPerfil(membro, cota, usina);
  assert.equal(perfil.membro.inicial, "J");
  assert.equal(perfil.membro.eh_admin, false);
  assert.equal(perfil.consorcio.cota_percentual, 25);
  assert.equal(perfil.consorcio.membro_desde, "2025-03-10T00:00:00.000Z"); // cai na data da cota
  assert.equal(perfil.consorcio.usina?.nome, "Usina Solis");
  assert.ok(!JSON.stringify(perfil).includes("nunca-pode-vazar"));
});

test("membro_desde prioriza data_cadastro e, sem nada, usa a data do _id", () => {
  const comCadastro = montarPerfil({ ...membro, data_cadastro: new Date("2024-01-05T12:00:00Z") }, cota, null);
  assert.equal(comCadastro.consorcio.membro_desde, "2024-01-05T12:00:00.000Z");
  const doId = montarPerfil(membro, null, null);
  assert.ok(doId.consorcio.membro_desde); // 507f1f77 = 2012
  assert.equal(doId.consorcio.usina, null);
  assert.equal(doId.consorcio.cota_percentual, null);
});

test("admin vê o botão do painel administrador (maiúsculas e variações)", () => {
  assert.equal(montarPerfil({ ...membro, tipo_usuario: "admin" }, null, null).membro.eh_admin, true);
  assert.equal(montarPerfil({ ...membro, tipo_usuario: " Administrador " }, null, null).membro.eh_admin, true);
  assert.equal(montarPerfil({ ...membro, tipo_usuario: undefined }, null, null).membro.eh_admin, false);
});

test("contrato: escolhe o ativo e completa dados com a cota e a usina", () => {
  const encerrado = { numero: "A", status: "encerrado" };
  const ativo = { numero: "B", status: "ATIVO", clausulas: [{ titulo: "1", texto: "x" }, {}] };
  assert.equal(escolherContrato([encerrado, ativo])?.numero, "B");
  assert.equal(escolherContrato([encerrado])?.numero, "A");
  assert.equal(escolherContrato([]), null);

  const c = montarContrato(ativo, membro, cota, usina);
  assert.equal(c.status, "ativo");
  assert.equal(c.cota_percentual, 25);
  assert.equal(c.tarifa_kwh, 0.69);
  assert.equal(c.data_inicio, "2025-03-10T00:00:00.000Z");
  assert.equal(c.clausulas.length, 1); // cláusula vazia é descartada
  assert.equal(c.usina?.localizacao, "Campinas - SP");
});

// ---------- casos de uso com banco falso ----------

function depsFalsas(parcial: Partial<DepsPerfil> = {}): DepsPerfil {
  return {
    buscarMembroPorId: async () => ({ ...membro }),
    buscarMembroPorEmail: async () => ({ ...membro }),
    emailEmUsoPorOutro: async () => false,
    atualizarDadosMembro: async (_id, d) => ({ ...membro, ...d }),
    atualizarSenhaMembro: async () => {},
    buscarCotaDoMembro: async () => ({ ...cota }),
    buscarUsinaPorId: async () => ({ ...usina }),
    listarContratosDoMembro: async () => [],
    ...parcial,
  };
}

const status = async (promessa: Promise<unknown>) => {
  try {
    await promessa;
  } catch (erro) {
    return (erro as ErroHttp).status;
  }
  return 200;
};

test("obterPerfil: exige email ou id e devolve 404 se não achar", async () => {
  assert.equal(await status(obterPerfil({}, depsFalsas())), 400);
  assert.equal(
    await status(obterPerfil({ email: "x@y.com" }, depsFalsas({ buscarMembroPorEmail: async () => null }))),
    404,
  );
  const perfil = await obterPerfil({ email: "joao@email.com" }, depsFalsas());
  assert.equal(perfil.membro.nome, "João Oliveira");
});

test("editarPerfil: grava dados normalizados e recusa e-mail de outro membro", async () => {
  let gravado: any;
  const perfil = await editarPerfil(
    ID,
    { nome: "João  Silva", email: "NOVO@email.com", telefone: "(19) 98888-7777" },
    depsFalsas({
      atualizarDadosMembro: async (_id, d) => {
        gravado = d;
        return { ...membro, ...d };
      },
    }),
  );
  assert.deepEqual(gravado, { nome: "João Silva", email: "novo@email.com", telefone: "19988887777" });
  assert.equal(perfil.membro.email, "novo@email.com");

  assert.equal(
    await status(
      editarPerfil(ID, { nome: "João Silva", email: "a@b.co" }, depsFalsas({ emailEmUsoPorOutro: async () => true })),
    ),
    409,
  );
  assert.equal(await status(editarPerfil(ID, { nome: "só", email: "a@b.co" }, depsFalsas())), 400);
  assert.equal(
    await status(editarPerfil(ID, { nome: "João Silva", email: "a@b.co" }, depsFalsas({ buscarMembroPorId: async () => null }))),
    404,
  );
});

test("alterarSenha: confere a senha atual e guarda só o hash da nova", async () => {
  const hashAtual = await gerarHashSenha("antiga123");
  let guardado = "";
  const deps = depsFalsas({
    buscarMembroPorId: async () => ({ ...membro, senha_hash: hashAtual }),
    atualizarSenhaMembro: async (_id, h) => {
      guardado = h;
    },
  });

  assert.equal(await status(alterarSenha(ID, { senha_atual: "errada1", nova_senha: "nova1234" }, deps)), 401);
  assert.equal(guardado, "");

  await alterarSenha(ID, { senha_atual: "antiga123", nova_senha: "nova1234", confirmar_senha: "nova1234" }, deps);
  assert.notEqual(guardado, "nova1234");
  assert.equal(await verificarSenha("nova1234", guardado), true);
});

test("alterarSenha: conta sem senha_hash não passa (define a primeira senha pelo Esqueci a senha)", async () => {
  let guardado = "";
  const codigo = await status(
    alterarSenha(
      ID,
      { senha_atual: "qualquer", nova_senha: "nova1234" },
      depsFalsas({
        buscarMembroPorId: async () => ({ ...membro, senha_hash: undefined }),
        atualizarSenhaMembro: async (_id, h) => {
          guardado = h;
        },
      }),
    ),
  );
  assert.equal(codigo, 401);
  assert.equal(guardado, "");
});

test("obterContrato: 404 sem contrato, dados completos com contrato", async () => {
  assert.equal(await status(obterContrato(ID, depsFalsas())), 404);
  const contrato = await obterContrato(
    ID,
    depsFalsas({
      listarContratosDoMembro: async () => [{ numero: "SOLIS-1", status: "ativo", data_assinatura: "2025-03-01T00:00:00Z" }],
    }),
  );
  assert.equal(contrato.numero, "SOLIS-1");
  assert.equal(contrato.membro.nome, "João Oliveira");
  assert.equal(contrato.usina?.nome, "Usina Solis");
});
