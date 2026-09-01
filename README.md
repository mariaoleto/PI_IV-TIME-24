# ☀️ Solis
>

---

## 📋 Descrição do Projeto



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

> ⚠️ Todos os dados de geração e consumo utilizados no sistema são fictícios/simulados. O sistema não realiza integração real com equipamentos, distribuidoras de energia ou sistemas financeiros externos.

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
- [MongoDB](https://www.mongodb.com/try/download/community) (instância local ou cluster no MongoDB Atlas)
- [JDK (Java Development Kit)](https://www.oracle.com/java/technologies/downloads/)
- [Git](https://git-scm.com/)

---

### 1. Clonar o repositório

```bash
git clone https://github.com/[seu-usuario]/[nome-repositorio].git
cd [nome-repositorio]
```

---

### 2. Configurar e executar o Backend

```bash
# Acesse a pasta do backend
cd backend

# Instale as dependências
npm install

# Configure as variáveis de ambiente
cp .env.example .env
# Edite o arquivo .env com a string de conexão do MongoDB e demais configurações

# Execute em modo de desenvolvimento
npm run dev
```

> O servidor estará disponível em `http://localhost:3000` (ou a porta configurada no `.env`).

---

### 3. Configurar o Banco de Dados MongoDB

Certifique-se de que o MongoDB esteja em execução localmente, ou configure a string de conexão de um cluster remoto (ex: MongoDB Atlas) no arquivo `.env` do backend.

---

### 4. Configurar e executar o Servidor Java

```bash
# Acesse a pasta do servidor Java
cd servidor-java
```

> Framework e ferramenta de build (Maven, Gradle etc.) ainda não definidos pela equipe. Assim que forem escolhidos, complete esta seção com os comandos de compilação e execução correspondentes.

---

## 📁 Estrutura do Repositório

```text

```

### Organização da Arquitetura



---

## 📌 Informações Acadêmicas

| Campo | Informação |
|---|---|
| Instituição | PUC-Campinas |
| Curso | Engenharia de Software |
| Disciplina | Projeto Integrador 4 |
| Ano | 2026 |
| Professor Orientador | |
| Repositório | |

---

*Projeto desenvolvido exclusivamente para fins acadêmicos.*
