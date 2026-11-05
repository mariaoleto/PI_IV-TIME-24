//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// rotas do perfil do membro (montadas em /perfil no server.ts)

import { Router } from "express";
import { exigirAutenticacao } from "../auth/auth_middleware";
import {
  atualizarPerfil,
  buscarContrato,
  buscarPerfil,
  trocarSenha,
} from "./perfil_controller";

const roteador = Router();

// todas as rotas do perfil exigem login (header Authorization: Bearer <token>)
roteador.use(exigirAutenticacao);

// perfil de quem está logado (administrador também pode consultar outro por ?membro_id= ou ?email=)
roteador.get("/", buscarPerfil);

// editar nome, e-mail e telefone
roteador.put("/:id", atualizarPerfil);

// alterar senha
roteador.put("/:id/senha", trocarSenha);

// contrato do consórcio (visualização)
roteador.get("/:id/contrato", buscarContrato);

export default roteador;
