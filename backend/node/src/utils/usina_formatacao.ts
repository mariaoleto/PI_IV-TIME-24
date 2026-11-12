export function formatarLocalizacaoUsina(valor: unknown): string | null {
  if (valor == null) return null;
  if (typeof valor === "string") {
    const limpo = valor.trim();
    return limpo.length > 0 ? limpo : null;
  }
  if (typeof valor === "object") {
    const obj = valor as Record<string, unknown>;
    const cidade = typeof obj.cidade === "string" ? obj.cidade.trim() : "";
    const estado = typeof obj.estado === "string" ? obj.estado.trim() : "";
    if (cidade && estado) return `${cidade} - ${estado}`;
    if (cidade || estado) return cidade || estado;
  }
  return null;
}

export function lerCapacidadeUsina(
  usina: Record<string, unknown> | null | undefined,
): number {
  if (!usina) return 0;
  const candidatos = [
    usina.potencia,
    usina.potencia_instalada_kwp,
    usina.capacidade_kwp,
  ];
  for (const valor of candidatos) {
    if (valor === null || valor === undefined || valor === "") continue;
    const numero = Number(valor);
    if (Number.isFinite(numero) && numero > 0) return numero;
  }
  return 0;
}

