//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// regras de negócio do perfil do membro:
// consultar perfil (avatar, nome, e-mail, card do consórcio), editar dados,
// alterar senha e consultar o contrato do consórcio
//
// os acessos ao banco vêm por "deps" (padrão: perfil_repo) para poderem ser trocados nos testes

import { gerarHashSenha, verificarSenha } from "./perfil_senha";
import * as repoReal from "./perfil_repo";
import type { Doc } from "./perfil_repo";
import {
  DadosPerfilEntrada,
  DadosSenhaEntrada,
  ErroHttp,
  validarDadosPerfil,
  validarDadosSenha,
} from "./perfil_validacao";

export type DepsPerfil = Pick<
  typeof repoReal,
  | "buscarMembroPorId"
  | "buscarMembroPorEmail"
  | "emailEmUsoPorOutro"
  | "atualizarDadosMembro"
  | "atualizarSenhaMembro"
  | "buscarCotaDoMembro"
  | "buscarUsinaPorId"
  | "listarContratosDoMembro"
>;

// tipos de usuario que enxergam o botao "Painel Administrador"
const TIPOS_ADMIN = ["admin", "administrador"];

export type RespostaPerfil = {
  membro: {
    id: string;
    nome: string;
    inicial: string;
    email: string;
    telefone: string | null;
    tipo_usuario: string;
    eh_admin: boolean;
  };
  consorcio: {
    cota_percentual: number | null;
    membro_desde: string | null; // data ISO
    usina: { id: string; nome: string; localizacao: string | null } | null;
  };
};

export type RespostaContrato = {
  numero: string | null;
  status: string;
  membro: { nome: string; email: string };
  usina: { nome: string; localizacao: string | null } | null;
  cota_percentual: number | null;
  tarifa_kwh: number | null;
  data_assinatura: string | null;
  data_inicio: string | null;
  data_fim: string | null;
  vigencia_meses: number | null;
  clausulas: { titulo: string; texto: string }[];
  observacoes: string | null;
  arquivo_url: string | null;
};

// ---------- funções auxiliares (puras) ----------

function paraIso(valor: unknown): string | null {
  if (!valor) return null;
  const data = valor instanceof Date ? valor : new Date(valor as string);
  return Number.isNaN(data.getTime()) ? null : data.toISOString();
}

function paraNumeroOuNulo(valor: unknown): number | null {
  if (valor === null || valor === undefined || valor === "") return null;
  const numero = Number(valor);
  return Number.isFinite(numero) ? numero : null;
}

function idTexto(valor: unknown): string {
  return valor ? String(valor) : "";
}

// quando a conta foi criada: data_cadastro > createdAt > início da cota > data embutida no _id
function descobrirMembroDesde(membro: Doc, cota: Doc | null): string | null {
  const direta = paraIso(membro.data_cadastro) ?? paraIso(membro.createdAt);
  if (direta) return direta;

  const daCota = paraIso(cota?.data_inicio);
  if (daCota) return daCota;

  const objectId = idTexto(membro._id);
  if (/^[0-9a-f]{24}$/i.test(objectId)) {
    return new Date(parseInt(objectId.slice(0, 8), 16) * 1000).toISOString();
  }
  return null;
}

export function ehAdministrador(membro: Doc): boolean {
  return TIPOS_ADMIN.includes(String(membro.tipo_usuario ?? "").trim().toLowerCase());
}

export function montarPerfil(membro: Doc, cota: Doc | null, usina: Doc | null): RespostaPerfil {
  const nome = String(membro.nome ?? "").trim();
  return {
    membro: {
      id: idTexto(membro._id),
      nome,
      inicial: nome.charAt(0).toUpperCase(),
      email: String(membro.email ?? ""),
      telefone: membro.telefone ? String(membro.telefone) : null,
      tipo_usuario: String(membro.tipo_usuario ?? "membro"),
      eh_admin: ehAdministrador(membro),
    },
    consorcio: {
      cota_percentual: paraNumeroOuNulo(cota?.percentual),
      membro_desde: descobrirMembroDesde(membro, cota),
      usina: usina
        ? {
            id: idTexto(usina._id),
            nome: String(usina.nome ?? ""),
            localizacao: usina.localizacao ? String(usina.localizacao) : null,
          }
        : null,
    },
  };
}

// entre varios contratos, mostra o ativo mais recente; se não houver, o mais recente de todos
// (a lista já chega ordenada do mais novo para o mais antigo)
export function escolherContrato(contratos: Doc[]): Doc | null {
  if (contratos.length === 0) return null;
  const ativo = contratos.find(
    (c) => String(c.status ?? "ativo").toLowerCase() === "ativo",
  );
  return ativo ?? contratos[0];
}

