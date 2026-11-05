//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// validações e normalizações do perfil do membro (nome, e-mail, telefone e senha)
// são funções puras (sem banco), por isso são fáceis de testar

// erro com status HTTP, convertido em resposta JSON pelo controller do perfil
export class ErroHttp extends Error {
  constructor(
    public status: number,
    mensagem: string,
    public campos: Record<string, string> = {},
  ) {
    super(mensagem);
  }
}

export type DadosPerfilEntrada = {
  nome?: unknown;
  email?: unknown;
  telefone?: unknown;
};

export type DadosPerfilValidos = {
  nome: string;
  email: string;
  telefone: string | null; // somente dígitos (DDD + número) ou null quando removido
};

const REGEX_EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const TAMANHO_MINIMO_SENHA = 6; // mesma regra do validarSenha do app
export const TAMANHO_MAXIMO_SENHA = 128;

function texto(valor: unknown): string {
  return typeof valor === "string" ? valor.trim() : "";
}

// guarda só os dígitos do telefone. aceita "(19) 99999-8888" e "+55 19 99999-8888"
// retorna null se estiver vazio e "invalido" se não tiver DDD + 8 ou 9 dígitos
export function normalizarTelefone(valor: unknown): string | null | "invalido" {
  const bruto = texto(valor);
  if (bruto === "") return null;

  let digitos = bruto.replace(/\D/g, "");
  if ((digitos.length === 12 || digitos.length === 13) && digitos.startsWith("55")) {
    digitos = digitos.slice(2);
  }
  if (digitos.length !== 10 && digitos.length !== 11) return "invalido";
  // DDD não começa com 0 e celular (11 dígitos) começa com 9 depois do DDD
  if (digitos.startsWith("0")) return "invalido";
  if (digitos.length === 11 && digitos[2] !== "9") return "invalido";
  return digitos;
}

// valida e normaliza os dados da tela "Editar perfil"
// lança ErroHttp 400 com o erro de cada campo
export function validarDadosPerfil(entrada: DadosPerfilEntrada): DadosPerfilValidos {
  const campos: Record<string, string> = {};

  const nome = texto(entrada.nome).replace(/\s+/g, " ");
  if (nome === "") campos.nome = "Informe seu nome completo";
  else if (nome.split(" ").length < 2) campos.nome = "Informe nome e sobrenome";
  else if (nome.length > 120) campos.nome = "Nome muito longo";

  const email = texto(entrada.email).toLowerCase();
  if (email === "") campos.email = "Informe seu e-mail";
  else if (!REGEX_EMAIL.test(email) || email.length > 160) campos.email = "E-mail inválido";

  const telefone = normalizarTelefone(entrada.telefone);
  if (telefone === "invalido") campos.telefone = "Telefone inválido. Use DDD + número";

  if (Object.keys(campos).length > 0) {
    throw new ErroHttp(400, "Dados inválidos", campos);
  }
  return { nome, email, telefone: telefone as string | null };
}

export type DadosSenhaEntrada = {
  senha_atual?: unknown;
  nova_senha?: unknown;
  confirmar_senha?: unknown;
};

// valida o formulário de alterar senha (as senhas não são alteradas com trim)
// lança ErroHttp 400 com o erro de cada campo
export function validarDadosSenha(entrada: DadosSenhaEntrada) {
  const campos: Record<string, string> = {};
  const atual = typeof entrada.senha_atual === "string" ? entrada.senha_atual : "";
  const nova = typeof entrada.nova_senha === "string" ? entrada.nova_senha : "";
  const confirmar =
    typeof entrada.confirmar_senha === "string" ? entrada.confirmar_senha : undefined;

  if (atual === "") campos.senha_atual = "Informe sua senha atual";

  if (nova === "") campos.nova_senha = "Informe a nova senha";
  else if (nova.length < TAMANHO_MINIMO_SENHA)
    campos.nova_senha = `A senha deve ter ao menos ${TAMANHO_MINIMO_SENHA} caracteres`;
  else if (nova.length > TAMANHO_MAXIMO_SENHA) campos.nova_senha = "Senha muito longa";
  else if (nova === atual) campos.nova_senha = "A nova senha deve ser diferente da atual";

  // a confirmação é opcional na API (o app já confere), mas se vier tem que bater
  if (confirmar !== undefined && confirmar !== nova) {
    campos.confirmar_senha = "As senhas não conferem";
  }

  if (Object.keys(campos).length > 0) {
    throw new ErroHttp(400, "Dados inválidos", campos);
  }
  return { senhaAtual: atual, novaSenha: nova };
}
