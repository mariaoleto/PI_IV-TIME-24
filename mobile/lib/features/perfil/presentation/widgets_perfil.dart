//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// pequenos widgets reutilizados nas telas de Perfil (cabeçalho, avatar, cartão e item de menu)
// as cores e a estrutura (EstruturaAuth) vêm de auth/presentation/widgets_auth.dart

import 'package:flutter/material.dart';

import '../../auth/presentation/widgets_auth.dart';

// linha do topo das telas internas: botão voltar + título
class CabecalhoTelaInterna extends StatelessWidget {
  const CabecalhoTelaInterna({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 24, 20),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Voltar',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// avatar com a inicial do nome
class AvatarPerfil extends StatelessWidget {
  const AvatarPerfil({super.key, required this.inicial, this.raio = 42});

  final String inicial;
  final double raio;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: raio,
      backgroundColor: corDestaque,
      child: Text(
        inicial,
        style: TextStyle(
          color: corPrimaria,
          fontSize: raio * 0.9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// cartão branco com borda suave
class CartaoPerfil extends StatelessWidget {
  const CartaoPerfil({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: child,
    );
  }
}

// título de seção dentro do conteúdo
class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        texto,
        style: const TextStyle(
          color: corPrimaria,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// item do menu do perfil (Editar perfil, Segurança, Contrato)
class ItemMenuPerfil extends StatelessWidget {
  const ItemMenuPerfil({
    super.key,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.aoTocar,
  });

  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: corPrimaria.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: corPrimaria, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: corPrimaria,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9AA2AF)),
          ],
        ),
      ),
    );
  }
}

// mensagem de erro com botão "Tentar novamente"
class EstadoErro extends StatelessWidget {
  const EstadoErro({super.key, required this.mensagem, required this.aoTentar});

  final String mensagem;
  final VoidCallback aoTentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42, color: Color(0xFF9AA2AF)),
          const SizedBox(height: 12),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
          ),
          const SizedBox(height: 20),
          BotaoPrincipalAuth(texto: 'Tentar novamente', aoPressionar: aoTentar),
        ],
      ),
    );
  }
}
