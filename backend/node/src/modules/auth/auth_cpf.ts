//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// normalização e validação de CPF (funções puras)
// o CPF é guardado somente com os 11 dígitos (sem pontos e traço)

// "529.982.247-25" -> "52998224725"
export function normalizarCpf(valor: unknown): string {
  return typeof valor === "string" ? valor.replace(/\D/g, "") : "";
}

function digitoVerificador(base: string): number {
  // pesos decrescentes: 10..2 para os 9 primeiros dígitos, 11..2 para os 10 primeiros
  let soma = 0;
  for (let i = 0; i < base.length; i++) {
    soma += Number(base[i]) * (base.length + 1 - i);
  }
  const resto = (soma * 10) % 11;
  return resto === 10 ? 0 : resto;
}

// confere o tamanho, rejeita sequências repetidas (111.111.111-11) e confere os 2 dígitos verificadores
export function cpfValido(valor: unknown): boolean {
  const cpf = normalizarCpf(valor);
  if (cpf.length !== 11 || /^(\d)\1{10}$/.test(cpf)) return false;
  const d1 = digitoVerificador(cpf.slice(0, 9));
  const d2 = digitoVerificador(cpf.slice(0, 10));
  return d1 === Number(cpf[9]) && d2 === Number(cpf[10]);
}
