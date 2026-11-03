# Dicionário de Dados: Sistema de gerenciação de energia solar compartilhada da empresa Solis.

## 1. Histórico de versões (ou revisões)

| Data | Autor | Versão | Comentários |
| :---: | :---: | ---: | :--- |
| 03/09/2026 | Maria Júlia Lazarini Oleto | 1.0.0-solis101 | Versão inicial - Título e estrutura do documento, citação das entidades e suas descrições |

## 2. Entidades e atributos conceituais

### 2.1. Membro

> Membro é caracterizado como aquele que possui uma porcentagem de geração de créditos de energia provida de uma usina solar compartilhada, possuindo o direito de usufrui-la, baseado na sua participação percentual, ou que atua no perfil de gestão e operação administrativa da usina.

#### Atributos da Entidade Membro

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
|:---|:---:|:---:|:---:|:---|:---|:---|
| _id | Identificador único | Sim | Simples | 000000000000000000000065 | "", nulo, 123 | Chave primária única gerada pelo banco (ObjectId de 24 caracteres hexadecimais). |
| nome | Texto alfanumérico | Sim | Simples | João Oliveira, Ana Beatriz Souza, 123 Log&Cia | "", "A", "   " | Nome completo do consorciado ou razão social. Mínimo de 3 caracteres. |
| email | E-mail | Sim | Simples | joao@email.com, ana.beatriz@email.com | joao@, @email.com, joaoemail | Chave de autenticação e comunicação do usuário. Deve ser único no sistema e seguir formato RFC 5322. |
| senha_hash | Hash criptográfico | Sim | Simples | $2b$10$examplehash1... | 123456, senha123, "" | Hash seguro da senha gerado via algoritmo bcrypt. O sistema nunca armazena a senha em texto puro. |
| telefone | Telefone | Não | Simples | (19) 99876-5432, 19998765432 | 123, texto, (00) 0000-0000 | Telefone de contato para avisos urgentes e comunicação operacional. |
| tipo_usuario | Elemento enumerado | Sim | Simples | "membro", "administrador" | "root", "gestor", "comum", "" | Perfil de permissão e nível de autorização de acesso às telas do sistema. |
| usina_id | Identificador referencial | Sim | Simples | 000000000000000000000001 | "", nulo | Referência à entidade Usina à qual o membro está vinculado. |
| data_cadastro | Data e hora | Sim | Simples | 2024-03-01T00:00:00Z | 31/02/2024, data futura, "" | Registro temporal de ingresso do consorciado na usina. |

### 2.2. Usina

> Usina é a unidade geradora de energia solar fotovoltaica pertencente ao consórcio, responsável pela produção física de energia que será convertida em créditos e distribuída proporcionalmente entre os membros.

#### Atributos da Entidade Usina

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
|:---|:---:|:---:|:---:|:---|:---|:---|
| _id | Identificador único | Sim | Simples | 000000000000000000000001 | "", nulo | Identificador exclusivo da usina geradora. |
| nome | Texto alfanumérico | Sim | Simples | Consórcio Solis, Usina Solis 1 | "", "U" | Nome fantasia ou denominação oficial do consórcio gerador. |
| codigo | Código alfanumérico | Sim | Simples | SP-Norte-01, MG-Sul-02 | "", "codigo", "123" | Código identificador operacional e regulatório da unidade geradora. |
| potencia_instalada_kwp | Número decimal | Sim | Simples | 15.0, 75.5, 100.0 | -5, 0, "15kW" | Potência de pico nominal instalada (em kWp). Deve ser estritamente maior que zero. |
| distribuidora | Texto alfanumérico | Sim | Simples | CPFL Piratininga, Enel SP, Cemig | "", "123" | Concessionária de energia elétrica responsável pela rede de distribuição local. |
| localizacao | Localização geográfica | Sim | Composto (C) | { cidade: "Campinas", estado: "SP" } | "Campinas", "", { cidade: "" } | Estrutura composta por cidade e sigla federativa de instalação física da usina. |
| data_operacao | Data | Sim | Simples | 2024-01-01T00:00:00Z | "", datas inválidas | Data de homologação e início do fornecimento de energia pela usina à rede. |

### 2.3. Cota

> Cota é a fração ideal ou percentual contratado por um membro sobre a capacidade e a geração total de uma usina solar, servindo de base de cálculo para a divisão dos créditos mensais.

