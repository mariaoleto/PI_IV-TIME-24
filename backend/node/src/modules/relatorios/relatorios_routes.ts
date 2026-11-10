import { Router } from "express";
import { exigirAutenticacao } from "../auth/auth_middleware";
import {
  baixarRelatorio,
  gerarDemonstrativoAnual,
  gerarExtratoCreditos,
  gerarRelatorioMensal,
  listarRelatorios,
} from "./relatorios_controller";

const roteador = Router();

roteador.use(exigirAutenticacao);
roteador.get("/", listarRelatorios);
roteador.post("/mensal", gerarRelatorioMensal);
roteador.post("/extrato-creditos", gerarExtratoCreditos);
roteador.post("/demonstrativo-anual", gerarDemonstrativoAnual);
roteador.get("/:id/download", baixarRelatorio);

export default roteador;
