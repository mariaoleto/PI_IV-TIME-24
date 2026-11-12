// autora: Maria Julia Lazarini OletO
// RA: 25006031

// significado do arquivo:
// define as rotas 
// a rota aponta para o controller, que chama o service e lida com a regra de negocio 

import { Router } from "express";
import {
    buscarResumoEnergia,
    buscarCotasDistribuicao,
    salvarConsumoMensal,
    salvarLancamentoMensal,
    consultarTelemetriaTcp,
} from "./energia_controllers";

const roteador = Router();

roteador.get("/", buscarResumoEnergia);
roteador.get("/cotas", buscarCotasDistribuicao);
roteador.post("/consumo", salvarConsumoMensal);
roteador.post("/lancamento", salvarLancamentoMensal);

// consulta a telemetria da placa solar via Socket TCP com o Java
roteador.get("/telemetria-tcp",
    consultarTelemetriaTcp);

export default roteador;