#### Atributos da Entidade Cota

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
|:---|:---:|:---:|:---:|:---|:---|:---|
| _id | Identificador único | Sim | Simples | 00000000000000000000012d | "", nulo | Identificador exclusivo do registro de cota. |
| membro_id | Identificador referencial | Sim | Simples | 000000000000000000000065 | "", nulo | Chave de relacionamento com o membro titular da cota. |
| usina_id | Identificador referencial | Sim | Simples | 000000000000000000000001 | "", nulo | Chave de relacionamento com a usina geradora. |
| percentual | Número percentual | Sim | Simples | 25.0, 15.0, 10.0 | -10, 0, 105, "25%" | Percentual de participação da cota (0 < cota ≤ 100). A soma de todas as cotas da usina não pode exceder 100%. |
| tarifa_kwh | Moeda / Valor monetário | Sim | Simples | 0.82, 0.69, 0.75 | -0.5, 0, "R$ 0,80" | Valor pactuado em Reais por kWh gerado/compensado. Deve ser maior que zero. |
| data_inicio | Data | Sim | Simples | 2024-03-01T00:00:00Z | "", datas inconsistentes | Início da vigência do direito de compensação da cota. |

### 2.4. Geração Mensal

> Geração Mensal é o registro consolidado da quantidade de energia elétrica (em kWh) gerada pela usina solar ao longo de um determinado mês de faturamento da distribuidora.

#### Atributos da Entidade Geração Mensal

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
|:---|:---:|:---:|:---:|:---|:---|:---|
| _id | Identificador único | Sim | Simples | 000000000000000000000191 | "", nulo | Identificador exclusivo do lançamento de geração. |
| usina_id | Identificador referencial | Sim | Simples | 000000000000000000000001 | "", nulo | Chave de relacionamento com a usina de origem. |
| mes_referencia | Mês/Ano de competência | Sim | Simples | "2026-01", "2026-09" | "01/2026", "2026", "Janeiro" | Período de faturamento no formato estrito AAAA-MM. |
| geracao_kwh | Número decimal | Sim | Simples | 284.0, 312.5, 340.0 | -50, 0, "300kWh" | Quantidade de energia elétrica gerada no mês em quilowatts-hora (kWh). Maior que zero. |
| data_lancamento | Data e hora | Sim | Simples | 2026-01-28T00:00:00Z | "", nulo | Data e hora em que a medição foi inserida no sistema pelo administrador. |

### 2.5. Crédito

> Crédito é o volume individualizado de energia solar (em kWh brutos e líquidos) concedido ao membro no mês de apuração, resultante da aplicação de sua cota sobre a geração total da usina.

#### Atributos da Entidade Crédito

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
|:---|:---:|:---:|:---:|:---|:---|:---|
| _id | Identificador único | Sim | Simples | 0000000000000000000001f5 | "", nulo | Identificador exclusivo do crédito apurado. |
| membro_id | Identificador referencial | Sim | Simples | 000000000000000000000065 | "", nulo | Referência ao membro beneficiário dos créditos. |
| usina_id | Identificador referencial | Sim | Simples | 000000000000000000000001 | "", nulo | Referência à usina geradora. |
| mes_referencia | Mês/Ano de competência | Sim | Simples | "2026-06", "2026-09" | "06/26", "Junho" | Mês de competência da distribuição no formato AAAA-MM. |
| geracao_total_kwh | Número decimal | Sim | Simples | 310.0, 325.0 | -10, 0 | Total de energia gerada pela usina usado como base da partilha. |
| percentual_cota | Número percentual | Sim | Simples | 25.0, 15.0 | -5, 0, 105 | Cota do membro aplicada no cálculo no momento da apuração. |
| creditos_brutos_kwh | Número decimal | Sim | Simples | 77.5, 73.8 | -1, "77.5" | Volume calculado: (geracao_total_kwh * percentual_cota) / 100. |
| perdas_transmissao_kwh | Número decimal | Sim | Simples | 0.0, 2.5 | -1 | Desconto regulatório por perdas técnicas de rede, se aplicável. |
| creditos_liquidos_kwh | Número decimal | Sim | Simples | 77.5, 71.3 | -1 | Volume final de créditos disponíveis: (brutos - perdas). |

### 2.6. Consumo Mensal

