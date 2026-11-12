import mongoose from "mongoose";
import {
  formatarLocalizacaoUsina,
  lerCapacidadeUsina,
} from "../../utils/usina_formatacao";
import { Cota, Membro } from "../geracao_creditos/energia_model";
import { Usina } from "../painel_admin/painel_model";

export class ErroGestao extends Error {
  constructor(
    message: string,
    public readonly status = 400,
  ) {
    super(message);
    this.name = "ErroGestao";
  }
}

export type UsinaDto = {
  id: string;
  nome: string;
  potencia: number;
  distribuidora: string;
  codigo: string;
  local: string | null;
};

export type MembroUsinaDto = {
  id: string;
  nome: string;
  email: string;
  cota: number;
  status: "Ativo" | "Pendente";
};

export type ContratoUsinaDto = {
  usinaId: string;
  nomeArquivo: string;
  tamanhoBytes: number;
  dataEnvio: string;
};

export type EntradaUsina = {
  nome?: unknown;
  potencia?: unknown;
  distribuidora?: unknown;
  local?: unknown;
  codigo?: unknown;
};

export type EntradaCota = {
  membro_id?: unknown;
  percentual?: unknown;
};

export type ArquivoMultipart = {
  nomeArquivo: string;
  mimeType: string;
  conteudo: Buffer;
  tamanhoBytes: number;
};

const schemaContratoUsina = new mongoose.Schema(
  {
    usina_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Usina",
      required: true,
      index: true,
      unique: true,
    },
    nomeArquivo: { type: String, required: true, trim: true },
    tamanhoBytes: { type: Number, required: true },
    mimeType: { type: String, default: "application/pdf" },
    conteudoBase64: { type: String, required: true },
    dataEnvio: { type: Date, default: Date.now },
  },
  {
    collection: "contratos_usina",
    strict: false,
    versionKey: false,
  },
);

export const ContratoUsina =
  (mongoose.models.ContratoUsina as mongoose.Model<Record<string, unknown>>) ||
  mongoose.model("ContratoUsina", schemaContratoUsina, "contratos_usina");

const UsinaFlex = Usina as unknown as mongoose.Model<Record<string, unknown>>;

function escaparRegex(texto: string): string {
  return texto.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function exigirObjectId(id: string, rotulo: string): mongoose.Types.ObjectId {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new ErroGestao(`${rotulo} inválido.`, 400);
  }
  return new mongoose.Types.ObjectId(id);
}

function gerarCodigoUsina(): string {
  const sufixo = Math.floor(100000 + Math.random() * 900000);
  return `SOL-${sufixo}`;
}

export function validarDadosUsina(entrada: EntradaUsina) {
  const nome = typeof entrada.nome === "string" ? entrada.nome.trim() : "";
  if (nome.length < 2) {
    throw new ErroGestao("Informe o nome da usina.");
  }

  const potenciaNum = Number(entrada.potencia);
  if (!Number.isFinite(potenciaNum) || potenciaNum <= 0) {
    throw new ErroGestao("Informe uma potência válida maior que zero.");
  }

  const distribuidora =
    typeof entrada.distribuidora === "string" ? entrada.distribuidora.trim() : "";
  if (distribuidora.length < 2) {
    throw new ErroGestao("Informe a distribuidora da usina.");
  }

  const localBruto = typeof entrada.local === "string" ? entrada.local.trim() : "";
  const local = localBruto.length > 0 ? localBruto : null;

  const codigoBruto = typeof entrada.codigo === "string" ? entrada.codigo.trim() : "";
  const codigo = codigoBruto.length > 0 ? codigoBruto : undefined;

  return { nome, potencia: potenciaNum, distribuidora, local, codigo };
}

