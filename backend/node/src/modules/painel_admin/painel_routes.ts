//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo: rotas do painel administrativo (montadas em /admin)

import { Router } from "express";
import { buscarPainelAdmin } from "./painel_controller";

const roteador = Router();

roteador.get("/painel", buscarPainelAdmin);

export default roteador;