> Consumo Mensal é a medição periódica de energia elétrica demandada e faturada na unidade consumidora do membro, confrontada com os créditos solares para aferição do saldo e da economia gerada.

#### Atributos da Entidade Consumo Mensal

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
|:---|:---:|:---:|:---:|:---|:---|:---|
| _id | Identificador único | Sim | Simples | 000000000000000000000259 | "", nulo | Identificador exclusivo do registro de consumo. |
| membro_id | Identificador referencial | Sim | Simples | 000000000000000000000065 | "", nulo | Chave de relacionamento com o membro consumidor. |
| mes_referencia | Mês/Ano de competência | Sim | Simples | "2026-01", "2026-09" | "01/26", "Jan" | Mês e ano de faturamento da distribuidora (AAAA-MM). |
| consumo_kwh | Número decimal | Sim | Simples | 210.0, 245.0, 192.0 | -10, "210" | Total consumido na residência/empresa do membro no mês em kWh. |
| economia_estimada_reais | Moeda / Valor monetário | Sim | Simples | 154.98, 180.81, 141.70 | -50, "150 reais" | Economia estimada em Reais obtida pelo membro naquele mês com a compensação solar. |

### 2.7. Custo

> Custo é qualquer obrigação financeira de operação e manutenção gerada pela usina solar compartilhada, discriminando a divisão proporcional (rateio) do valor entre os membros.

#### Atributos da Entidade Custo

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
|:---|:---:|:---:|:---:|:---|:---|:---|
| _id | Identificador único | Sim | Simples | 0000000000000000000002bc | "", nulo | Identificador exclusivo do lançamento de custo. |
| usina_id | Identificador referencial | Sim | Simples | 000000000000000000000001 | "", nulo | Chave de relacionamento com a usina correspondente. |
| tipo | Elemento enumerado | Sim | Simples | "manutencao", "seguro", "imposto", "operacional" | "", "outros", 123 | Categoria financeira/operacional da despesa. |
| descricao | Texto alfanumérico | Sim | Simples | Limpeza e manutenção preventiva dos painéis, Apólice anual do seguro da usina | "", "abc" | Detalhamento descritivo do serviço ou custo incorrido. |
| valor_total_reais | Moeda / Valor monetário | Sim | Simples | 450.00, 1200.00 | -100, 0 | Valor global da despesa a ser rateada entre os consorciados. |
| mes_referencia | Mês/Ano de competência | Sim | Simples | "2026-09" | "09/2026" | Mês e ano de cobrança da despesa (AAAA-MM). |
| rateio | Lista de itens de rateio | Sim | Multivalorado e Composto (MC) | Lista de objetos contendo `membro_id`, `percentual` e `valor_reais` para cada participante | [], [{}], lista vazia | Coleção de itens que especifica a partilha da despesa. A soma dos valores rateados deve equivaler ao valor_total_reais. |

### 2.8. Contrato

> Contrato é o instrumento jurídico formalizado entre os participantes e a entidade gestora da usina solar, estabelecendo direitos, deveres, regras de rateio e vigência do consórcio.

#### Atributos da Entidade Contrato

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
|:---|:---:|:---:|:---:|:---|:---|:---|
| _id | Identificador único | Sim | Simples | 0000000000000000000000c9 | "", nulo | Identificador exclusivo do contrato no sistema. |
| usina_id | Identificador referencial | Sim | Simples | 000000000000000000000001 | "", nulo | Chave de relacionamento com a usina contratada. |
| titulo | Texto alfanumérico | Sim | Simples | Contrato do Consórcio Solis, Termo de Adesão 2024 | "", "12" | Título descritivo do instrumento contratual. |
| data_assinatura | Data | Sim | Simples | 2024-03-01T00:00:00Z | "", datas inválidas | Data em que o documento foi formalizado juridicamente. |
| arquivo_url | Endereço URL | Sim | Simples | https://storage.solis.app/contratos/consorcio-solis.pdf | "c:\arquivo.pdf", "contrato", "" | Localizador uniforme de recursos (URL segura) para download do PDF original. |
| tamanho_mb | Número decimal | Sim | Simples | 3.2, 1.5, 0.8 | -1, 0, "3MB" | Tamanho físico do documento digital em Megabytes (MB). |

### 2.9. Relatório

