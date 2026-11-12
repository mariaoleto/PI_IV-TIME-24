//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// acesso ao banco (coleção "membros") para cadastro, login e recuperação de senha
// a busca por e-mail reaproveita a do módulo de perfil

import { Membro } from "../geracao_creditos/energia_model";
import { idObjeto } from "../perfil/perfil_repo";
import type { Doc } from "../perfil/perfil_repo";

export { buscarMembroPorEmail } from "../perfil/perfil_repo";

export type NovoMembro = {
  nome: string;
  email: string;
  cpf: string; // somente dígitos
  telefone: string | null;
  senha_hash: string;
  tipo_usuario: "membro" | "admin";
  data_cadastro: Date;
  ultimo_login_em: Date;
};

export type DadosComplementoCadastro = {
  nome: string;
  cpf: string;
  telefone: string | null;
  senha_hash: string;
  tipo_usuario: "membro" | "admin";
  data_cadastro: Date;
  ultimo_login_em: Date;
};

export async function criarMembro(dados: NovoMembro): Promise<Doc> {
  const { telefone, ...resto } = dados;
  const criado = await Membro.create(
    telefone
      ? { ...resto, telefone, cadastro_concluido: true }
      : { ...resto, cadastro_concluido: true },
  );
  return criado.toObject() as Doc;
}

// completa um membro pré-cadastrado pelo administrador preservando _id e usina_id
export async function completarPreCadastroMembro(
  membroId: string,
  dados: DadosComplementoCadastro,
): Promise<Doc | null> {
  const { telefone, ...resto } = dados;
  const setCampos: Record<string, unknown> = {
    ...resto,
    atualizado_em: dados.ultimo_login_em,
    cadastro_concluido: true,
  };
  if (telefone) {
    setCampos.telefone = telefone;
  }

  return Membro.findOneAndUpdate(
    {
      _id: idObjeto(membroId, "membro_id"),
      $or: [
        { senha_hash: { $exists: false } },
        { senha_hash: null },
        { senha_hash: "" },
      ],
    },
    { $set: setCampos },
    { new: true },
  ).lean<Doc>();
}

// usado para impedir dois cadastros com o mesmo CPF
export function buscarMembroPorCpf(cpf: string) {
  return Membro.findOne({ cpf }).lean<Doc>();
}

export async function registrarLogin(membroId: string) {
  await Membro.updateOne(
    { _id: idObjeto(membroId, "membro_id") },
    { $set: { ultimo_login_em: new Date() } },
  );
}

export async function salvarRecuperacao(
  membroId: string,
  dados: { codigoHash: string; expiraEm: Date; enviadaEm: Date },
) {
  await Membro.updateOne(
    { _id: idObjeto(membroId, "membro_id") },
    {
      $set: {
        recuperacao_codigo_hash: dados.codigoHash,
        recuperacao_expira_em: dados.expiraEm,
        recuperacao_enviada_em: dados.enviadaEm,
        recuperacao_tentativas: 0,
      },
    },
  );
}

// soma 1 tentativa errada de código (operação atômica no banco)
export async function registrarTentativaRecuperacao(membroId: string) {
  await Membro.updateOne(
    { _id: idObjeto(membroId, "membro_id") },
    { $inc: { recuperacao_tentativas: 1 } },
  );
}

// grava a nova senha e apaga os dados da recuperação (o código só vale uma vez)
export async function gravarNovaSenha(membroId: string, senhaHash: string) {
  await Membro.updateOne(
    { _id: idObjeto(membroId, "membro_id") },
    {
      $set: { senha_hash: senhaHash, senha_alterada_em: new Date() },
      $unset: {
        recuperacao_codigo_hash: "",
        recuperacao_expira_em: "",
        recuperacao_tentativas: "",
      },
    },
  );
}
