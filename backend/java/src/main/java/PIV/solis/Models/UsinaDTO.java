// Autora: Marina Hehnes Espósito.
// Propósito: transfere os dados de usina nas respostas da API de gestão.
package PIV.solis.Models;

public record UsinaDTO(
        String id,
        String nome,
        Double potencia,
        String distribuidora,
        String codigo,
        String local) {

    public UsinaDTO(Usina usina) {
        this(
                usina.id().toHexString(),
                usina.nome(),
                usina.potencia(),
                usina.distribuidora(),
                usina.codigo(),
                usina.local());
    }
}