export function montarContrato(
  contrato: Doc,
  membro: Doc,
  cota: Doc | null,
  usina: Doc | null,
): RespostaContrato {
  const clausulas = Array.isArray(contrato.clausulas) ? contrato.clausulas : [];
  return {
    numero: contrato.numero ? String(contrato.numero) : null,
    status: String(contrato.status ?? "ativo").toLowerCase(),
    membro: { nome: String(membro.nome ?? ""), email: String(membro.email ?? "") },
    usina: usina
      ? {
          nome: String(usina.nome ?? ""),
          localizacao: usina.localizacao ? String(usina.localizacao) : null,
        }
      : null,
    cota_percentual:
      paraNumeroOuNulo(contrato.percentual_cota) ?? paraNumeroOuNulo(cota?.percentual),
    tarifa_kwh: paraNumeroOuNulo(contrato.tarifa_kwh) ?? paraNumeroOuNulo(cota?.tarifa_kwh),
    data_assinatura: paraIso(contrato.data_assinatura),
    data_inicio: paraIso(contrato.data_inicio) ?? paraIso(cota?.data_inicio),
    data_fim: paraIso(contrato.data_fim),
    vigencia_meses: paraNumeroOuNulo(contrato.vigencia_meses),
    clausulas: clausulas
      .filter((c: Doc) => c && (c.titulo || c.texto))
      .map((c: Doc) => ({ titulo: String(c.titulo ?? ""), texto: String(c.texto ?? "") })),
    observacoes: contrato.observacoes ? String(contrato.observacoes) : null,
    arquivo_url: contrato.arquivo_url ? String(contrato.arquivo_url) : null,
  };
}

// ---------- casos de uso ----------

async function exigirMembro(membroId: string, deps: DepsPerfil): Promise<Doc> {
  const membro = await deps.buscarMembroPorId(membroId);
  if (!membro) throw new ErroHttp(404, "Membro não encontrado");
  return membro;
}

async function carregarCotaEUsina(membro: Doc, deps: DepsPerfil) {
  const cota = await deps.buscarCotaDoMembro(idTexto(membro._id));
  const usinaId = idTexto(membro.usina_id) || idTexto(cota?.usina_id);
  const usina = await deps.buscarUsinaPorId(usinaId || undefined);
  return { cota, usina };
}

// GET /perfil?email=... ou ?membro_id=...
export async function obterPerfil(
  params: { membroId?: string; email?: string },
  deps: DepsPerfil = repoReal,
): Promise<RespostaPerfil> {
  let membro: Doc | null = null;
  if (params.membroId) {
    membro = await deps.buscarMembroPorId(params.membroId);
  } else if (params.email && params.email.trim() !== "") {
    membro = await deps.buscarMembroPorEmail(params.email);
  } else {
    throw new ErroHttp(400, "Informe membro_id ou email");
  }
  if (!membro) throw new ErroHttp(404, "Membro não encontrado");

  const { cota, usina } = await carregarCotaEUsina(membro, deps);
  return montarPerfil(membro, cota, usina);
}

// PUT /perfil/:id  (nome, e-mail, telefone)
export async function editarPerfil(
  membroId: string,
  entrada: DadosPerfilEntrada,
  deps: DepsPerfil = repoReal,
): Promise<RespostaPerfil> {
  const dados = validarDadosPerfil(entrada);
  await exigirMembro(membroId, deps);

  if (await deps.emailEmUsoPorOutro(dados.email, membroId)) {
    throw new ErroHttp(409, "Este e-mail já está em uso", {
      email: "Este e-mail já está em uso",
    });
  }

  const atualizado = await deps.atualizarDadosMembro(membroId, dados);
  if (!atualizado) throw new ErroHttp(404, "Membro não encontrado");

  const { cota, usina } = await carregarCotaEUsina(atualizado, deps);
  return montarPerfil(atualizado, cota, usina);
}

// PUT /perfil/:id/senha
export async function alterarSenha(
  membroId: string,
  entrada: DadosSenhaEntrada,
  deps: DepsPerfil = repoReal,
): Promise<void> {
  const { senhaAtual, novaSenha } = validarDadosSenha(entrada);
  const membro = await exigirMembro(membroId, deps);

  // a senha atual é sempre conferida (conta sem senha_hash não consegue nem entrar:
  // ela define a primeira senha pelo "Esqueci a senha")
  const hashGuardado = typeof membro.senha_hash === "string" ? membro.senha_hash : "";
  if (hashGuardado === "" || !(await verificarSenha(senhaAtual, hashGuardado))) {
    throw new ErroHttp(401, "Senha atual incorreta", {
      senha_atual: "Senha atual incorreta",
    });
  }

  await deps.atualizarSenhaMembro(membroId, await gerarHashSenha(novaSenha));
}

// GET /perfil/:id/contrato
export async function obterContrato(
  membroId: string,
  deps: DepsPerfil = repoReal,
): Promise<RespostaContrato> {
  const membro = await exigirMembro(membroId, deps);
  const contrato = escolherContrato(await deps.listarContratosDoMembro(membroId));
  if (!contrato) throw new ErroHttp(404, "Nenhum contrato encontrado para este membro");

  const cota = await deps.buscarCotaDoMembro(membroId);
  const usinaId = idTexto(contrato.usina_id) || idTexto(membro.usina_id) || idTexto(cota?.usina_id);
  const usina = await deps.buscarUsinaPorId(usinaId || undefined);
  return montarContrato(contrato, membro, cota, usina);
}
