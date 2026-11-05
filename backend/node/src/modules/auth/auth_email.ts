//Autora: Ana Luísa Maso Mafra | RA: 25007997

// significado do arquivo:
// envia o e-mail com o código de recuperação de senha
//
// variáveis do .env para envio real (SMTP):
//   SMTP_HOST, SMTP_PORT (587), SMTP_SECURE ("true" para porta 465), SMTP_USER, SMTP_PASS, SMTP_FROM
// sem SMTP_HOST (ambiente de desenvolvimento) o código aparece no console do servidor.
// em produção (NODE_ENV=production) sem SMTP o envio falha, para o código não vazar no log

function escaparHtml(texto: string) {
  return texto.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);
}

export async function enviarEmailRecuperacao(destino: string, nome: string, codigo: string) {
  const host = process.env.SMTP_HOST;

  if (!host) {
    if (process.env.NODE_ENV === "production") {
      throw new Error("SMTP não configurado: não foi possível enviar o e-mail de recuperação");
    }
    console.log(`[recuperação de senha] SMTP não configurado. Código de ${destino}: ${codigo}`);
    return;
  }

  const nodemailer = await import("nodemailer");
  const usuario = process.env.SMTP_USER;
  const transporte = nodemailer.createTransport({
    host,
    port: Number(process.env.SMTP_PORT ?? 587),
    secure: process.env.SMTP_SECURE === "true",
    auth: usuario ? { user: usuario, pass: process.env.SMTP_PASS ?? "" } : undefined,
  });

  const primeiroNome = nome.trim().split(" ")[0] || "";
  await transporte.sendMail({
    from: process.env.SMTP_FROM ?? "Solis <no-reply@solis.com.br>",
    to: destino,
    subject: "Código para redefinir sua senha - Solis",
    text:
      `Olá${primeiroNome ? `, ${primeiroNome}` : ""}!\n\n` +
      `Seu código para redefinir a senha é: ${codigo}\n` +
      `Ele vale por 15 minutos. Se você não pediu, ignore este e-mail.\n\nEquipe Solis`,
    html:
      `<p>Olá${primeiroNome ? `, ${escaparHtml(primeiroNome)}` : ""}!</p>` +
      `<p>Seu código para redefinir a senha é:</p>` +
      `<p style="font-size:28px;font-weight:bold;letter-spacing:6px">${codigo}</p>` +
      `<p>Ele vale por 15 minutos. Se você não pediu, ignore este e-mail.</p><p>Equipe Solis</p>`,
  });
}
