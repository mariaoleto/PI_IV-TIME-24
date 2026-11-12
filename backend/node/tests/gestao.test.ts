import test from "node:test";
import assert from "node:assert/strict";
import type { NextFunction, Request, Response } from "express";
import {
  atualizarCotasController,
  criarUsinaController,
  enviarContratoController,
} from "../src/modules/gestao/gestao_controller";
import {
  ErroGestao,
  extrairArquivoMultipart,
  mapearUsinaParaResposta,
  validarDadosUsina,
  validarListaCotas,
} from "../src/modules/gestao/gestao_service";

function criarRespostaMock() {
  let statusCode = 200;
  let corpo: unknown;
  const resposta = {
    status(codigo: number) {
      statusCode = codigo;
      return resposta;
    },
    json(payload: unknown) {
      corpo = payload;
      return resposta;
    },
    send(payload?: unknown) {
      corpo = payload;
      return resposta;
    },
  } as unknown as Response;

  return {
    resposta,
    obterResultado: () => ({ statusCode, corpo }),
  };
}

test("validarDadosUsina normaliza campos e rejeita entrada inválida", () => {
  const valida = validarDadosUsina({
    nome: "  Usina Solis Campinas ",
    potencia: "150.5",
    distribuidora: " CPFL Paulista ",
    local: " Campinas - SP ",
  });
  assert.deepEqual(valida, {
    nome: "Usina Solis Campinas",
    potencia: 150.5,
    distribuidora: "CPFL Paulista",
    local: "Campinas - SP",
    codigo: undefined,
  });

  assert.throws(
    () => validarDadosUsina({ nome: "", potencia: 100, distribuidora: "CPFL" }),
    (erro) => erro instanceof ErroGestao && erro.status === 400,
  );
  assert.throws(
    () => validarDadosUsina({ nome: "Usina A", potencia: 0, distribuidora: "CPFL" }),
    (erro) => erro instanceof ErroGestao && erro.status === 400,
  );
});

test("mapearUsinaParaResposta aceita campos novos e legados do MongoDB", () => {
  const mapeada = mapearUsinaParaResposta({
    _id: "507f1f77bcf86cd799439011",
    nome: "Solis 1",
    capacidade_kwp: 120,
    distribuidora: "Enel",
    codigo: "SOL-123456",
    localizacao: "São Paulo - SP",
  });

  assert.deepEqual(mapeada, {
    id: "507f1f77bcf86cd799439011",
    nome: "Solis 1",
    potencia: 120,
    distribuidora: "Enel",
    codigo: "SOL-123456",
    local: "São Paulo - SP",
  });

  const preDefinida = mapearUsinaParaResposta({
    _id: "000000000000000000000001",
    nome: "Consórcio Solis",
    potencia_instalada_kwp: 15,
    distribuidora: "CPFL Piratininga",
    codigo: "SP-Norte-01",
    localizacao: { cidade: "Campinas", estado: "SP" },
  });

  assert.deepEqual(preDefinida, {
    id: "000000000000000000000001",
    nome: "Consórcio Solis",
    potencia: 15,
    distribuidora: "CPFL Piratininga",
    codigo: "SP-Norte-01",
    local: "Campinas - SP",
  });
});

test("validarListaCotas aceita até 100% e bloqueia excesso ou duplicidade", () => {
  const cotas = validarListaCotas([
    { membro_id: "507f1f77bcf86cd799439021", percentual: 60 },
    { membro_id: "507f1f77bcf86cd799439022", percentual: 40 },
  ]);
  assert.equal(cotas.length, 2);

  assert.throws(
    () =>
      validarListaCotas([
        { membro_id: "507f1f77bcf86cd799439021", percentual: 70 },
        { membro_id: "507f1f77bcf86cd799439022", percentual: 35 },
      ]),
    /não pode ultrapassar 100%/i,
  );

  assert.throws(
    () =>
      validarListaCotas([
        { membro_id: "507f1f77bcf86cd799439021", percentual: 50 },
        { membro_id: "507f1f77bcf86cd799439021", percentual: 20 },
      ]),
    /duplicados/i,
  );
});

test("extrairArquivoMultipart extrai binário PDF e nome do arquivo", () => {
  const boundary = "----SolisBoundary12345";
  const pdfBytes = Buffer.from("%PDF-1.4\n1 0 obj\n<<>>\nendobj\n%%EOF\n", "latin1");
  const corpo = Buffer.concat([
    Buffer.from(
      `--${boundary}\r\n` +
        `Content-Disposition: form-data; name="arquivo"; filename="C:\\fakepath\\contrato_solis.pdf"\r\n` +
        `Content-Type: application/pdf\r\n\r\n`,
      "utf8",
    ),
    pdfBytes,
    Buffer.from(`\r\n--${boundary}--\r\n`, "utf8"),
  ]);

  const extraido = extrairArquivoMultipart(
    corpo,
    `multipart/form-data; boundary="${boundary}"`,
  );

  assert.equal(extraido.nomeArquivo, "contrato_solis.pdf");
  assert.equal(extraido.mimeType, "application/pdf");
  assert.equal(extraido.tamanhoBytes, pdfBytes.length);
  assert.equal(extraido.conteudo.equals(pdfBytes), true);

  assert.throws(
    () => extrairArquivoMultipart(Buffer.alloc(0), `multipart/form-data; boundary=${boundary}`),
    /vazio|nenhum arquivo/i,
  );
});

test("controllers de gestão mapeiam ErroGestao para status HTTP e mensagem", async () => {
  const mock1 = criarRespostaMock();
  let proximoChamado = false;
  const proximo: NextFunction = () => {
    proximoChamado = true;
  };

  await criarUsinaController(
    { body: { nome: "", potencia: -5 } } as Request,
    mock1.resposta,
    proximo,
  );
  assert.equal(proximoChamado, false);
  assert.equal(mock1.obterResultado().statusCode, 400);

  const mock2 = criarRespostaMock();
  await atualizarCotasController(
    {
      params: { id: "id-invalido" },
      body: { cotas: [] },
    } as unknown as Request,
    mock2.resposta,
    proximo,
  );
  assert.equal(mock2.obterResultado().statusCode, 400);

  const mock3 = criarRespostaMock();
  await enviarContratoController(
    {
      params: { id: "507f1f77bcf86cd799439011" },
      headers: {},
      body: {},
    } as unknown as Request,
    mock3.resposta,
    proximo,
  );
  assert.equal(mock3.obterResultado().statusCode, 400);
});

