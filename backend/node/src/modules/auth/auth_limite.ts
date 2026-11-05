//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// limita tentativas de login erradas por e-mail (proteção contra adivinhar a senha)
// guarda na memória do servidor: reiniciar o servidor zera a contagem

export class LimiteTentativas {
  private falhas = new Map<string, { quantidade: number; desde: number }>();

  constructor(
    private maximo = 5,
    private janelaMs = 15 * 60 * 1000,
    private agora: () => number = Date.now,
  ) {}

  bloqueado(chave: string): boolean {
    const registro = this.falhas.get(chave);
    if (!registro) return false;
    if (this.agora() - registro.desde > this.janelaMs) {
      this.falhas.delete(chave);
      return false;
    }
    return registro.quantidade >= this.maximo;
  }

  registrarFalha(chave: string) {
    const registro = this.falhas.get(chave);
    if (!registro || this.agora() - registro.desde > this.janelaMs) {
      this.falhas.set(chave, { quantidade: 1, desde: this.agora() });
    } else {
      registro.quantidade += 1;
    }
  }

  limpar(chave: string) {
    this.falhas.delete(chave);
  }
}
