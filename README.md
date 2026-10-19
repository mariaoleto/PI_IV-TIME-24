# ☀️ Solis

> Aplicativo mobile de gestão de energia solar compartilhada para comunidades de geração distribuída.

---

## 📋 Descrição do Projeto

O **Solis** é um aplicativo mobile desenvolvido como projeto acadêmico na disciplina **Projeto Integrador 4** do curso de Engenharia de Software da PUC-Campinas (2026).

A proposta simula uma plataforma de gestão de energia solar compartilhada entre membros de um consórcio de geração distribuída, como vizinhos, condomínios ou pequenas comunidades rurais que dividem os créditos de uma mesma usina solar. O aplicativo calcula, com base na cota de participação de cada membro, os créditos de energia gerados, o consumo individual e a economia estimada, centralizando essas informações em um painel simples e acessível.

> ⚠️ Todos os dados de geração e consumo utilizados no sistema são fictícios/simulados. O sistema não realiza integração real com equipamentos, distribuidoras de energia ou sistemas financeiros externos.

---

### Funcionalidades principais

- **Cadastro e Consórcio** — Cadastro de membros, definição da cota de participação de cada um na usina e cadastro da usina compartilhada.
- **Geração e Créditos** — Registro da geração mensal de energia da usina e cálculo automático dos créditos de cada membro com base na sua cota.
- **Consumo e Economia** — Registro do consumo mensal de cada membro, cálculo do saldo de créditos e estimativa da economia gerada.
- **Painel do Membro** — Dashboard individual com créditos do mês, saldo acumulado, consumo e histórico simplificado.
- **Painel do Administrador** — Visão geral de todos os membros, cotas e geração total da usina, com opção de lançar/editar dados.
- **Notificações e Avisos** — Alertas de novo relatório disponível e de consumo acima dos créditos do mês.
- **Rateio de Custos** — Cadastro de custos fixos da usina (manutenção, seguro, taxa de administração) e rateio proporcional entre os membros.
- **Relatórios Exportáveis** — Geração de relatório mensal por membro para prestação de contas da cooperativa.
- **Simulador de Novo Membro** — Simulação de economia estimada para um novo interessado, com base no percentual de cota e consumo médio informado.
- **Indicador de Sustentabilidade** — Cálculo do CO2 evitado com base na energia gerada.

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

### Backend
| Tecnologia | Descrição |
|---|---|
| Node.js (LTS) | Runtime JavaScript para o servidor |
| TypeScript / JavaScript | Linguagens de desenvolvimento |
| Java/Spring Boot | Transição do node para java |

### Frontend (Mobile)
| Tecnologia | Descrição |
|---|---|
| Flutter | Framework de desenvolvimento mobile |
| Dart | Linguagem de programação |

### Banco de Dados
| Tecnologia | Descrição |
|---|---|
| MongoDB | Banco de dados não relacional |

### Servidor Java
| Tecnologia | Descrição |
|---|---|
| Java | Linguagem para serviços adicionais do backend |

---

## 🚀 Como Executar o Projeto

### Pré-requisitos

Certifique-se de ter instalado em sua máquina:

- [Node.js LTS](https://nodejs.org/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (incluído no Flutter)
- [MongoDB](https://www.mongodb.com/try/download/community) (instância local ou cluster no MongoDB Atlas)
- [JDK (Java Development Kit)](https://www.oracle.com/java/technologies/downloads/)
- [Git](https://git-scm.com/)
- Um emulador Android/iOS ou dispositivo físico conectado

---

### 1. Clonar o repositório

```bash
git clone https://github.com/[seu-usuario]/[nome-repositorio].git
cd [nome-repositorio]
```

---

### 2. Configurar e executar o Backend

O projeto possui duas implementações do backend dentro da pasta `backend/`:

#### 2.1 Backend em Node.js (TypeScript)

```bash
# Acesse a pasta do backend Node
cd backend/node

# Instale as dependências
npm install

# Configure as variáveis de ambiente
cp .env.example .env
# Edite o arquivo .env com a string de conexão do MongoDB Atlas

# Execute em modo de desenvolvimento
npm run dev
```

> O servidor estará disponível em `http://localhost:3000`.

#### 2.2 Backend em Java (Spring Boot)

```powershell
# Acesse a pasta do backend Java
cd backend/java

# Configure a variável de ambiente do MongoDB (opcional, padrão: mongodb://localhost:27017/solis)
$env:MONGODB_URI = "sua_string_de_conexao_mongodb"

# Execute a aplicação Spring Boot
.\mvnw.cmd spring-boot:run
```

> O servidor Java também sobe na porta `3000` (`http://localhost:3000`), garantindo paridade total com o app mobile.

---

### 3. Configurar o Banco de Dados MongoDB

Certifique-se de que o MongoDB esteja em execução localmente, ou informe a URI de um cluster remoto (por exemplo, MongoDB Atlas) na variável de ambiente `MONGODB_URI`.

---

### 4. Configurar e executar o Aplicativo Mobile

```bash
# Acesse a pasta do mobile
cd mobile

# Instale as dependências do Flutter
flutter pub get

# Verifique se há um emulador rodando ou dispositivo conectado
flutter devices

# Execute o aplicativo
flutter run
```

---

## 📁 Estrutura do Repositório

```text
projeto-solis/
├── backend/
│   ├── java/              # Servidor Spring Boot (Java 21, Maven)
│   │   ├── src/
│   │   │   ├── main/java/PIV/solis/
│   │   │   │   ├── Controllers/
│   │   │   │   ├── Models/
│   │   │   │   ├── Repositories/
│   │   │   │   └── Services/
│   │   │   └── main/resources/application.properties
│   │   ├── pom.xml
│   │   └── mvnw.cmd
│   └── node/              # Servidor Node.js (TypeScript, Express)
│       ├── src/
│       │   ├── modules/geracao_creditos/
│       │   └── server.ts
│       ├── package.json
│       └── tsconfig.json
├── mobile/                # Aplicativo mobile (Flutter / Dart)
│   ├── lib/
│   │   ├── features/auth/
│   │   └── src/geracao_consumos/
│   └── pubspec.yaml
├── banco/                 # Scripts e esquemas do MongoDB
├── docs/                  # Documentação do projeto
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
| Repositório | PI_IV-TIME-24|

---

*Projeto desenvolvido exclusivamente para fins acadêmicos.*
