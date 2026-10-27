// autora: Maria Júlia Lazarini Oleto
// significado do arquivo:
// define as rotas do painel do membro (dashboard)

import { Router } from "express";
import { buscarDashboardMembro } from "./painel_membro_controllers";

const roteador = Router();

// rotas para obter os dados do dashboard do membro
roteador.get("/", buscarDashboardMembro);
roteador.get("/dashboard", buscarDashboardMembro);

export default roteador;
