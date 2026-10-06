// autora: Maria Júlia Lazarini Oleto

// significado do arquivo:
// inicia o servidor e conecta ao mongoDB

import dns from "node:dns";
import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import { env } from "./config/env";
import roteadorEnergia from "./modules/geracao_creditos/energia_routes";

// garante resolução de DNS segura para MongoDB Atlas em ambientes locais/Windows
try {
  dns.setServers(["8.8.8.8", "1.1.1.1"]);
} catch {
  // mantém padrão se o ambiente não permitir alteração de DNS
}

// configurações do servidor express
const app = express();
app.use(cors());
app.use(express.json());

// rota que tetsa se o servidor está rodando
app.get("/", (_req, res) => {
  res.json({ status: "Solis API rodando" });
});

// usa a rota para receber e enviar dados
app.use("/energia", roteadorEnergia);

// trata erros da rota
app.use(
  (
    erro: Error,
    _requisicao: express.Request,
    resposta: express.Response,
    _proximo: express.NextFunction,
  ) => {
    console.error(erro);
    resposta.status(400).json({ mensagem: erro.message || "Erro inesperado" });
  },
);

// conecta no mongoDB e inicia o servidor
mongoose.connect(env.mongodbUri)
  .then(() => {
    console.log("Conectado ao MongoDB");
    app.listen(env.port, () => {
      console.log(`Servidor rodando na porta ${env.port}`);
    });
  })
  .catch((err) => {
    console.error("Erro ao conectar no MongoDB:", err);
  });