> Relatório é um documento analítico gerado periodicamente em PDF que consolida as medições, créditos apurados e benefícios econômicos obtidos pelo membro em um intervalo temporal.

#### Atributos da Entidade Relatório

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
|:---|:---:|:---:|:---:|:---|:---|:---|
| _id | Identificador único | Sim | Simples | 000000000000000000000384 | "", nulo | Identificador exclusivo do registro do relatório. |
| membro_id | Identificador referencial | Sim | Simples | 000000000000000000000065 | "", nulo | Chave de relacionamento com o membro a quem o relatório pertence. |
| tipo | Elemento enumerado | Sim | Simples | "relatorio_mensal", "extrato_creditos", "demonstrativo_anual" | "", "pdf", "planilha" | Classificação do modelo e periodicidade do relatório gerado. |
| titulo | Texto alfanumérico | Sim | Simples | Relatório mensal, Extrato de créditos, Demonstrativo anual | "", "Rel" | Título legível de exibição na lista de documentos do aplicativo. |
| referencia | Texto descritivo | Sim | Simples | Setembro 2026, Agosto 2026, 2025 — Completo | "", "2026" | Rótulo temporal humanizado do período de competência abrangido. |
| tamanho_mb | Número decimal | Sim | Simples | 2.1, 1.4, 5.8 | -1, 0, "2MB" | Peso do arquivo PDF em Megabytes para exibição ao usuário antes do download. |
| data_geracao | Data e hora | Sim | Simples | 2026-09-01T08:00:00Z | "", datas inconsistentes | Timestamp da compilação e emissão do demonstrativo. |
| arquivo_url | Endereço URL | Sim | Simples | https://storage.solis.app/relatorios/2026-09-mensal.pdf | "c:\relatorio.pdf", "" | URL direta e segura para visualização ou download do arquivo PDF. |

## 3. Tipos especiais, compostos ou específicos 

| Padrões de atributos especiais |
|----|
|(C) =  Composto (Tipo estruturado, composto de partes que juntas formam o atributo em si)|
|(M) =  Multivalorado (vários valores)|
|(MC) =  Multivalorado e Composto (lista / array etc de um tipo composto)|


### 3.1. <Localização> (Composto)

> Localização é composto de dois atributos: "cidade" e "estado", que guardam os dados principais da onde a usina está localizada.

| Atributo / Dado | Tipo conceitual | Obrigatório | Comentários |
| :---: | :--- | :---: | :--- |
| cidade | Texto | Sim | Cidade aonde a usina está localizada. |
| estado | Texto | Sim | Estado aonde a usina está localizada. |

### 3.2. <Rateio> (Multivalorado e Composto)

> Rateio é composto de um array de objetos numerados, que possuem os atributos: membro_id; percentual e valor_reais, que mapeiam a distribuição de custo de um determinado serviço referente a usina, de acordo com o membro, seu percentual e o valor cobrado.

| Atributo / Dado | Tipo conceitual | Obrigatório | Comentários |
| :---: | :--- | :---: | :--- |
| membro_id | ObjectId | Sim | Referencia por id de um membro. |
| percentual | NumberInt | Sim | Percentual do membro. |
| valor_reais | NumberInt | Sim | Valor cobrado do membro. |

## 4. Desdobramento físico ou tecnológico

### 4.1. Desdobramento para banco orientado a documentos

| Entidade conceitual | Coleção | Estratégia |
| :--- | :--- | :--- |
| <Usina> | <usina> | Valores Embutidos |

```json
{
  _id: ObjectId('000000000000000000000001'),
  nome: 'Consórcio Solis',
  codigo: 'SP-Norte-01',
  potencia_instalada_kwp: NumberInt('15'),
  distribuidora: 'CPFL Piratininga',
  localizacao: {
    cidade: 'Campinas',
    estado: 'SP'
  },
  data_operacao: ISODate('2024-01-01T00:00:00.000Z')
}
```

Justificativa: 
> Os dados são embutidos pois são pequenos, não são atualizados, não são frequentemente consultados e são de grande importancia no documento em que são colocados, esse sim que é referenciado em outras coleções.

| Entidade conceitual | Coleção | Estratégia |
| :--- | :--- | :--- |
| <Cuso> | <custos> | Valores Referenciados (membro_id) e Embutidos|


