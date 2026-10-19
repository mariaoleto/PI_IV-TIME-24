// autora: Maria Júlia Lazarini Oleto

import "dotenv/config";
import dns from "node:dns";

// garante compatibilidade de resolução SRV com MongoDB Atlas no Node.js
try {
  dns.setServers(["8.8.8.8", "1.1.1.1"]);
} catch {
  // ignora caso o ambiente restrinja alteração de servidores DNS
}

// valida a presenca das variaveis obrigatorias antes de subir o servidor
const variaveisObrigatorias = ["MONGODB_URI"];

variaveisObrigatorias.forEach((key) => {
  if (!process.env[key]) {
    throw new Error(`Variavel de ambiente obrigatoria ausente: ${key}`);
  }
});

// exporta as variaveis para uso no restante da aplicacao
export const ambiente = {
  modo: process.env.NODE_ENV || "desenvolvimento",
  porta: process.env.PORT || 3000,
  mongoDbUri: process.env.MONGODB_URI!,
  segredoJwt: process.env.JWT_SECRET || "",
};

export const env = {
  nodeEnv: ambiente.modo,
  port: ambiente.porta,
  mongodbUri: ambiente.mongoDbUri,
  jwtSecret: ambiente.segredoJwt,
};
