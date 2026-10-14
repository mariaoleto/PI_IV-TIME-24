// autora: Maria Julia Lazarini Oleto

// significado do arquivo:
// define as rotas 
// a rota aponta para o controller, que chama o service e lida com a regra de negocio 

import { Router } from "express";
import {
    buscarResumoEnergia,
    buscarCotasDistribuicao,
    salvarLancamentoMensal,
} from "./energia_controllers";

const roteador = Router();

roteador.get("/", buscarResumoEnergia);
roteador.get("/cotas", buscarCotasDistribuicao);
roteador.post("/lancamento", salvarLancamentoMensal);

export default roteador;