```json
{
  _id: ObjectId('0000000000000000000002bd'),
  usina_id: ObjectId('000000000000000000000001'),
  tipo: 'seguro',
  descricao: 'Apólice anual do seguro da usina',
  valor_total_reais: NumberInt('1200'),
  mes_referencia: '2026-09',
  rateio: [
    {
      membro_id: ObjectId('000000000000000000000065'),
      percentual: NumberInt('25'),
      valor_reais: NumberInt('300')
    },
    {
      membro_id: ObjectId('000000000000000000000066'),
      percentual: NumberInt('15'),
      valor_reais: NumberInt('180')
    },
    {
      membro_id: ObjectId('000000000000000000000067'),
      percentual: NumberInt('10'),
      valor_reais: NumberInt('120')
    }
  ]
}
```

Justificativa:

> Os dados referenciados (membro_id), são frequentemente usados em consultas, são referenciados diversas vezes em outras coleções e possuem mais dados atrelados a sua referencia, por isso são referenciados através do id.
Já os dados embutidos, são dados necessários nesse documento, não são frequentemente consultados ou refenciados em outros documentos ou coleções e não possuem outros dados vinculados a eles, podendo ser embutidos. 

## 5. Consultas, índices e observações de arquitetura

| Consulta esperada | Campos envolvidos | Índices sugeridos | Observações |
| :--- | :--- | :--- | :--- |
| **Autenticação e busca de membro por e-mail** | `email` | `membros: { email: 1 }` (Único) | Ponto de entrada de login do aplicativo. O índice único assegura que não existam contas duplicadas e viabiliza a busca rápida em $O(\log N)$. |
| **Resumo anual de geração da usina (Gráficos do Painel)** | `usina_id`, `mes_referencia` | `geracao_mensal: { usina_id: 1, mes_referencia: 1 }` (Composto / Único) | Alimenta os gráficos de barras mensais (Jan a Dez). O índice composto garante que só exista um registro por mês para cada usina e acelera filtros por ano (`^2026-`). |
| **Apuração e extrato de créditos do membro** | `membro_id`, `usina_id`, `mes_referencia` | `creditos: { membro_id: 1, usina_id: 1, mes_referencia: 1 }` (Composto / Único) | Consulta mais frequente do painel do membro. Garante a integridade na distribuição mensal e o cálculo imediato do saldo de créditos disponível. |
| **Histórico de consumo mensal da unidade consumidora** | `membro_id`, `mes_referencia` | `consumo_mensal: { membro_id: 1, mes_referencia: 1 }` (Composto) | Utilizada para confrontar a demanda real de energia com os créditos gerados, apurando o percentual utilizado e a economia em R$. |
| **Auditoria e rateio de cotas da usina** | `usina_id`, `percentual` | `cotas: { usina_id: 1, percentual: -1 }` (Composto) | Permite ao painel administrativo validar se a soma das cotas totaliza 100% e ordenar as cotas decrescentemente para o motor de rateio do servidor Java. |
| **Identificação da cota ativa do consorciado** | `membro_id`, `usina_id`, `data_inicio` | `cotas: { membro_id: 1, usina_id: 1, data_inicio: -1 }` (Composto) | Recupera a cota vigente do usuário logado para exibir o percentual e a tarifa contratada no cabeçalho do aplicativo. |
| **Apuração de despesas e custos operacionais** | `usina_id`, `mes_referencia` | `custos: { usina_id: 1, mes_referencia: -1 }` (Composto) | Lista as despesas operacionais da usina por período e recupera a partilha embutida (`rateio`) dos membros para prestação de contas. |
| **Feed de notificações e comunicados não lidos** | `membro_id`, `lida`, `data` | `notificacoes: { membro_id: 1, lida: 1, data: -1 }` (Composto) | Alimenta o badge contador de alertas e o feed de notificações do aplicativo ordenado das mensagens mais recentes para as mais antigas. |
| **Listagem de relatórios e extratos disponíveis** | `membro_id`, `data_geracao` | `relatorios: { membro_id: 1, data_geracao: -1 }` (Composto) | Permite a recuperação cronológica dos relatórios em PDF gerados para download do cooperado. |
| **Localização da usina ativa para operação** | `ativa`, `_id` | `usina: { ativa: 1, _id: 1 }` (Composto) | Permite ao painel administrativo recuperar instantaneamente os dados da usina principal em operação sem varredura completa da coleção. |