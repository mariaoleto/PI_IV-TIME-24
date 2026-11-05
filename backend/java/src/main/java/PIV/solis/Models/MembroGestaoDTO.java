// Autora: Marina Hehnes Espósito.
// Propósito: apresenta os dados do membro e sua cota na gestão da usina.
package PIV.solis.Models;

public record MembroGestaoDTO(
        String id,
        String nome,
        String email,
        double cota,
        String status) {
}
