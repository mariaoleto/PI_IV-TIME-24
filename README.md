# ☀️ Solis

> Aplicativo mobile e ecossistema backend para gestão de energia solar compartilhada em comunidades de geração distribuída.

---

## 📋 Descrição do Projeto

O **Solis** é um aplicativo mobile desenvolvido como projeto acadêmico na disciplina **Projeto Integrador IV** do curso de Engenharia de Software da **PUC-Campinas (2026)**.

A plataforma simula a gestão de energia solar compartilhada entre membros de um consórcio de geração distribuída (vizinhos, condomínios ou comunidades) que dividem os créditos de uma mesma usina solar. A partir da cota de participação de cada membro, o sistema calcula os créditos líquidos de energia, apura o consumo individual, estima a economia financeira, monitora a telemetria simulada da usina via **Socket TCP em Java** e gera **relatórios em PDF** para prestação de contas.

> ⚠️ Todos os dados de geração, telemetria e consumo utilizados no sistema são fictícios/simulados. O sistema não realiza integração real com inversores físicos, distribuidoras de energia ou sistemas financeiros externos.

---

## 🏗️ Arquitetura do Sistema

O projeto é dividido em três camadas que se comunicam localmente ou em rede:

```text
┌─────────────────────────┐      HTTP / REST + JWT      ┌───────────────────────────────────┐
│   App Mobile (Flutter)  │ ──────────────────────────► │   Backend API (Node.js / Express) │
│    (Android/iOS/Web)    │                             │            Porta 3000             │
└─────────────────────────┘                             └───────────┬──────────────┬────────┘
                                                                    │              │
                                              Socket TCP (5050)     │              │ Mongoose
                                                                    ▼              ▼
                                                        ┌──────────────────┐  ┌──────────┐
                                                        │ Servidor TCP Java│  │ MongoDB  │
                                                        │ br.com.solis.tcp │  │          │
                                                        └──────────────────┘  └──────────┘
```

1. **Mobile (`mobile/`)** — Aplicativo Flutter/Dart para membros e administradores.
2. **Backend API (`backend/node/`)** — API REST em Node.js, TypeScript e Express integrada ao MongoDB (Mongoose), autenticação JWT, envio de e-mails de recuperação (`nodemailer`) e geração de PDFs (`pdfkit`).
3. **Servidor Socket TCP (`backend/java/`)** — Serviço em Java (`br.com.solis.tcp.Servidor` na porta `5050`) responsável pelo cálculo proporcional de cotas (`CALCULAR_COTAS`) e consulta de telemetria simulada da usina (`STATUS_USINA`). Caso o servidor TCP Java esteja offline, o backend Node aplica cálculo de fallback local automaticamente.

---

## ✨ Funcionalidades Implementadas

- **Autenticação e Segurança (`auth`)**
  - Login separado por perfil (**Membro** e **Administrador**) com emissão de token JWT e controle de tentativas (bloqueio temporário por excesso de falhas).
  - Cadastro em 2 etapas no app com validação algorítmica de CPF, normalização de telefone, escolha do tipo de conta (`membro` ou `admin`) e criação/promoção de administrador via CLI (`npm run criar-admin`).
  - Recuperação e redefinição de senha via código temporário de 6 dígitos validado por HMAC e envio opcional por SMTP (`nodemailer`).
- **Perfil e Contrato (`perfil`)**
  - Visualização e edição de dados pessoais (nome, e-mail, telefone), troca segura de senha e consulta ao contrato/cota vinculada ao membro.
- **Painel do Membro (`painel_membro`)**
  - Dashboard individual com resumo do mês, créditos, consumo, saldo acumulado e navegação integrada entre Início, Energia, Relatórios e Perfil.
- **Painel do Administrador (`painel_admin`)**
  - Visão consolidada da usina ativa, alertas operacionais (cotas, queda de geração, consumo acima dos créditos), controle de pendências de lançamento mensal e acesso ao lançamento de geração.
- **Geração, Créditos e Telemetria TCP (`geracao_creditos`)**
  - Resumo anual e mensal de geração, consumo, saldo de créditos, economia estimada em reais e indicador de sustentabilidade (CO₂ evitado).
  - Lançamento mensal da geração da usina pelo administrador com distribuição automática dos créditos por cota usando o servidor TCP Java (`CALCULAR_COTAS`), com fallback seguro no Node.js se a porta `5050` não estiver ativa.
  - Consulta de telemetria da usina (`STATUS_USINA`) via `GET /energia/telemetria-tcp`.