export function validarListaCotas(
  cotas: unknown,
): Array<{ membroId: string; percentual: number }> {
  if (!Array.isArray(cotas)) {
    throw new ErroGestao("Envie uma lista válida de cotas.");
  }

  const normalizadas: Array<{ membroId: string; percentual: number }> = [];
  const membrosVistos = new Set<string>();
  let soma = 0;

  for (const item of cotas) {
    const bruto = (item ?? {}) as EntradaCota;
    const membroId =
      typeof bruto.membro_id === "string" ? bruto.membro_id.trim() : "";
    if (!membroId) {
      throw new ErroGestao("Cada cota deve informar o membro_id.");
    }
    if (membrosVistos.has(membroId)) {
      throw new ErroGestao("Há membros duplicados na distribuição de cotas.");
    }
    membrosVistos.add(membroId);

    const percentual = Number(bruto.percentual);
    if (!Number.isFinite(percentual) || percentual < 0 || percentual > 100) {
      throw new ErroGestao("Cada percentual deve estar entre 0% e 100%.");
    }

    const arredondado = Number(percentual.toFixed(2));
    soma += arredondado;
    normalizadas.push({ membroId, percentual: arredondado });
  }

  if (soma > 100.001) {
    throw new ErroGestao("A soma das cotas não pode ultrapassar 100%.");
  }

  return normalizadas;
}

export function mapearUsinaParaResposta(doc: Record<string, unknown>): UsinaDto {
  const local =
    formatarLocalizacaoUsina(doc.local) ??
    formatarLocalizacaoUsina(doc.localizacao);

  return {
    id: String(doc._id ?? ""),
    nome: String(doc.nome ?? ""),
    potencia: lerCapacidadeUsina(doc),
    distribuidora: String(doc.distribuidora ?? ""),
    codigo: String(doc.codigo ?? ""),
    local,
  };
}

export function extrairArquivoMultipart(
  corpo: Buffer,
  contentType?: string,
): ArquivoMultipart {
  if (!contentType || !contentType.toLowerCase().includes("multipart/form-data")) {
    throw new ErroGestao("Envie o contrato como multipart/form-data.");
  }

  const matchBoundary = contentType.match(/boundary=(?:"([^"]+)"|([^;\s]+))/i);
  const boundary = matchBoundary?.[1] || matchBoundary?.[2];
  if (!boundary) {
    throw new ErroGestao("Boundary multipart ausente na requisição.");
  }

  if (!Buffer.isBuffer(corpo) || corpo.length === 0) {
    throw new ErroGestao("Nenhum arquivo enviado.");
  }

  const marcador = Buffer.from(`--${boundary}`, "latin1");
  const separadorCabecalho = Buffer.from("\r\n\r\n", "latin1");

  let cursor = corpo.indexOf(marcador);
  while (cursor !== -1) {
    let inicioParte = cursor + marcador.length;
    // Fim final do stream multipart: "--boundary--"
    if (corpo.subarray(inicioParte, inicioParte + 2).toString("latin1") === "--") {
      break;
    }
    if (corpo.subarray(inicioParte, inicioParte + 2).toString("latin1") === "\r\n") {
      inicioParte += 2;
    }

    const fimCabecalho = corpo.indexOf(separadorCabecalho, inicioParte);
    if (fimCabecalho === -1) break;

    const cabecalho = corpo.subarray(inicioParte, fimCabecalho).toString("utf8");
    const inicioConteudo = fimCabecalho + separadorCabecalho.length;
    const proximoMarcador = corpo.indexOf(marcador, inicioConteudo);
    if (proximoMarcador === -1) break;

    let fimConteudo = proximoMarcador;
    if (
      fimConteudo >= 2 &&
      corpo[fimConteudo - 2] === 13 &&
      corpo[fimConteudo - 1] === 10
    ) {
      fimConteudo -= 2;
    }

    const ehCampoArquivo =
      /name="arquivo"/i.test(cabecalho) || /filename="/i.test(cabecalho);
    if (ehCampoArquivo) {
      const matchNome = cabecalho.match(/filename="([^"]*)"/i);
      const nomeBruto = (matchNome?.[1] ?? "contrato.pdf")
        .split(/[\\/]/)
        .pop()
        ?.trim();
      const nomeArquivo = nomeBruto && nomeBruto.length > 0 ? nomeBruto : "contrato.pdf";
      const matchMime = cabecalho.match(/content-type:\s*([^\r\n;]+)/i);
      const mimeType = matchMime?.[1]?.trim() || "application/pdf";
      const conteudo = corpo.subarray(inicioConteudo, fimConteudo);

      if (conteudo.length === 0) {
        throw new ErroGestao("O arquivo do contrato está vazio.");
      }

      return {
        nomeArquivo,
        mimeType,
        conteudo,
        tamanhoBytes: conteudo.length,
      };
    }

    cursor = proximoMarcador;
  }

  throw new ErroGestao("Arquivo de contrato não encontrado na requisição.");
}

