// Autora: Marina Hehnes Espósito.
// Propósito: recebe os dados necessários para cadastrar ou atualizar uma usina.
package PIV.solis.Models;

public record UsinaRequest(
        String nome,
        Double potencia,
        String distribuidora,
        String local) {
}
