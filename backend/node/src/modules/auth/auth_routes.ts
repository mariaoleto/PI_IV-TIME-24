//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// rotas de autenticação (montadas em /auth no server.ts). todas são públicas

import { Router } from "express";
import { cadastro, login, recuperarSenha, redefinir } from "./auth_controller";

const roteador = Router();

roteador.post("/cadastro", cadastro); // cria conta de membro e já devolve o token
roteador.post("/login", login); // membro e administrador (campo "perfil")
roteador.post("/recuperar-senha", recuperarSenha); // envia o código por e-mail
roteador.post("/redefinir-senha", redefinir); // confere o código e troca a senha

export default roteador;
