import 'package:flutter/material.dart';

import 'features/auth/presentation/tela_login.dart';
import 'src/geracao_consumos/repositorio_energia.dart';
import 'src/geracao_consumos/tela_energia.dart';

void main() {
  runApp(const AplicativoSolis());
}

class AplicativoSolis extends StatelessWidget {
  const AplicativoSolis({super.key, RepositorioEnergia? repositorioEnergia})
    : _repositorioEnergia = repositorioEnergia;

  final RepositorioEnergia? _repositorioEnergia;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF142340),
          primary: const Color(0xFF142340),
          secondary: const Color(0xFFF4A12B),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: _repositorioEnergia != null
          ? TelaEnergia(repositorio: _repositorioEnergia)
          : const TelaLogin(),
    );
  }
}
