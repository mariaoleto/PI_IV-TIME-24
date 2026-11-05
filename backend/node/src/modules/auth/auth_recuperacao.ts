//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// código de 6 dígitos da recuperação de senha: geração e conferência
// o código NUNCA é guardado em texto: só um HMAC dele (com o JWT_SECRET e o id do membro)

import { createHmac, randomInt, timingSafeEqual } from "node:crypto";
import { lerConfigAuth } from "./auth_config";

export const VALIDADE_CODIGO_MS = 15 * 60 * 1000; // 15 minutos
export const INTERVALO_REENVIO_MS = 60 * 1000; // 1 envio por minuto
export const MAXIMO_TENTATIVAS_CODIGO = 5;

export function gerarCodigo(): string {
  return String(randomInt(0, 1_000_000)).padStart(6, "0");
}

export function hashCodigo(membroId: string, codigo: string): string {
  return createHmac("sha256", lerConfigAuth().segredo)
    .update(`${membroId}:${codigo}`)
    .digest("hex");
}

export function codigoConfere(membroId: string, codigo: string, hashGuardado: string): boolean {
  const esperado = Buffer.from(hashGuardado, "hex");
  const obtido = Buffer.from(hashCodigo(membroId, codigo), "hex");
  return esperado.length === obtido.length && timingSafeEqual(esperado, obtido);
}