export async function migrarColecaoUsinasParaUsina(): Promise<number> {
  const db = mongoose.connection.db;
  if (!db) return 0;

  const existeUsinas = await db
    .listCollections({ name: "usinas" }, { nameOnly: true })
    .hasNext();
  if (!existeUsinas) return 0;

  const origem = db.collection("usinas");
  const destino = db.collection("usina");
  const docs = await origem.find({}).toArray();

  let migrados = 0;
  for (const doc of docs) {
    const jaExiste = await destino.findOne(
      { _id: doc._id },
      { projection: { _id: 1 } },
    );
    if (!jaExiste) {
      await destino.insertOne(doc);
      migrados++;
    }
  }

  await origem.drop();
  return migrados;
}

export async function listarUsinas(): Promise<UsinaDto[]> {
  const docs = await UsinaFlex.find()
    .sort({ ativa: -1, _id: 1 })
    .lean<Record<string, unknown>[]>();
  return docs.map(mapearUsinaParaResposta);
}

export async function criarUsina(entrada: EntradaUsina): Promise<UsinaDto> {
  const dados = validarDadosUsina(entrada);
  const codigo = dados.codigo ?? gerarCodigoUsina();

  const criada = await UsinaFlex.create({
    nome: dados.nome,
    potencia: dados.potencia,
    capacidade_kwp: dados.potencia,
    potencia_instalada_kwp: dados.potencia,
    distribuidora: dados.distribuidora,
    codigo,
    local: dados.local,
    localizacao: dados.local,
    ativa: true,
  });

  return mapearUsinaParaResposta(criada.toObject() as Record<string, unknown>);
}

export async function atualizarUsina(
  id: string,
  entrada: EntradaUsina,
): Promise<UsinaDto> {
  const objId = exigirObjectId(id, "Identificador da usina");
  const dados = validarDadosUsina(entrada);

  const atualizacao: Record<string, unknown> = {
    nome: dados.nome,
    potencia: dados.potencia,
    capacidade_kwp: dados.potencia,
    potencia_instalada_kwp: dados.potencia,
    distribuidora: dados.distribuidora,
    local: dados.local,
    localizacao: dados.local,
  };
  if (dados.codigo) {
    atualizacao.codigo = dados.codigo;
  }

  const atualizada = await UsinaFlex.findByIdAndUpdate(
    objId,
    { $set: atualizacao },
    { new: true },
  ).lean<Record<string, unknown> | null>();

  if (!atualizada) {
    throw new ErroGestao("Usina não encontrada.", 404);
  }
  return mapearUsinaParaResposta(atualizada);
}

export async function excluirUsina(id: string): Promise<void> {
  const objId = exigirObjectId(id, "Identificador da usina");
  const removida = await UsinaFlex.findByIdAndDelete(objId).lean();
  if (!removida) {
    throw new ErroGestao("Usina não encontrada.", 404);
  }

  await Promise.all([
    Cota.deleteMany({ usina_id: objId }),
    ContratoUsina.deleteMany({ usina_id: objId }),
    Membro.updateMany({ usina_id: objId }, { $unset: { usina_id: "" } }),
  ]);
}

function mapearMembroUsina(
  membro: Record<string, unknown>,
  percentual: number,
): MembroUsinaDto {
  const cota = Number.isFinite(percentual) ? Number(percentual) : 0;
  return {
    id: String(membro._id ?? ""),
    nome: String(membro.nome ?? ""),
    email: String(membro.email ?? ""),
    cota,
    status: cota > 0 ? "Ativo" : "Pendente",
  };
}

