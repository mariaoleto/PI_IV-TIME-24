//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// lê as configurações de autenticação das variáveis de ambiente (.env)
// a leitura é feita na hora do uso (e não na importação) para facilitar os testes
//
// variáveis:
//   JWT_SECRET            obrigatória, mínimo de 16 caracteres (use um texto longo e aleatório)
//   JWT_EXPIRA_EM         opcional, validade do token de membro (padrão "7d")
//   JWT_EXPIRA_ADMIN_EM   opcional, validade do token de administrador (padrão "8h")

export const TAMANHO_MINIMO_SEGREDO = 16;

export function lerConfigAuth() {
  const segredo = process.env.JWT_SECRET ?? "";
  if (segredo.length < TAMANHO_MINIMO_SEGREDO) {
    throw new Error(
      `JWT_SECRET ausente ou curto demais (mínimo de ${TAMANHO_MINIMO_SEGREDO} caracteres)`,
    );
  }
  return {
    segredo,
    expiraEmMembro: process.env.JWT_EXPIRA_EM || "7d",
    expiraEmAdmin: process.env.JWT_EXPIRA_ADMIN_EM || "8h",
  };
}