- **Relatórios em PDF (`relatorios`)**
  - Geração pelo app e pela API de **Relatório Mensal**, **Extrato de Créditos** e **Demonstrativo Anual** em PDF (`pdfkit`), armazenados na coleção `relatorios` do MongoDB.
  - Integração direta com o Servidor TCP Java: ao gerar um relatório, o backend consulta `STATUS_USINA` e recalcula os créditos mensais via `CALCULAR_COTAS`, gravando `origem_dados_tcp` e `telemetria_tcp` no banco, no cabeçalho do PDF e nos cartões do aplicativo.
  - Download externo seguro sem expor JWT na URL pública por meio de **tickets HMAC-SHA256 de uso temporário** (120 segundos) obtidos em `GET /relatorios/:id/ticket`.
- **Gestão de Usinas (`mobile/lib/features/gestao/`)**
  - Telas e repositório no aplicativo Flutter para cadastro de usinas, componentes, cotas e contratos *(fluxo visual/cliente pronto no mobile; as rotas `/gestao/*` ainda não foram montadas no `server.ts` do Node.js)*.

---

## 👥 Integrantes

| Nome Completo | RA |
|---|---|
| Ana Luísa Maso Mafra | 25007997 |
| Lara Brondi Fraccaroli | 25001358 |
| Maria Júlia Lazarini Oleto | 25006031 |
| Marina Hehnes Espósito | 25000937 |

---

## 🛠️ Tecnologias Utilizadas

| Camada | Tecnologias |
|---|---|
| **Mobile** | Flutter, Dart (`^3.11.4`), `http`, `url_launcher` |
| **Backend API** | Node.js, TypeScript, Express 5, Mongoose 9, `jsonwebtoken`, `pdfkit`, `nodemailer`, `dotenv`, `cors` |
| **Servidor TCP** | Java 21+, Sockets TCP (`java.net.ServerSocket` / `Socket`) |
| **Banco de Dados** | MongoDB (local ou MongoDB Atlas) |
| **Testes** | Node Test Runner (`node --import tsx --test`) e `flutter test` (`MockClient`, `WidgetTester`) |

---

## 🚀 Como Executar o Projeto

### Pré-requisitos