export async function listarMembrosUsina(
  usinaId?: string,
): Promise<MembroUsinaDto[]> {
  if (usinaId && usinaId.trim().length > 0) {
    const objUsinaId = exigirObjectId(usinaId.trim(), "Identificador da usina");
    const cotas = await Cota.find({ usina_id: objUsinaId }).lean<
      Record<string, unknown>[]
    >();
    const mapaCotaPorMembro = new Map<string, number>();
    const idsCota: mongoose.Types.ObjectId[] = [];

    for (const cota of cotas) {
      if (cota.membro_id) {
        const membroStr = String(cota.membro_id);
        mapaCotaPorMembro.set(membroStr, Number(cota.percentual ?? 0));
        if (mongoose.Types.ObjectId.isValid(membroStr)) {
          idsCota.push(new mongoose.Types.ObjectId(membroStr));
        }
      }
    }

    const membros = await Membro.find({
      $or: [{ usina_id: objUsinaId }, ...(idsCota.length ? [{ _id: { $in: idsCota } }] : [])],
    })
      .sort({ nome: 1, _id: 1 })
      .lean<Record<string, unknown>[]>();

    return membros.map((m) =>
      mapearMembroUsina(m, mapaCotaPorMembro.get(String(m._id)) ?? 0),
    );
  }

  const [membros, cotas] = await Promise.all([
    Membro.find({ tipo_usuario: { $ne: "admin" } })
      .sort({ nome: 1, _id: 1 })
      .lean<Record<string, unknown>[]>(),
    Cota.find().lean<Record<string, unknown>[]>(),
  ]);

  const mapaCota = new Map<string, number>();
  for (const c of cotas) {
    if (c.membro_id) {
      mapaCota.set(String(c.membro_id), Number(c.percentual ?? 0));
    }
  }

  return membros.map((m) => mapearMembroUsina(m, mapaCota.get(String(m._id)) ?? 0));
}

export async function adicionarMembroNaUsina(entrada: {
  nome?: unknown;
  email?: unknown;
  usina_id?: unknown;
}): Promise<MembroUsinaDto> {
  const nome = typeof entrada.nome === "string" ? entrada.nome.trim() : "";
  const email =
    typeof entrada.email === "string" ? entrada.email.trim().toLowerCase() : "";
  const usinaId =
    typeof entrada.usina_id === "string" ? entrada.usina_id.trim() : "";

  if (nome.length < 2) {
    throw new ErroGestao("Informe o nome completo do membro.");
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new ErroGestao("Informe um e-mail válido para o membro.");
  }

  const objUsinaId = exigirObjectId(usinaId, "Identificador da usina");
  const usinaExiste = await Usina.exists({ _id: objUsinaId });
  if (!usinaExiste) {
    throw new ErroGestao("Usina não encontrada.", 404);
  }

  let membroDoc = await Membro.findOne({
    email: new RegExp(`^${escaparRegex(email)}$`, "i"),
  });

  if (membroDoc) {
    await Membro.updateOne(
      { _id: membroDoc._id },
      {
        $set: {
          usina_id: objUsinaId,
          ...(membroDoc.get("nome") ? {} : { nome }),
        },
      },
    );
    membroDoc = await Membro.findById(membroDoc._id);
  } else {
    membroDoc = await Membro.create({
      nome,
      email,
      tipo_usuario: "membro",
      usina_id: objUsinaId,
      data_cadastro: new Date(),
      cadastro_concluido: false,
    });
  }

  const membroObj = membroDoc!.toObject() as Record<string, unknown>;
  const cotaExistente = await Cota.findOne({
    membro_id: membroDoc!._id,
    usina_id: objUsinaId,
  }).lean<Record<string, unknown> | null>();

  if (!cotaExistente) {
    await Cota.create({
      membro_id: membroDoc!._id,
      usina_id: objUsinaId,
      percentual: 0,
      tarifa_kwh: 0.69,
      data_inicio: new Date(),
    });
  }

  return mapearMembroUsina(membroObj, Number(cotaExistente?.percentual ?? 0));
}

