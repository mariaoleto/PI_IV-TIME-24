//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// validação dos formulários de cadastro, login e recuperação de senha (funções puras)
// nome, e-mail, telefone e regras de senha reaproveitam perfil_validacao.ts

import { cpfValido, normalizarCpf } from "./auth_cpf";
import {
  ErroHttp,
  TAMANHO_MAXIMO_SENHA,
  TAMANHO_MINIMO_SENHA,
  validarDadosPerfil,
} from "../perfil/perfil_validacao";

const REGEX_EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function texto(valor: unknown) {
  return typeof valor === "string" ? valor.trim() : "";
}

function erroSenha(senha: string): string | null {
  if (senha === "") return "Informe uma senha";
  if (senha.length < TAMANHO_MINIMO_SENHA)
    return `A senha deve ter ao menos ${TAMANHO_MINIMO_SENHA} caracteres`;
  if (senha.length > TAMANHO_MAXIMO_SENHA) return "Senha muito longa";
  return null;
}

// exigirCpf: o cadastro pelo app sempre exige CPF; só o script criar-admin dispensa
export function validarCadastro(
  entrada: {
    nome?: unknown;
    email?: unknown;
    cpf?: unknown;
    telefone?: unknown;
    senha?: unknown;
    confirmar_senha?: unknown;
  },
  opcoes: { exigirCpf: boolean } = { exigirCpf: true },
) {
  const campos: Record<string, string> = {};
  let dados: ReturnType<typeof validarDadosPerfil> | null = null;

  try {
    dados = validarDadosPerfil(entrada);
  } catch (erro) {
    if (!(erro instanceof ErroHttp)) throw erro;
    Object.assign(campos, erro.campos);
  }

  const cpf = normalizarCpf(entrada.cpf);
  if (cpf === "") {
    if (opcoes.exigirCpf) campos.cpf = "Informe seu CPF";
  } else if (!cpfValido(cpf)) {
    campos.cpf = "CPF inválido";
  }

  const senha = typeof entrada.senha === "string" ? entrada.senha : "";
  const erro = erroSenha(senha);
  if (erro) campos.senha = erro;
  if (typeof entrada.confirmar_senha === "string" && entrada.confirmar_senha !== senha) {
    campos.confirmar_senha = "As senhas não conferem";
  }

  if (Object.keys(campos).length > 0 || !dados) {
    throw new ErroHttp(400, "Dados inválidos", campos);
  }
  return { ...dados, cpf: cpf === "" ? null : cpf, senha };
}

export function validarLogin(entrada: { email?: unknown; senha?: unknown; perfil?: unknown }) {
  const campos: Record<string, string> = {};
  const email = texto(entrada.email).toLowerCase();
  const senha = typeof entrada.senha === "string" ? entrada.senha : "";

  if (email === "") campos.email = "Informe seu e-mail";
  if (senha === "") campos.senha = "Informe sua senha";
  if (Object.keys(campos).length > 0) throw new ErroHttp(400, "Dados inválidos", campos);

  return { email, senha, comoAdmin: entrada.perfil === "admin" };
}

export function validarEmailRecuperacao(entrada: { email?: unknown }) {
  const email = texto(entrada.email).toLowerCase();
  if (!REGEX_EMAIL.test(email)) {
    throw new ErroHttp(400, "Dados inválidos", { email: "E-mail inválido" });
  }
  return email;
}

export function validarRedefinicao(entrada: {
  email?: unknown;
  codigo?: unknown;
  nova_senha?: unknown;
}) {
  const campos: Record<string, string> = {};
  const email = texto(entrada.email).toLowerCase();
  const codigo = texto(entrada.codigo);
  const novaSenha = typeof entrada.nova_senha === "string" ? entrada.nova_senha : "";

  if (!REGEX_EMAIL.test(email)) campos.email = "E-mail inválido";
  if (!/^\d{6}$/.test(codigo)) campos.codigo = "O código tem 6 dígitos";
  const erro = erroSenha(novaSenha);
  if (erro) campos.nova_senha = erro;

  if (Object.keys(campos).length > 0) throw new ErroHttp(400, "Dados inválidos", campos);
  return { email, codigo, novaSenha };
}
