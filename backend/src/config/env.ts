import 'dotenv/config';

// valida presença das variáveis obrigatórias antes de subir o servidor
const required = ['MONGODB_URI'];
required.forEach((key) => {
  if (!process.env[key]) {
    throw new Error(`Variável de ambiente obrigatória ausente: ${key}`);
  }
});

// exporta as variáveis para uso no restante da aplicação
export const env = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  port: process.env.PORT || 3000,
  mongodbUri: process.env.MONGODB_URI!,
  jwtSecret: process.env.JWT_SECRET || '',
};