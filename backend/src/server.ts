import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import { env } from "./config/env";

// configurações do servidor express
const app = express();
app.use(cors());
app.use(express.json());

// rota que tetsa se o servidor está rodando
app.get("/", (_req, res) => {
  res.json({ status: "Solis API rodando" });
});

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