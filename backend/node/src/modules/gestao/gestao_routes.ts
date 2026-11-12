import express, { Router } from "express";
import {
  adicionarMembroController,
  atualizarCotasController,
  atualizarUsinaController,
  buscarContratoController,
  criarUsinaController,
  enviarContratoController,
  excluirContratoController,
  excluirUsinaController,
  listarMembrosController,
  listarUsinasController,
} from "./gestao_controller";

const roteador = Router();

roteador.get("/usinas", listarUsinasController);
roteador.post("/usinas", criarUsinaController);
roteador.put("/usinas/:id", atualizarUsinaController);
roteador.delete("/usinas/:id", excluirUsinaController);

roteador.get("/membros", listarMembrosController);
roteador.post("/membros", adicionarMembroController);
roteador.put("/usinas/:id/cotas", atualizarCotasController);

roteador.get("/usinas/:id/contrato", buscarContratoController);
roteador.post(
  "/usinas/:id/contrato",
  express.raw({ type: "multipart/form-data", limit: "10mb" }),
  enviarContratoController,
);
roteador.delete("/usinas/:id/contrato", excluirContratoController);

export default roteador;

