//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// passo 2 do cadastro: telefone (opcional) e senha
// ao concluir, o backend cria a conta (senha com hash) e devolve o token: o usuário já entra logado

import 'package:flutter/material.dart';

import '../../geracao_creditos/domain/repositorio_energia.dart';
import '../../painel_admin/domain/repositorio_painel_admin.dart';
import '../../painel_admin/presentation/tela_painel_admin.dart';
import '../../painel_membro/domain/repositorio_painel_membro.dart';
import '../../painel_membro/presentation/tela_painel_membro.dart';
import '../../perfil/domain/formatadores_perfil.dart';
import '../data/servico_auth.dart';
import '../domain/validadores.dart';
import 'widgets_auth.dart';

class TelaCriarContaPasso2 extends StatefulWidget {
  const TelaCriarContaPasso2({
    super.key,
    required this.nome,
    required this.email,
    required this.cpf,
    this.tipoConta = 'membro',
    this.servicoAuth,
    this.destinoAposCadastro,
  });

  // dados digitados no passo 1
  final String nome;
  final String email;
  final String cpf; // somente dígitos
  final String tipoConta; // 'membro' ou 'admin' (escolhido no passo 1)

  // permitem trocar o serviço e a tela seguinte (útil nos testes)
  final ServicoAuth? servicoAuth;
  final Widget Function(BuildContext contexto, String email)? destinoAposCadastro;

  @override
  State<TelaCriarContaPasso2> createState() => _EstadoTelaCriarContaPasso2();
}

class _EstadoTelaCriarContaPasso2 extends State<TelaCriarContaPasso2> {
  final _formulario = GlobalKey<FormState>();
  late final ServicoAuth _auth = widget.servicoAuth ?? ServicoAuthApi();
  final _telefone = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _carregando = false;

  bool get _ehAdmin => widget.tipoConta == 'admin';

  @override
  void dispose() {
    _telefone.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  String? _validarConfirmacao(String? valor) {
    if ((valor ?? '').isEmpty) return 'Confirme sua senha';
    if (valor != _senha.text) return 'As senhas não conferem';
    return null;
  }

  Future<void> _criarConta() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      final telefone = telefoneSoDigitos(_telefone.text);
      await _auth.cadastrar(
        nome: widget.nome,
        email: widget.email,
        cpf: widget.cpf,
        telefone: telefone.isEmpty ? null : telefone,
        senha: _senha.text,
        tipoConta: widget.tipoConta,
      );
      if (!mounted) return;
      // conta criada e já logada: vai direto para o painel e apaga as telas de cadastro
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (contexto) =>
              widget.destinoAposCadastro?.call(contexto, widget.email) ??
              (_ehAdmin
                  ? TelaPainelAdmin(
                      repositorio: RepositorioApiPainelAdmin(),
                      repositorioEnergia: RepositorioApiEnergia(),
                      nomeAdmin: widget.nome,
                    )
                  : TelaPainelMembro(
                      repositorio: RepositorioApiPainelMembro(),
                      emailMembro: widget.email,
                    )),
        ),
        (rota) => false,
      );
    } catch (erro) {
      if (!mounted) return;
      // se a API apontou o campo com problema (ex.: e-mail já cadastrado), mostra esse erro
      var mensagem = erro.toString().replaceFirst('Exception: ', '');
      var erroDoPasso1 = false;
      if (erro is ErroApiAuth && erro.campos.isNotEmpty) {
        mensagem = erro.campos.values.first;
        // nome, e-mail e CPF são digitados no passo 1: volta para corrigir
        erroDoPasso1 = erro.campos.keys.any(
          (campo) => campo == 'nome' || campo == 'email' || campo == 'cpf',
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
      if (erroDoPasso1) {
        Navigator.of(context).pop();
        return;
      }
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primeiroNome = widget.nome.trim().split(RegExp(r'\s+')).first;

    return EstruturaAuth(
      cabecalho: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.chevron_left, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _barra(corDestaque)),
                const SizedBox(width: 8),
                Expanded(child: _barra(corDestaque)),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'PASSO 2 DE 2',
              style: TextStyle(
                color: Color(0xFF9AA5B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Defina sua senha',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Quase lá, $primeiroNome!',
              style: const TextStyle(color: Color(0xFF9AA5B8), fontSize: 13),
            ),
          ],
        ),
      ),
      conteudo: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CampoAuth(
              rotulo: 'Telefone (opcional)',
              dica: '(00) 00000-0000',
              controlador: _telefone,
              tipoTeclado: TextInputType.phone,
              formatadores: [MascaraTelefone()],
              validador: validarTelefone,
            ),
            const SizedBox(height: 16),
            CampoAuth(
              rotulo: 'Senha',
              dica: 'Mínimo de 6 caracteres',
              controlador: _senha,
              senha: true,
              validador: validarSenha,
            ),
            const SizedBox(height: 16),
            CampoAuth(
              rotulo: 'Confirmar senha',
              dica: 'Repita a senha',
              controlador: _confirmacao,
              senha: true,
              validador: _validarConfirmacao,
            ),
            const SizedBox(height: 24),
            BotaoPrincipalAuth(
              texto: 'Criar conta',
              aoPressionar: _criarConta,
              carregando: _carregando,
            ),
            const SizedBox(height: 20),
            LinkAuth(
              pergunta: 'Já tem conta?',
              acao: 'Entrar',
              // volta até a tela de login (a primeira rota)
              aoPressionar: () =>
                  Navigator.of(context).popUntil((rota) => rota.isFirst),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barra(Color cor) => Container(
    height: 4,
    decoration: BoxDecoration(
      color: cor,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