- [Node.js LTS](https://nodejs.org/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) e Dart SDK
- [JDK 21+](https://www.oracle.com/java/technologies/downloads/)
- [MongoDB](https://www.mongodb.com/try/download/community) local ou cluster no MongoDB Atlas
- Emulador Android/iOS, navegador web, desktop ou dispositivo físico conectado

---

### 1. Clonar o repositório

```bash
git clone https://github.com/mariaoleto/ES-PI4-2026-T1-G26.git
cd ES-PI4-2026-T1-G26
```

---

### 2. Iniciar o Servidor Socket TCP Java (porta `5050`)

O servidor TCP deve estar rodando antes de consultar telemetria em tempo real ou gerar cálculos distribuídos diretamente no Java (se estiver offline, o backend Node utiliza fallback local automaticamente, exceto no endpoint de telemetria).

**No PowerShell (Windows):**

```powershell
# Na raiz do repositório
New-Item -ItemType Directory -Force -Path backend/java/bin | Out-Null
$arquivosJava = Get-ChildItem -Path backend/java/src/main/java -Filter *.java -Recurse | ForEach-Object { $_.FullName }
javac -encoding UTF-8 -d backend/java/bin $arquivosJava
java -cp backend/java/bin br.com.solis.tcp.Servidor
```

**No Bash / Linux / macOS:**

```bash
mkdir -p backend/java/bin
javac -encoding UTF-8 -d backend/java/bin $(find backend/java/src/main/java -name "*.java")
java -cp backend/java/bin br.com.solis.tcp.Servidor
```

> Para encerrar o servidor Java de forma limpa, digite `desativar` no terminal em que ele estiver rodando. Também é possível passar outra porta como argumento (`java -cp backend/java/bin br.com.solis.tcp.Servidor 5050`).

#### Comandos suportados no protocolo TCP (`127.0.0.1:5050`)

| Comando | Resposta esperada | Finalidade |
|---|---|---|
| `PING` | `PONG` | Verificação de disponibilidade |
| `HELP` | `Comandos: PING, STATUS_USINA, CALCULAR_COTAS, SAIR` | Lista os comandos do protocolo |
| `STATUS_USINA` | `OK USINA=Solis_1 STATUS=OPERANDO GERACAO_ATUAL=14.2kW TENSAO=220V FREQ=60Hz` | Telemetria instantânea da usina |
| `CALCULAR_COTAS total=1240;cotas=25,30,45` | `OK 25.0%=310.0kWh;30.0%=372.0kWh;45.0%=558.0kWh` | Cálculo proporcional dos créditos em kWh |
| `SAIR` | `BYE` | Encerra a sessão TCP do cliente |

---

### 3. Configurar e executar o Backend Node.js (porta `3000`)

```bash
cd backend/node
npm install
cp .env.example .env
```

Edite `backend/node/.env` configurando as variáveis necessárias:

| Variável | Obrigatória | Padrão / Observação |
|---|---|---|
| `MONGODB_URI` | Sim | URI do MongoDB local ou Atlas (ex.: `mongodb://127.0.0.1:27017/solis`) |
| `JWT_SECRET` | Sim | Segredo aleatório com **pelo menos 16 caracteres** (`openssl rand -hex 32`) |
| `PORT` | Não | `3000` |
| `NODE_ENV` | Não | `desenvolvimento` (em `production`, o envio de e-mail exige SMTP configurado) |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM` | Não (dev) / Sim (`production`) | Configuração SMTP para envio real do código de recuperação de senha; sem `SMTP_HOST` em desenvolvimento, o código é exibido no console do servidor |

Executar em desenvolvimento ou produção:

```bash
# Modo desenvolvimento (hot reload)
npm run dev

# Ou compilar e rodar build de produção
npm run build
npm start
```

Criar ou promover um administrador pelo terminal:

```bash
npm run criar-admin -- "Nome Sobrenome" admin@solis.com.br SenhaForte123
```

> A API sobe por padrão em `http://localhost:3000` (`GET /` retorna `{"status": "Solis API rodando"}`).

---

### 4. Configurar e executar o Aplicativo Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter devices
flutter run
```

#### Apontamento automático da URL da API

- **Emulador Android:** usa automaticamente `http://10.0.2.2:3000`
- **Web, Desktop (Windows/Linux/macOS) e Simulador iOS:** usa automaticamente `http://localhost:3000`
- **Dispositivo físico ou host customizado:** passe `--dart-define=SOLIS_URL_API=http://SEU_IP:3000` ao executar:

```bash
flutter run --dart-define=SOLIS_URL_API=http://192.168.0.10:3000
```

---

## 🔌 Principais Rotas da API REST (Node.js)

| Módulo | Método e Rota | Autenticação | Descrição |
|---|---|---|---|
| **Status** | `GET /` | Pública | Healthcheck da API |
| **Auth** | `POST /auth/cadastro` | Pública | Cria conta de `membro` ou `admin` (com CPF válido) e devolve JWT |
| **Auth** | `POST /auth/login` | Pública | Autentica membro ou administrador (`perfil`) e devolve JWT |
| **Auth** | `POST /auth/recuperar-senha` | Pública | Gera código temporário de 6 dígitos e envia por e-mail/console |
| **Auth** | `POST /auth/redefinir-senha` | Pública | Valida código e atualiza a senha |
| **Perfil** | `GET /perfil` | Bearer JWT | Retorna dados do usuário autenticado (admin pode consultar por `?membro_id=` ou `?email=`) |
| **Perfil** | `PUT /perfil/:id` | Bearer JWT | Atualiza nome, e-mail e telefone |
| **Perfil** | `PUT /perfil/:id/senha` | Bearer JWT | Altera a senha conferindo a senha atual |
| **Perfil** | `GET /perfil/:id/contrato` | Bearer JWT | Retorna o contrato e dados de cota do membro |
| **Painel Membro** | `GET /painel-membro` e `/painel-membro/dashboard` | Aberta (query `?membro_id=` ou `?email=`) | Retorna resumo consolidado para a tela inicial do membro |
| **Painel Admin** | `GET /admin/painel` | Aberta (query `?usina_id=`) | Retorna situação da usina, cotas, alertas e lançamentos pendentes |
| **Energia** | `GET /energia` | Aberta (query `?ano=&usina_id=&membro_id=`) | Retorna resumo mensal/anual de geração, consumo, créditos e economia |
| **Energia** | `GET /energia/cotas` | Aberta (query `?usina_id=&membro_id=`) | Lista as cotas e tarifas dos membros |
| **Energia** | `POST /energia/lancamento` | Aberta | Salva geração do mês e distribui créditos via TCP Java (ou fallback) |
| **Energia** | `GET /energia/telemetria-tcp` | Aberta | Consulta `STATUS_USINA` na porta `5050` (`200` online / `503` offline) |
| **Relatórios** | `POST /relatorios/mensal` | Bearer JWT | Gera PDF mensal (`{"referencia":"AAAA-MM"}`) com dados e telemetria TCP (retorna PDF + `X-Relatorio-Id`) |
| **Relatórios** | `POST /relatorios/extrato-creditos` | Bearer JWT | Gera PDF do extrato mensal (`{"referencia":"AAAA-MM"}`) |
| **Relatórios** | `POST /relatorios/demonstrativo-anual` | Bearer JWT | Gera PDF agregado anual (`{"ano":"AAAA"}`) |
| **Relatórios** | `GET /relatorios` | Bearer JWT | Lista metadados dos relatórios do membro (inclui `origem_dados_tcp` e `telemetria_tcp`) |
| **Relatórios** | `GET /relatorios/:id/ticket` | Bearer JWT | Emite ticket HMAC-SHA256 válido por 120 s para abertura externa do PDF |
| **Relatórios** | `GET /relatorios/:id/download` | Bearer JWT ou `?ticket=` | Retorna o binário `application/pdf` salvo no MongoDB |

---

## 🧪 Testes e Verificações Automatizadas

**Backend Node.js (`backend/node/`):**

```bash
npm test       # Executa auth, painel_admin, perfil e relatorios
npm run build  # Valida compilação TypeScript (tsc)
```

**Aplicativo Mobile (`mobile/`):**

```bash
flutter analyze
flutter test   # Executa auth, painel_admin, painel_membro, perfil, relatorios, usina_page e widget_test
```

---

## 📁 Estrutura do Repositório

```text
projeto-solis/
├── backend/
│   ├── java/                        # Servidor Socket TCP (porta 5050)
│   │   ├── src/main/java/br/com/solis/tcp/
│   │   │   ├── protocol/            # PedidoStatusUsina, PedidoCalcularCotas, Resultado, etc.
│   │   │   ├── service/             # TcpService.java (cálculo de cotas)
│   │   │   ├── AceitadoraDeConexao.java
│   │   │   ├── Parceiro.java
│   │   │   ├── Servidor.java
│   │   │   └── SupervisoraDeConexao.java
│   │   └── pom.xml
│   └── node/                        # API REST (TypeScript, Express 5, Mongoose 9)
│       ├── src/
│       │   ├── config/env.ts
│       │   ├── modules/
│       │   │   ├── auth/
│       │   │   ├── geracao_creditos/
│       │   │   ├── painel_admin/
│       │   │   ├── painel_membro/
│       │   │   ├── perfil/
│       │   │   └── relatorios/
│       │   ├── scripts/criar_admin.ts
│       │   ├── utils/cliente_tcp_java.ts
│       │   └── server.ts
│       ├── tests/
│       ├── .env.example
│       └── package.json
├── mobile/                          # Aplicativo Flutter / Dart
│   ├── lib/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── geracao_creditos/
│   │   │   ├── gestao/
│   │   │   ├── painel_admin/
│   │   │   ├── painel_membro/
│   │   │   ├── perfil/
│   │   │   └── relatorios/
│   │   └── main.dart
│   ├── test/
│   └── pubspec.yaml
├── docs/                            # Dicionário de dados e documentação
│   ├── dicionario_de_dados.md
│   └── documentacao.pdf
└── README.md
```

---

## 📌 Informações Acadêmicas

| Campo | Informação |
|---|---|
| Instituição | PUC-Campinas |
| Curso | Engenharia de Software |
| Disciplina | Projeto Integrador IV |
| Ano | 2026 |
| Professor Orientador | Renata Arantes |
| Repositório | PI_IV-TIME-24 |

---

*Projeto desenvolvido exclusivamente para fins acadêmicos.*
