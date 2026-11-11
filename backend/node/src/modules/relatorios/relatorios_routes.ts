import { Router } from "express";
import { exigirAutenticacao } from "../auth/auth_middleware";
import {
  baixarRelatorio,
  emitirTicketDownload,
  gerarDemonstrativoAnual,
  gerarExtratoCreditos,
  gerarRelatorioMensal,
  listarRelatorios,
} from "./relatorios_controller";

const roteador = Router();

// Download aceita Bearer token ou ticket temporário assinado (usado ao abrir o PDF externamente)
roteador.get("/:id/download", baixarRelatorio);

roteador.use(exigirAutenticacao);
roteador.get("/", listarRelatorios);
roteador.post("/mensal", gerarRelatorioMensal);
roteador.post("/extrato-creditos", gerarExtratoCreditos);
roteador.post("/demonstrativo-anual", gerarDemonstrativoAnual);
roteador.get("/:id/ticket", emitirTicketDownload);

export default roteador;