export async function atualizarCotasUsina(
  usinaId: string,
  cotasEntrada: unknown,
): Promise<MembroUsinaDto[]> {
  const objUsinaId = exigirObjectId(usinaId, "Identificador da usina");
  const usinaExiste = await Usina.exists({ _id: objUsinaId });
  if (!usinaExiste) {
    throw new ErroGestao("Usina não encontrada.", 404);
  }

  const cotasValidadas = validarListaCotas(cotasEntrada);
  for (const item of cotasValidadas) {
    const objMembroId = exigirObjectId(item.membroId, "Identificador do membro");
    const membroExiste = await Membro.exists({ _id: objMembroId });
    if (!membroExiste) {
      throw new ErroGestao(`Membro ${item.membroId} não encontrado.`, 404);
    }

    await Promise.all([
      Cota.findOneAndUpdate(
        { usina_id: objUsinaId, membro_id: objMembroId },
        {
          $set: {
            usina_id: objUsinaId,
            membro_id: objMembroId,
            percentual: item.percentual,
          },
          $setOnInsert: {
            tarifa_kwh: 0.69,
            data_inicio: new Date(),
          },
        },
        { upsert: true, new: true },
      ),
      Membro.updateOne({ _id: objMembroId }, { $set: { usina_id: objUsinaId } }),
    ]);
  }

  return listarMembrosUsina(usinaId);
}

function mapearContratoDto(
  usinaId: string,
  doc: Record<string, unknown>,
): ContratoUsinaDto {
  const dataBruta = doc.dataEnvio;
  const dataEnvio =
    dataBruta instanceof Date
      ? dataBruta.toISOString()
      : typeof dataBruta === "string"
        ? dataBruta
        : new Date().toISOString();

  return {
    usinaId,
    nomeArquivo: String(doc.nomeArquivo ?? "contrato.pdf"),
    tamanhoBytes: Number(doc.tamanhoBytes ?? 0),
    dataEnvio,
  };
}

export async function buscarContratoUsina(
  usinaId: string,
): Promise<ContratoUsinaDto> {
  const objUsinaId = exigirObjectId(usinaId, "Identificador da usina");
  const contrato = await ContratoUsina.findOne({ usina_id: objUsinaId }).lean<
    Record<string, unknown> | null
  >();
  if (!contrato) {
    throw new ErroGestao("Nenhum contrato encontrado para esta usina.", 404);
  }
  return mapearContratoDto(usinaId, contrato);
}

export async function salvarContratoUsina(
  usinaId: string,
  arquivo: ArquivoMultipart,
): Promise<ContratoUsinaDto> {
  const objUsinaId = exigirObjectId(usinaId, "Identificador da usina");
  const usinaExiste = await Usina.exists({ _id: objUsinaId });
  if (!usinaExiste) {
    throw new ErroGestao("Usina não encontrada.", 404);
  }

  const agora = new Date();
  const salvo = await ContratoUsina.findOneAndUpdate(
    { usina_id: objUsinaId },
    {
      $set: {
        usina_id: objUsinaId,
        nomeArquivo: arquivo.nomeArquivo,
        tamanhoBytes: arquivo.tamanhoBytes,
        mimeType: arquivo.mimeType,
        conteudoBase64: arquivo.conteudo.toString("base64"),
        dataEnvio: agora,
      },
    },
    { upsert: true, new: true },
  ).lean<Record<string, unknown>>();

  return mapearContratoDto(usinaId, salvo!);
}

export async function excluirContratoUsina(usinaId: string): Promise<void> {
  const objUsinaId = exigirObjectId(usinaId, "Identificador da usina");
  const removido = await ContratoUsina.findOneAndDelete({
    usina_id: objUsinaId,
  }).lean();
  if (!removido) {
    throw new ErroGestao("Contrato não encontrado para exclusão.", 404);
  }
}
