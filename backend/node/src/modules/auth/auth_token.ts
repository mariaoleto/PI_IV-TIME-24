//Autora: Ana Luísa Maso Mafra | RA: 25007997
 
// significado do arquivo:
// cria e confere o token JWT (HS256) usado no login de membro e de administrador
// o token guarda o id do membro (sub) e o tipo da conta ("membro" ou "admin")

import jwt, { SignOptions } from "jsonwebtoken";
import { lerConfigAuth } from "./auth_config";

export type TipoConta = "membro" | "admin";

export type UsuarioToken = { id: string; tipo: TipoConta };

export function gerarToken(id: string, tipo: TipoConta): string {
  const config = lerConfigAuth();
  const expiresIn = (tipo === "admin" ? config.expiraEmAdmin : config.expiraEmMembro) as SignOptions["expiresIn"];
  return jwt.sign({ tipo }, config.segredo, {
    subject: id,
    expiresIn,
    algorithm: "HS256",
  });
}

// devolve os dados do token, ou null se ele for inválido, adulterado ou estiver expirado
export function verificarToken(token: string): UsuarioToken | null {
  try {
    const { segredo } = lerConfigAuth();
    // fixar o algoritmo evita aceitar tokens "alg: none" ou assinados com outro método
    const dados = jwt.verify(token, segredo, { algorithms: ["HS256"] });
    if (typeof dados === "string" || typeof dados.sub !== "string") return null;
    if (dados.tipo !== "membro" && dados.tipo !== "admin") return null;
    return { id: dados.sub, tipo: dados.tipo };
  } catch {
    return null;
  }
}
