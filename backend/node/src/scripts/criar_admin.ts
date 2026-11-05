//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// script para criar (ou promover) uma conta de administrador pelo terminal
// não existe cadastro de administrador pelo app de propósito: só quem tem acesso ao servidor cria
//
// uso (na pasta backend/node):
//   npm run criar-admin -- "Nome Sobrenome" admin@solis.com.br SenhaForte123
//
// se o e-mail já existir, a conta vira administrador e a senha informada passa a valer

import mongoose from "mongoose";
import { env } from "../config/env";
import { Membro } from "../modules/geracao_creditos/energia_model";
import { buscarMembroPorEmail } from "../modules/perfil/perfil_repo";
import { gerarHashSenha } from "../modules/perfil/perfil_senha";
import { validarCadastro } from "../modules/auth/auth_validacao";

async function principal() {
  const [nome, email, senha] = process.argv.slice(2);
  if (!nome || !email || !senha) {
    console.error('Uso: npm run criar-admin -- "Nome Sobrenome" email senha');
    process.exit(1);
  }

  const dados = validarCadastro({ nome, email, senha }, { exigirCpf: false });
  await mongoose.connect(env.mongodbUri);

  const senhaHash = await gerarHashSenha(dados.senha);
  const existente = await buscarMembroPorEmail(dados.email);

  if (existente) {
    await Membro.updateOne(
      { _id: existente._id },
      { $set: { tipo_usuario: "admin", senha_hash: senhaHash, senha_alterada_em: new Date() } },
    );
    console.log(`Conta existente promovida a administrador: ${dados.email}`);
  } else {
    await Membro.create({
      nome: dados.nome,
      email: dados.email,
      senha_hash: senhaHash,
      tipo_usuario: "admin",
      data_cadastro: new Date(),
    });
    console.log(`Administrador criado: ${dados.email}`);
  }
}

principal()
  .catch((erro) => {
    console.error("Erro:", erro instanceof Error ? erro.message : erro);
    process.exitCode = 1;
  })
  .finally(() => mongoose.disconnect());
