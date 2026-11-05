//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// gera e confere o hash da senha do membro usando o scrypt do próprio Node
// (não precisa instalar bcrypt). a senha nunca é guardada em texto puro
//
// formato guardado em membros.senha_hash: "scrypt$<salt base64>$<hash base64>"
// quando o login real for criado, ele deve usar verificarSenha() deste arquivo

import { randomBytes, scrypt, timingSafeEqual } from "node:crypto";

const TAMANHO_CHAVE = 64;

function derivar(senha: string, salt: Buffer): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    scrypt(senha, salt, TAMANHO_CHAVE, (erro, chave) =>
      erro ? reject(erro) : resolve(chave),
    );
  });
}

export async function gerarHashSenha(senha: string): Promise<string> {
  const salt = randomBytes(16);
  const chave = await derivar(senha, salt);
  return `scrypt$${salt.toString("base64")}$${chave.toString("base64")}`;
}

export async function verificarSenha(senha: string, hashGuardado: string): Promise<boolean> {
  const partes = hashGuardado.split("$");
  if (partes.length !== 3 || partes[0] !== "scrypt") return false;

  const salt = Buffer.from(partes[1], "base64");
  const esperado = Buffer.from(partes[2], "base64");
  if (esperado.length !== TAMANHO_CHAVE) return false;

  const obtido = await derivar(senha, salt);
  return timingSafeEqual(obtido, esperado);
}
