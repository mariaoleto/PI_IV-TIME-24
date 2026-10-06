// autora: Maria Julia Lazarini Oleto

// significado do arquivo:
// define as rotas 
// a rota aponta para o controller, que chama o service e lida com a regra de negocio 

import { Router } from "express";
import { buscarResumoEnergia } from "./energia_controllers";
import { buscarCotasDistribuicao } from "./energia_controllers";

const roteador = Router();

roteador.get("/", buscarResumoEnergia);
roteador.get("/cotas", buscarCotasDistribuicao);

export default roteador;
