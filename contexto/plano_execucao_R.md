# Plano de execução em R — redes de dependência e previsão de perdas em criptoativos

**Versão:** 1.0.0. **Data:** 02/11/2026. **Linguagem:** R. **Situação:** protocolo consolidado; coleta integral, estimações e resultados ainda pendentes.

Este documento substitui, para fins de execução, as especificações preliminares de [contexto.txt](contexto.txt). Incorpora as correções do [parecer crítico](avaliacao_critica_plano.md). Os originais permanecem como histórico. A configuração correspondente está em [config/projeto.R](../config/projeto.R) e o inventário inicial em [config/ativos_solicitados.csv](../config/ativos_solicitados.csv).

As citações são clicáveis e remetem diretamente ao artigo ou à documentação. **Fundamento** identifica uma contribuição da fonte; **decisão do projeto** identifica uma escolha operacional aqui proposta. Datas de corte, janelas, filtros, priors e critérios numéricos precisam ser registrados antes da avaliação final; não foram determinados pelos artigos citados.

## 1. Projeto, pergunta e contribuição

### 1.1. Título e objetivo

**Título:** Redes de dependência entre criptoativos e previsão probabilística de perdas: evidência com dados históricos da Binance.

**Objetivo geral:** avaliar se atributos de uma rede de dependência entre retornos acrescentam capacidade de prever perdas futuras, além de retornos passados, volatilidade, atividade de negociação e exposição ao Bitcoin e a uma medida de mercado da própria amostra. A unidade será o ativo no horário de previsão. A análise bayesiana representará explicitamente incerteza dos parâmetros e das previsões.

**Fundamento:** jogos em rede relacionam complementaridades e posição estrutural [Ballester et al., 2006][R01]; redes econômicas permitem estudar agregação e propagação quando as ligações têm mecanismo definido [Acemoglu et al., 2012][R02]. Redes de retornos e conectividade cripto já foram estudadas [Ji et al., 2019][R13]; [Będowska-Sójka et al., 2025][R14]. **Decisão do projeto:** a contribuição proposta será o teste incremental de informação de rede sob validação temporal, não a simples aplicação de centralidades.

### 1.2. Pergunta e hipóteses

**Pergunta:** atributos de uma rede estimada apenas com informação disponível até cada previsão melhoram a probabilidade prevista de perda superior a 5% em 24 horas, em comparação com modelos que já incorporam risco individual, mercado e Bitcoin?

| Hipótese | Comparação previamente definida | Resultado relevante | Origem |
| --- | --- | --- | --- |
| H1 | M3 contra M2, no mesmo algoritmo e mesmas observações | Redução de Brier Score fora da amostra | Decisão do projeto; regras de pontuação em [Gneiting e Raftery][R15] |
| H2 | M4 contra M3 | Informação adicional da interação entre exposição estatística ao BTC e estresse passado do BTC | Decisão do projeto; multiplicador inspirado em [Ballester et al.][R01] |
| H3 | Repetição das comparações por ano, janela e definição de rede | Estabilidade ou heterogeneidade do ganho | Decisão do projeto; validação prospectiva em [Bürkner et al.][R19] |
| H4 | Modelos bayesianos B2 e B3 na amostra diária comum | Ganho preditivo e posterior de associações condicionais de rede | Decisão do projeto; priors e checagem em [Gelman et al.][R17] e [Gabry et al.][R18] |

Ausência de melhora é um resultado válido. Não se estabelecerá antecipadamente que todos os coeficientes de centralidade devem ser positivos. Os resultados de estabilidade em redes financeiras dependem das condições dos choques e da estrutura [Acemoglu, Ozdaglar e Tahbaz-Salehi][R03].

### 1.3. Alcance das conclusões

O desfecho será **perda de preço em USDT**, e as ligações serão **dependências estatísticas entre retornos**. Retornos negativos não constituem, sozinhos, uma medida de confiança nem uma identificação de contágio. Mudanças de volatilidade também afetam a interpretação das correlações [Forbes e Rigobon][R08]. A estratégia não identifica o efeito causal de alterar a centralidade [Manski][R09]; [Bramoullé et al.][R10].

“Dispersão” será entendida como propagação em redes. A inversa de rede será usada para construir atributos e cenários condicionais; não será apresentada como estimativa observada da circulação de confiança. Modelos de aprendizado social descrevem agentes, sinais e decisões, objetos diferentes de uma classificação de preços pelo pesquisador [Acemoglu et al., 2011][R07]. O trabalho não estimará, neste núcleo, insolvência de instituições ou probabilidade conjunta de colapso do sistema [Haldane e May][R04]; [Bardoscia et al.][R05].

## 2. Especificações operacionais fixadas

Os valores abaixo são **decisões deste protocolo**. Sua fundamentação conceitual aparece nas seções seguintes. Alterações decorrentes do piloto deverão gerar nova versão da configuração, com justificativa, antes de abrir as métricas do teste final.

| Elemento | Especificação principal |
| --- | --- |
| Mercado | Binance spot; pares diretos com USDT |
| Universo inicial | Lista intencional de 17 nomes enviada em `moedas.txt`, sujeita a confirmação de identidade e disponibilidade |
| Rede principal | BTC como âncora + até 14 outros ativos de risco; MUSD e PAXG em análises separadas |
| Alvos principais | Até 14 ativos; BTC participa da rede, mas não da comparação principal de perdas das demais moedas |
| Frequência bruta / previsões | Candles de 1 hora / origens horárias |
| Fuso | UTC em dados, janelas e cortes |
| Busca de arquivos | Meses a partir de agosto de 2017; início real por par determinado pela auditoria |
| Período de origens analíticas | `2020-01-01 00:00:00 <= t < 2026-11-01 00:00:00` |
| Extensão bruta para maturar alvos | Coletar candles com abertura anterior a `2026-11-02 00:00:00`; verificar disponibilidade real |
| Alvo | Retorno simples entre fechamentos em `t` e `t+24h` estritamente menor que `−0,05` |
| Rede | Correlação de retornos horários, janela de 90 dias; atualização às 00h UTC |
| Elegibilidade da rede | 90 dias de calendário observáveis; cobertura de retornos >=98%; BTC presente; pelo menos 5 nós |
| Aresta principal | Correlação positiva >=0,30; diagonal zero; matriz simétrica |
| Atenuação do multiplicador | `κ = 0,50`, após escala global que assegure soma máxima de linha <=1 |
| Ajuste dos modelos clássicos | Mensal; janela móvel de até 730 dias de origens com rótulos já observáveis |
| Calibração | Sigmoide sobre previsões históricas fora da amostra dos 90 dias anteriores, com rótulos maturados |
| Desenvolvimento | Origens anteriores a 01/07/2024; avaliação interna temporal, iniciada em 2022 |
| Validação operacional | 01/07/2024 a 31/12/2024; protocolo escolhido sem consultar o teste |
| Teste final prospectivo simulado | 01/01/2025 a 31/10/2026, com atualização mensal previamente programada |
| Comparação principal | Ridge-logit M3 contra M2; Naive Bayes fornece comparação adicional com os mesmos blocos |
| Métrica principal | Diferença pareada de Brier Score, com igual peso para cada observação elegível |
| Inferência bayesiana | Painel diário não sobreposto, componente comum temporal e interceptos por ativo |

O período longo de busca serve à auditoria e à formação do histórico; não pressupõe que todos os ativos existiam desde 2017. A previsão será retrospectiva, reconstruindo a informação que estaria disponível no horário, a partir dos arquivos baixados hoje. Isso não garante recuperar versões históricas anteriores a revisões da fonte. **Origem:** arquitetura de dados do projeto; arquivos e revisões documentados no [repositório oficial da Binance][D01].

## 3. Dados necessários e fontes

### 3.1. População e identidade dos ativos

O [inventário inicial](../config/ativos_solicitados.csv) contém **17 candidatos**, não 17 pares confirmados. MUSD exige atenção à identidade: ticker igual não demonstra que se trata do emissor ou ativo pretendido. HYPE, assim como qualquer outro candidato, só entrará se houver histórico **spot** adequado; disponibilidade de futuros não é prova de disponibilidade spot. BTC será âncora da rede. MUSD e PAXG serão tratados separadamente por sua proposta de referência econômica distinta, a confirmar documentalmente.

Consultar uma vez o catálogo atual, salvar o JSON original e cruzar `symbol`, `baseAsset`, `quoteAsset`, permissões e situação quando presentes. O endpoint descreve informações **atuais**. Em paralelo, procurar os arquivos históricos de cada símbolo candidato, inclusive quando ele não constar do catálogo atual. Nomear a primeira data como “primeira observação disponível”, salvo evidência específica da listagem. **Fonte:** [exchangeInfo][D03] e [API pública de mercado][D04].

**Decisão do projeto:** a amostra principal é intencional e condicionada aos nomes escolhidos hoje. Incluir apenas esses nomes não elimina viés de seleção ou de sobrevivência. A generalização será para essa amostra e sua cobertura. Uma expansão para todos os pares históricos USDT será um protocolo adicional, com catálogo próprio de deslistagens, migrações e identidades. Não afirmar que ela já foi implementada.

### 3.2. Base obrigatória

| Base | Unidade | Campos a preservar | Extração e utilização | Fonte direta |
| --- | --- | --- | --- | --- |
| Catálogo atual | Símbolo / data da consulta | Resposta JSON original e campos de identificação | `GET /api/v3/exchangeInfo`; auditoria de identidade atual | [Documentação][D03] |
| Candles spot de 1h | Símbolo / abertura do candle | Abertura, máxima, mínima, fechamento, volumes, contagem e timestamps originais | ZIPs mensais; diários ou API para complementação; retornos e atributos | [Arquivos][D01]; [klines][D05] |
| Checksums | Arquivo ZIP | SHA-256 esperado e calculado | Baixar arquivo `.CHECKSUM`; validar integridade | [Repositório oficial][D01] |
| Histórico documental de instrumentos | Ativo / evento | URL, data pública, ticker anterior e novo, evidência da identidade | Consulta documental para casos de migração/deslistagem; registro manual auditável | Documento primário específico encontrado em cada caso; salvar URL e cópia |
| Manifesto da extração | Arquivo / versão | URL, estado HTTP, hash, bytes, extração UTC, intervalo e parser | Gerado pelo projeto para rastrear cada transformação | Decisão de engenharia; [digest][P03] |

A base principal não exigirá API privada, carteira, conta de negociação, dados on-chain, notícias ou indicador de sentimento. Esses objetos seriam necessários a outras perguntas e ampliariam o escopo. Acesso sem autenticação aos endpoints de mercado é documentado pela [Binance][D04].

### 3.3. Campos dos candles

O CSV do arquivo spot contém 12 posições. O parser deve conferir número de colunas e eventual cabeçalho, sem descartar a primeira linha automaticamente. Preservar o ZIP como registro canônico. **Fonte do esquema:** [Kline/Candlestick data][D05].

| Posição no CSV | Nome analítico | Unidade e uso |
| --- | --- | --- |
| 1 | `open_time_raw` | Timestamp inteiro original; manter também como texto |
| 2–5 | `open`, `high`, `low`, `close` | Preço em USDT por unidade do ativo |
| 6 | `base_volume` | Volume na moeda-base; não somar entre moedas diferentes |
| 7 | `close_time_raw` | Timestamp final informado pela fonte |
| 8 | `quote_volume` | Volume negociado em USDT |
| 9 | `trade_count` | Número de negociações |
| 10–11 | `taker_buy_base_volume`, `taker_buy_quote_volume` | Volume de execução compradora agressora; não identifica crença ou identidade |
| 12 | `ignore` | Preservar sem uso substantivo |

Valores de mercado em USDT não serão chamados de dólares. Converter para USD exigiria série independente de USDT/USD com fonte, horário e cobertura. Também não será criado um fator de tamanho por capitalização usando apenas volume: faltam preços e quantidades em circulação históricos para reproduzir essa construção. **Fundamento:** distinção entre a nossa base e o modelo de fatores de [Liu, Tsyvinski e Wu][R12]; **decisão:** manter USDT e explicitar a limitação.

## 4. Pacotes de R e suas funções

Instalar os pacotes da coluna “núcleo” na preparação e os bayesianos na etapa correspondente. Registrar as versões efetivamente instaladas em `renv.lock`, em vez de presumir que uma versão futura ou uma página de desenvolvimento corresponde ao ambiente local. `Matrix` e `boot` podem já acompanhar a instalação de R, mas devem ser registrados quando usados. **Fonte:** [renv][P01].

| Pacote | Uso neste projeto | Grupo | Documentação direta |
| --- | --- | --- | --- |
| `renv` | Biblioteca do projeto, snapshot e restauração | Núcleo | [Guia][P01] |
| `httr2` | Requisições, download em disco, timeout e repetição de erros transitórios | Núcleo | [req_perform][P02]; [req_retry][P02R] |
| `jsonlite` | Leitura e gravação do catálogo/metadados JSON | Núcleo | [Manual][P04] |
| `digest` | SHA-256 dos arquivos e identificadores de execução | Núcleo | [Documentação][P03] |
| `data.table` | Leitura de CSV, junções por horário, agregações e painéis | Núcleo | [fread][P05] |
| `lubridate` | Datas, limites de calendário e fuso UTC | Núcleo | [Documentação][P06] |
| `slider` | Janelas indexadas por tempo; especificar que são retrospectivas | Núcleo | [slide_index][P07] |
| `arrow` | Armazenamento Parquet e leitura particionada | Núcleo | [Guia][P08] |
| `DBI`, `duckdb` | Consultas locais ao painel sem carregar tudo em RAM | Núcleo | [DBI][P09]; [DuckDB R][P10] |
| `igraph` | Grafos, força dos vínculos e intermediação ponderada | Núcleo | [Matriz de adjacência][P11]; [intermediação][P12] |
| `Matrix`; `base` | Matrizes esparsas quando úteis; `solve`, `eigen`, `cor`, `lm.fit` | Núcleo / base R | Ajuda local `?Matrix::Matrix`, `?solve`, `?eigen`, `?cor` |
| `glmnet` | Regressão logística ridge; grade explícita de penalização | Núcleo | [Guia dos autores][P13] |
| `naivebayes` | Gaussian Naive Bayes para atributos numéricos | Núcleo | [gaussian_naive_bayes][P14] |
| `yardstick` | ROC-AUC, PR-AUC e average precision, com classe positiva explícita | Núcleo | [ROC-AUC][P26]; [PR-AUC][P15]; [average precision][P16] |
| `boot` | Bootstrap temporal por blocos, incluindo `tsboot` | Núcleo | [Manual][P17] |
| `ggplot2` | Cobertura, previsões, calibração e comparações | Núcleo | [Documentação][P18] |
| `targets` | Dependências, cache e execução por partes | Núcleo | [Manual][P19] |
| `brms` | Modelo bayesiano preliminar de interceptos por ativo | Bayesiano | [brm][P20] |
| `cmdstanr` + CmdStan | Ajuste do modelo bayesiano com estado temporal comum | Bayesiano | [Instalação e uso][P21] |
| `posterior`, `bayesplot` | Diagnóstico, resumos posteriores e checagens preditivas | Bayesiano | [Diagnósticos][P22]; [gráficos][P23] |
| `loo` | Recursos de avaliação bayesiana; uso temporal compatível com LFO | Bayesiano | [Leave-future-out][P24] |

**Escolha de implementação:** calcular Katz e a coluna do multiplicador por `solve()` com a convenção matricial desta proposta. Não depender de uma função de centralidade com orientação diferente sem verificar sua definição. **Fundamento:** [Ballester et al.][R01] e Newman, seção 7.1.3, no [livro local](../referencias/livro_newman_networks_2ed.txt).

## 5. Estrutura dos arquivos e situação das entregas

Os arquivos de configuração e os dois scripts iniciais abaixo foram entregues junto com este plano. Os demais nomes são **entregas a implementar**, não programas já concluídos. O piloto baixa três arquivos e audita formato; ele não treina modelos nem certifica cobertura da amostra inteira.

```text
sat-bayes/
  contexto/plano_execucao_R.md          # este protocolo
  config/projeto.R                    # entregue: escolhas centrais
  config/ativos_solicitados.csv        # entregue: candidatos e papéis
  scripts/00_preparar_ambiente.R        # entregue: ambiente e diretórios
  scripts/01_piloto_extracao.R          # entregue: extração inicial limitada
  R/                                  # a implementar: funções sem efeitos ocultos
  modelos/                            # a implementar: código Stan
  _targets.R                          # a implementar: grafo computacional
  dados/brutos/                       # ZIP, checksum, JSON e versões originais
  dados/intermediarios/                # candles limpos e auditoria
  dados/analiticos/                    # atributos, alvos, amostra e redes
  resultados/modelos/                  # objetos ajustados e posterior
  resultados/tabelas/
  resultados/figuras/
  resultados/auditoria/
  relatorios/
  logs/
  renv.lock                           # gerado após preparar o ambiente
```

Manter os dados brutos imutáveis por versão/hash; uma atualização da fonte gera outra versão. No `targets`, os arquivos devem ser dependências rastreáveis e as etapas de download precisam de um manifesto explícito de atualização: cache não descobre sozinho mudanças remotas. **Fontes:** [targets][P19], [renv][P01], revisões nos [dados Binance][D01].

## 6. Etapa 0 — preparar o ambiente

**Entrada:** repositório e uma instalação de R compatível. **Ações:** abrir a raiz `sat-bayes`, executar o script de preparação em sessão nova, instalar os pacotes do núcleo, criar diretórios, registrar `sessionInfo()` e gerar `renv.lock`. Foi localizada uma instalação de R 4.4.1 nesta máquina; a disponibilidade de binários e a compatibilidade de cada pacote ainda precisam ser verificadas na instalação. **Origem:** verificação local; procedimento baseado em [renv][P01].

No console de R/RStudio, executar:

```r
setwd("C:/Users/felip/sat-bayes")
source("scripts/00_preparar_ambiente.R", encoding = "UTF-8")
```

**Entrega:** ambiente restaurável, configuração carregada e log de versões. **Critério para avançar:** todos os pacotes do núcleo carregam; caminhos e fuso são os esperados. Não instalar CmdStan nesta etapa: a compilação será preparada na etapa bayesiana, seguindo a [documentação oficial][P21].

## 7. Etapa 1 — auditar candidatos e executar o piloto

**Entradas:** inventário de 17 nomes e metadados públicos. **Ações:** confirmar a identidade de cada candidato; salvar `exchangeInfo`; verificar ao menos um caso anterior e um posterior à mudança de unidade temporal. O piloto entregue consulta o catálogo e baixa BTCUSDT de dezembro/2024, BTCUSDT de janeiro/2025 e ETHUSDT de janeiro/2025. **Fontes:** [catálogo][D03], [arquivos Binance][D01].

```r
source("scripts/01_piloto_extracao.R", encoding = "UTF-8")
```

O script usa uma pasta nova por execução, verifica SHA-256, confirma o CSV esperado, confere as 12 colunas e valida preços, volumes e horários. Uma falha de consulta do catálogo é registrada e a situação do candidato permanece pendente. Falha de integridade do ZIP interrompe a leitura. **Fontes técnicas:** [httr2][P02], [repetições][P02R], [digest][P03] e [fread][P05].

**Entregas:** `manifesto_piloto.csv`, JSON quando acessível, ZIPs/checksums e candles em RDS. RDS é uma conveniência do piloto; o painel integral usará Parquet. **Critério:** auditar manualmente algumas linhas de cada mês, explicar lacunas e registrar quais pares/identidades ainda faltam. O piloto com BTC/ETH não aprova automaticamente os outros candidatos. **Decisão do projeto.**

## 8. Etapa 2 — extrair o histórico completo

### 8.1. Descoberta e calendário de arquivos

Para cada par confirmado ou candidato com evidência histórica, gerar os meses entre agosto/2017 e novembro/2026, respeitando o limite final da configuração. Solicitar o caminho mensal padrão e registrar o resultado. Se o arquivo mensal não existir ou estiver incompleto, procurar os diários correspondentes, até o limite do estudo. Novembro/2026 deve ser coberto por arquivo diário/API se o mensal ainda não tiver sido publicado. **Fonte:** arquivos mensais/diários e calendário de publicação no [repositório oficial][D01]; **decisão:** enumeração por calendário, sem depender de um catálogo completo de deslistados.

Exemplos de caminhos de extração:

```text
https://data.binance.vision/data/spot/monthly/klines/BTCUSDT/1h/BTCUSDT-1h-2024-12.zip
https://data.binance.vision/data/spot/daily/klines/BTCUSDT/1h/BTCUSDT-1h-2026-11-01.zip
```

Um `404` prova apenas que aquele objeto não foi localizado naquela consulta; não prova que o ativo jamais foi negociado. Diferenciar `disponivel`, `nao_localizado`, `erro_transitorio`, `acesso_negado`, `checksum_divergente` e `esquema_inesperado`. Não converter indisponibilidade técnica em observação de volume zero. **Decisão de auditoria**, apoiada na distinção entre falhas HTTP documentada em [httr2][P02R].

### 8.2. Download, cache e versões

Baixar sequencialmente no piloto; depois usar concorrência limitada somente se necessário. Aplicar timeout e espera com limite de tentativas a erros transitórios; respeitar `Retry-After`. Para cada ZIP, baixar `.CHECKSUM`, comparar SHA-256 e só então liberar a transformação. Escrever inicialmente em `.part`; manter falhas identificadas e evitar substituir uma versão antiga sem registro. **Fontes:** [integridade Binance][D01]; [httr2][P02R]; [digest][P03].

Guardar no manifesto `source_url`, `symbol`, período, frequência, data de consulta UTC, estado HTTP, hash esperado/calculado, bytes, versão do parser, primeira/última abertura e quantidade de linhas. Se o arquivo mudar, preservar as duas versões e registrar qual alimentou a amostra final. **Decisão de engenharia**, baseada na possibilidade de revisões da [fonte][D01].

### 8.3. Complementação por API

Usar `GET https://data-api.binance.vision/api/v3/klines` com `symbol`, `interval=1h`, `startTime`, `endTime` e `limit=1000` para pequenas lacunas ou período recente. Omitir `timeZone` para manter UTC. As chamadas devem ser paginadas pelo **último open time convertido + 1 hora**; um cursor que não avança interrompe a execução. A documentação informa limite máximo de 1000 candles e identificação por abertura. **Fonte:** [klines][D05]; acesso público em [Market Data Only][D04].

Não aplicar cegamente a regra de microssegundos dos arquivos à resposta da API: registrar a unidade efetivamente solicitada/retornada e conferir a documentação do endpoint. Conciliar API e arquivo por chave e hash de conteúdo; não duplicar a mesma hora. Guardar JSON bruto quando a API for usada. Em conflito, preservar as versões e investigar; não escolher a que melhora o modelo. **Decisão do projeto; fontes:** [API][D05] e [arquivos][D01].

**Entrega:** ZIPs/JSONs versionados, manifesto integral e `catalogo_cobertura.csv` por par. **Critério:** cobertura e ausência descritas por período, candidatos ausentes explicitados e fronteira final suficiente para os alvos de 24 horas. Sem esse critério, não avançar para conclusões sobre a amostra completa.

## 9. Etapa 3 — normalizar e auditar o painel

### 9.1. Timestamps e tempo de referência

Nos arquivos spot, converter timestamps anteriores a 01/01/2025 dividindo por `1000` e, a partir dessa data, por `1e6`, preservando as strings originais. Validar ano, mês do arquivo, frequência e relação entre abertura e fechamento após converter. A magnitude é uma conferência adicional, não substituto da origem documentada. **Fonte da mudança de unidade:** [Binance Public Data][D01]; implementação de leitura em [data.table][P05].

Definir `candle_end = open_time + 3600 segundos`. O candle com abertura às 10h representa o intervalo que termina às 11h. Usar essa fronteira como índice analítico, evitando misturar o horário de abertura com informação de fechamento que ainda não existia. Definir `feature_available_at = candle_end + 60 segundos` e `forecast_at = t + 60 segundos`. O atraso de 60 segundos é **hipótese operacional**, não garantia publicada de latência da Binance. **Decisão do projeto; esquema temporal em [klines][D05].**

O alvo terá 24 horas **entre fechamentos**, `P_t` e `P_(t+24h)`, com emissão idealizada após o fechamento inicial. Portanto, a avaliação não equivale ao retorno de uma ordem executada exatamente na emissão nem a um backtest de negociação com custos. Como sensibilidade, atrasar os atributos em uma hora mantendo o mesmo alvo. Arquivos históricos são usados para reconstrução; sua publicação mensal posterior não é confundida com disponibilidade do candle pela API no momento da previsão. **Decisão de mensuração e reconstrução histórica; fontes de acesso [D01] e [D05].**

### 9.2. Controles de qualidade

| Controle | Regra de auditoria / tratamento | Origem |
| --- | --- | --- |
| Chave | Unicidade por mercado, símbolo, intervalo e abertura | Identificação por open time em [klines][D05] |
| OHLC | Preços positivos, `low <= open,close <= high` | Consistência do esquema [D05]; regra do projeto |
| Volumes | Não negativos; volumes compradores não excedem os totais, admitida tolerância numérica documentada | Campos em [D05]; regra do projeto |
| Contagem | Inteira e não negativa | Esquema [D05] |
| Calendário | Grade UTC de 1h; ausência preservada como `NA`, com motivo | Decisão do projeto |
| Duplicidade | Deduplicar apenas cópias idênticas; conflitos exigem investigação | Decisão do projeto |
| Extremos | Conferir na origem; não eliminar quedas reais por serem extremas | Decisão do projeto; o extremo é o desfecho de interesse |
| Migrações | Não concatenar tickers ou aplicar conversões sem documentação específica | Decisão do projeto e fonte primária de cada evento |
| Zeros | Separar candle registrado com zero de atividade de arquivo/linha ausente | Decisão do projeto |
| Futuro | Transformações usadas como atributos são calculadas apenas com histórico permitido | [Validação prospectiva][R19] |

Manter tabelas `candles`, `instrument_history`, `data_quality`, `eligibility_history` e `source_manifest`. Particionar candles por símbolo e ano em Parquet; evitar um arquivo por linha/hora. Consultar com DuckDB/DBI e trazer para R somente as janelas necessárias. **Decisão de arquitetura; capacidades em [Arrow][P08], [DuckDB][P10] e [DBI][P09].**

**Entrega:** painel horário auditado e relatório de cobertura. **Critério:** nenhum conflito de chave sem resolução, timestamps plausíveis, ausências distinguíveis de zeros e rastreabilidade de cada partição ao bruto.

## 10. Etapa 4 — construir os alvos e atributos

### 10.1. Alvo e elegibilidade

Definir:

\[
R^{24}_{i,t}=P_{i,t+24h}/P_{i,t}-1,
\qquad Y_{i,t}=\mathbb{1}\{R^{24}_{i,t}<-0{,}05\}.
\]

O limiar de 5% é **decisão do projeto**, mantida para continuidade com o plano original. Não é uma definição universal de contágio. Avaliar 3% e 10% como robustez previamente indicada. Se for usado log-retorno para conferir o alvo, empregar `log(0.95)` como limiar equivalente. A literatura motiva a cautela com o significado de contágio [Forbes e Rigobon][R08]; não fornece esse corte particular.

Obter o preço futuro por junção exata `asset_id + candle_end = t+24h`. Não usar simplesmente a 24ª linha posterior em uma série com lacunas. Se qualquer preço necessário não estiver disponível, manter `Y = NA` e registrar o motivo. Para retornos passados, também exigir os horários exatos ou reconstruir a grade completa antes de defasar. **Decisão de engenharia temporal**, implementável com [junções em data.table][P05].

A elegibilidade de uma previsão será definida só com dados conhecidos em `t`: identidade/par válido, histórico mínimo, participação no snapshot elegível, atributos obrigatórios observáveis e volume positivo na janela de liquidez. A disponibilidade do preço em `t+24h` não poderá determinar se a previsão é produzida. Na avaliação, apresentar separadamente previsões com e sem alvo observado. Isso evita ocultar censura após suspensão ou deslistagem. **Decisão do projeto; princípio temporal em [R19].**

### 10.2. Atributos individuais — bloco M1

Usar retornos simples em 1h, 24h e 168h, calculados entre preços nos horários correspondentes. Para volatilidade, usar desvio-padrão dos log-retornos horários nas últimas 24h e 168h, multiplicado por `sqrt(24)` apenas como convenção de escala; não afirmar que isso garante uma previsão da variância futura. Exigir cobertura integral nessas janelas curtas para o atributo principal. **Decisões do projeto.**

| Atributo | Construção | Informação disponível |
| --- | --- | --- |
| `ret_1h`, `ret_24h`, `ret_168h` | `P_t/P_(t-h) - 1` | Até o fechamento `t` |
| `vol_24h`, `vol_168h` | `sd(log_returns)` da janela × `sqrt(24)` | Até `t`; sem janela centrada |
| `log_quote_volume_24h` | `log1p(soma(volume em USDT))` | Últimas 24h completas |
| `illiq_168h` | Média de `abs(ret_1h)/quote_volume` nas horas de volume positivo | Cobertura válida registrada; volume zero não entra como divisão por zero |
| `observed_age_days` | Dias desde a primeira observação disponível | Proxy de histórico observado, não idade econômica comprovada |

A razão de iliquidez se inspira em [Amihud, 2002][R20]. A aplicação aqui será uma **adaptação horária em USDT**, não uma replicação da medida original diária em dólares. Exigir pelo menos 95% das 168 horas com volume positivo para esse atributo; guardar a contagem válida e avaliar sensibilidade. Transformação de escala será ajustada só no treino. **Decisão do projeto; fonte conceitual [R20].**

### 10.3. Controles comuns — bloco adicional M2

Construir uma medida de mercado da amostra como média igualmente ponderada dos retornos horários dos demais ativos elegíveis, excluindo o próprio ativo e BTC. Exigir pelo menos três contribuintes com dados válidos e registrar quais participaram. A composição será determinada com o snapshot conhecido do dia, sem exigir sobrevivência futura. Essa é uma **proxy restrita à amostra**, não um índice completo do mercado nem o fator de mercado de Liu et al. **Fundamento para controlar fatores comuns:** [Liu, Tsyvinski e Wu][R12]; **construção específica:** decisão do projeto.

Adicionar retornos passados de BTC em 1h/24h e da proxy de mercado em 24h. Calcular betas univariados históricos ao BTC e à proxy, em janela de 90 dias com pares de horários coincidentes e cobertura >=95%, usando `cov/var` e verificando variância positiva. Eles são controles estatísticos, não parâmetros causais. Para o estresse, definir `s_BTC,t = max(0, -ret_BTC,24h)`. **Decisões do projeto; motivação de fatores em [R12].**

Incluir ainda número de nós elegíveis no snapshot como controle de composição. Não usar nível nominal do preço como principal medida de risco, nem capitalização atual aplicada retrospectivamente. O proxy de idade e os contadores de cobertura devem ser descritos como informação observada. **Decisões de controle e mensuração.**

**Entrega da etapa:** `features_individual_market.parquet` e `targets.parquet`, separados, com `max_source_time`, `feature_available_at`, `label_end`, `label_available_at` e versão do cálculo. **Critério:** junções temporais corretas e nenhuma variável futura na tabela de atributos. **Princípio:** [R19].

## 11. Etapa 5 — construir a rede dinâmica e as exposições

### 11.1. Amostra de cada snapshot

Às 00h UTC de cada dia `d`, construir uma matriz usando apenas retornos horários com término em `(d-90 dias, d]`, observáveis em `d+60 segundos`. A matriz passa a valer nessa emissão e nas origens posteriores até o próximo snapshot. Para cada par de nós, exigir pelo menos 95% dos 2160 horários em comum; para cada nó, 98% de cobertura e variância positiva. Exigir BTC e pelo menos cinco nós. **Decisões do projeto; fundamentos de representação em Newman, caps. 6–7, no [livro local](../referencias/livro_newman_networks_2ed.txt).**

Se os requisitos não forem satisfeitos, registrar snapshot inválido e não inventar centralidades. No estudo principal incremental, comparar M2 e M3 na mesma amostra com rede válida; em tabela separada, mostrar a cobertura mais ampla de M2. Se um alvo perder elegibilidade intradia por atributos ausentes, registrar a exclusão no momento da previsão. **Decisão do projeto.**

### 11.2. Matriz de intensidade, escala e orientação

Estimar correlações de Pearson dos log-retornos horários nos horários coincidentes. Definir a intensidade:

\[
B_{ij,d}=\begin{cases}
\widehat\rho_{ij,d},&i\ne j\ \text{e}\ \widehat\rho_{ij,d}\ge0{,}30,\\
0,&\text{caso contrário}.
\end{cases}
\]

`B` será simétrica, não negativa e sem diagonal. A regra escolhe dependência positiva e não preserva o papel de associações negativas; estas serão tratadas em análise de sensibilidade separada. A correlação é uma medida de similaridade, não observação de obrigação financeira. **Construção:** decisão do projeto; distinção entre representações em [Bardoscia et al.][R05].

Usar uma única escala global em cada snapshot:

\[
a_d=\max\{1,\max_i\sum_jB_{ij,d}\},\qquad A_d=B_d/a_d.
\]

Assim `||A_d||_infinito <= 1` e `ρ(A_d) <= 1`. Com `κ=0,50`, o multiplicador `Q_d=(I-κA_d)^{-1}` fica na região convergente. Guardar `B`, `A`, `a_d`, espectro e ordenação dos nós. A escala varia entre snapshots e altera a interpretação temporal da intensidade; registrar `a_d` e examinar sensibilidade, sem chamar `κ` de transmissão estimada. **Escala e κ:** decisões do projeto; **fundamento do multiplicador:** [Ballester et al.][R01] e [Acemoglu et al.][R02].

A convenção de multiplicação será `(Ax)_i = soma_j A_ij x_j`: a coluna `j` é a origem da entrada e a linha `i` é o receptor. Como a matriz principal é simétrica, não há direção empírica de transmissão. A convenção passa a ser essencial em uma extensão dirigida. **Decisão de notação; representação de grafos em [igraph][P11].**

### 11.3. Atributos da rede — M3 e M4

| Variável | Definição | Interpretação e limite |
| --- | --- | --- |
| `strength_mean` | `soma_j B_ij/(n_d-1)` | Intensidade média de dependência positiva |
| `katz_excess` | `(Q_d 1)_i - 1` | Centralidade de passeios atenuados além da entrada própria |
| `btc_exposure` | `[(Q_d-I)e_BTC]_i` | Exposição estatística específica à origem BTC sob o multiplicador |
| `btc_exposure_stress` | `btc_exposure × s_BTC,t` | Interação usada apenas em M4 |

As definições de Katz e exposição são **adaptações operacionais** do multiplicador [Ballester et al.][R01]. A centralidade global utiliza entradas em todos os nós; a exposição ao BTC utiliza a coluna correspondente ao BTC. São objetos diferentes. Nenhum deles é uma estimativa causal de confiança.

Não normalizar cada linha para somar um antes de calcular `Q1`: isso tornaria essa definição de Katz constante, pois `(I-κA)^{-1}1 = 1/(1-κ)1` quando `A1=1`. A escala global escolhida evita impor essa igualdade. Ainda assim, uma rede regular pode produzir Katz igual entre nós; igualdade real não deve ser corrigida artificialmente. **Demonstração algébrica do projeto, com base na definição em [R01] e Newman 7.1.3.**

Como extensão exploratória previamente identificada, construir o estresse dos vizinhos excluindo BTC, usando pesos `B` normalizados apenas para essa média. Se não houver peso remanescente, definir a média como zero e guardar um indicador de isolamento para diagnóstico. Não misturar essa normalização com a de Katz. Intermediação também será exploratória: usar comprimento `1/B_ij` nas arestas retidas, com pesos positivos e zeros ausentes. **Decisões do projeto; interpretação de pesos como distâncias em [igraph::betweenness][P12].**

### 11.4. Verificações e entrega

Antes de salvar cada snapshot, conferir simetria, diagonal zero, `ρ(κA)<1`, solução numérica, nomes/ordem dos nós e existência de BTC. Uma matriz sem arestas deve gerar `Q=I`, Katz excedente zero e exposição zero; isso é uma consequência válida. Conferir também que o nó do BTC foi removido dos **alvos**, não da **rede**. **Origem:** consequências das definições desta seção.

**Entrega:** `network_snapshots.rds` ou partições equivalentes, `network_edges.parquet`, `network_features.parquet` e relatório de estabilidade/variabilidade. **Critério:** atributos reproduzíveis a partir do snapshot e da mesma ordem de nós, com dados anteriores à emissão. Na implementação, usar `solve(I-κA, rhs)` para obter os vetores necessários, sem inverter matrizes de covariância. **Decisão computacional.**

## 12. Etapa 6 — construir o calendário de treino, calibração e teste

### 12.1. Regra fundamental de disponibilidade

Para uma origem canônica `t`, definir `label_end = t+24h` e `label_available_at = label_end+60 segundos`. Um ajuste feito em `T+60 segundos` só pode usar observações com `label_available_at <= T+60 segundos`, alvo efetivamente conhecido e atributos disponíveis na respectiva emissão histórica. Essa regra vale para todos os ativos e também para calibração. **Decisão operacional; fundamento de avaliação do futuro com o passado em [Bürkner et al.][R19].**

Exemplo: o alvo originado às 12h de segunda termina às 12h de terça. Ele não pode treinar o modelo às 00h de terça. Não basta ordenar a tabela; a divisão deve operar sobre **origens temporais únicas comuns a todos os ativos**, nunca sobre a posição das linhas de um painel ordenado por moeda. **Dedução da definição do alvo; princípio em [R19].**

Janelas históricas compartilhadas entre treino e teste são admissíveis quando só usam informação conhecida. Não é necessário excluir automaticamente os 90 dias da janela de correlação. É necessário excluir os rótulos ainda não observáveis e qualquer transformação que tenha usado futuro. **Distinção operacional do projeto; referência temporal [R19].**

### 12.2. Fases de desenvolvimento

| Fase | Origens de avaliação | Uso permitido | Saída |
| --- | --- | --- | --- |
| Inicialização | 2020–2021 | Formar histórico de treino; gerar previsões temporais de desenvolvimento quando houver amostra suficiente | Arquivo inicial de previsões fora da amostra para calibração |
| Desenvolvimento | 2022 até junho/2024 | Escolher penalização em blocos semestrais, com ajustes mensais internos | Hiperparâmetros por modelo/bloco e algoritmo |
| Validação operacional | Julho–dezembro/2024 | Verificar execução, calibração, cobertura e viabilidade; corrigir e documentar antes do teste | Protocolo congelado e log de revisões |
| Teste final | Janeiro/2025 até outubro/2026 | Executar a regra mensal predefinida; produzir avaliação final | Previsões e métricas finais |

As datas e a divisão semestral são **decisões deste projeto**, não prescrições da literatura. Gerar previsões históricas iniciais antes do primeiro bloco de calibração; se faltar informação, usar a regra explícita de calibração identidade. Sempre respeitar a disponibilidade dos alvos, inclusive na fronteira de julho/2024 e janeiro/2025. **Princípio:** [R19].

### 12.3. Rotina de atualização mensal

No primeiro horário UTC de cada mês, em `T+60 segundos`:

1. Selecionar origens dos 730 dias anteriores, estritamente anteriores a `T`, com rótulo já maturado e observado. Não selecionar com informação de sobrevivência futura.
2. Estimar transformações e filtros somente nesse treino. Ajustar o modelo com penalização já escolhida no desenvolvimento.
3. Recuperar as **previsões brutas fora da amostra** armazenadas para os 90 dias anteriores, com rótulo maturado até `T`. Elas devem ter sido geradas por modelos que, em cada origem histórica, só conheciam seu passado.
4. Ajustar o calibrador sobre esse arquivo histórico; congelar modelo, transformações e calibrador até o próximo ajuste mensal.
5. Emitir previsões horárias do mês. Atualizar apenas os atributos e a rede na periodicidade definida, sem usar alvos ainda desconhecidos.
6. Guardar previsão bruta e calibrada, identificador do ajuste, maior horário de rótulo usado e snapshot de rede.

Essa é uma **decisão de avaliação sequencial** apoiada no princípio leave-future-out [R19]. Não usar `cv.glmnet()` com divisões aleatórias, nem confiar que um `foldid` cronológico garanta treino somente no passado: a validação cruzada usual ainda pode treinar com blocos posteriores. Implementar a seleção da penalização por chamadas diretas de `glmnet()` em janelas explicitamente anteriores. **Fonte técnica:** [glmnet][P13].

### 12.4. Significado de teste final com atualização

Durante o teste sequencial, rótulos de meses anteriores do próprio período de teste podem entrar em ajustes posteriores **depois de conhecidos**, como aconteceria no uso operacional. O que fica congelado é o protocolo: variáveis, grades, critérios e regra de atualização. Não se pode olhar o desempenho de 2025 e escolher uma regra melhor para apresentar 2025 como teste intocado. Se houver intervenção humana após abrir essas métricas, registrar nova versão e tratar os resultados seguintes conforme seu novo status. **Decisão do projeto; orientação de validação prospectiva em [R19].**

Como sensibilidade, estimar também um teste com parâmetros fixos antes de janeiro/2025 e sem realimentação dos rótulos de teste. Ele responde a uma pergunta diferente, sobre envelhecimento do modelo, e não substitui a rotina mensal principal. **Decisão do projeto.**

**Entrega:** tabela `splits.parquet` com origens, datas de ajuste, início/fim do treino e rótulos disponíveis. **Critério:** nenhuma previsão depende de rótulo cujo `available_at` ultrapasse o ajuste correspondente. Guardar essa auditoria por modelo. **Fundamento:** [R19].

## 13. Etapa 7 — ajustar os modelos de referência e de rede

### 13.1. Blocos de informação

| Modelo | Atributos | Finalidade |
| --- | --- | --- |
| M0 | Frequência de perdas do treino, suavizada por `(N1+1)/(N+2)` | Referência mínima; extensão por ativo usa retorno à frequência global quando não houver histórico |
| M1 | Retornos, volatilidades, volume, iliquidez e histórico observado da seção 10.2 | Risco individual |
| M2 | M1 + BTC, mercado da amostra, betas, estresse BTC e número de nós | Referência com fatores e composição |
| M3 | M2 + `strength_mean`, `katz_excess`, `btc_exposure` | Teste principal da informação de rede |
| M4 | M3 + `btc_exposure_stress` | Teste adicional da exposição específica sob estresse |

A suavização de M0 e a organização M0–M4 são **decisões deste estudo**. A necessidade de referências competitivas é motivada pela evidência de fatores comuns em [Liu et al.][R12]. A exposição de M3 deriva do multiplicador de rede [R01]. Não interpretar a combinação exata como um modelo publicado por esses autores.

Estimar M1–M4 com dois algoritmos: Gaussian Naive Bayes e regressão logística ridge. A comparação primária será ridge M3 contra ridge M2; a mesma diferença em Naive Bayes será complementar. Atribuir o ganho ao **bloco acrescentado**, com algoritmo, datas e observações fixos. Efeitos fixos por moeda serão uma comparação adicional da logística, sem apresentá-la como comparação isolada de algoritmo com Naive Bayes. **Decisão do projeto; implementações em [naivebayes][P14] e [glmnet][P13].**

### 13.2. Transformações sem vazamento

No treino de cada ajuste: selecionar as colunas previstas, calcular escala dos atributos contínuos e remover constantes ou colunas com desvio-padrão por classe inferior a `1e-8` após padronização. Aplicar o mesmo conjunto de colunas aos dois algoritmos em cada bloco. Esse limiar é uma **regra de estabilidade do projeto** para evitar variâncias gaussianas degeneradas; não foi retirado do pacote ou de um resultado econômico. Registrar cada exclusão.

Os atributos obrigatórios deverão estar presentes na amostra principal, sem imputar preço ou alvo. Caso se adote imputação de um atributo adicional em uma extensão, seus parâmetros devem vir somente do treino e a cobertura deve ser apresentada. Não permitir que cada algoritmo remova NAs de modo diferente e, depois, comparar métricas como se a amostra fosse igual. A implementação de GaussianNB documenta tratamento próprio de NAs, que precisa ser controlado pelo protocolo [documentação][P14].

Manter `Y` numérico 0/1 para logística e `factor(Y, levels=c("0","1"))` para Naive Bayes e métricas. A probabilidade de interesse é sempre a coluna `"1"`. Não alterar a frequência de classe por SMOTE, subamostragem ou pesos no núcleo probabilístico. Se faltar uma das classes ou houver menos de 50 observações de alguma classe no treino, usar M0 e registrar o fallback. Os números são **decisões de estabilidade**, não uma garantia de tamanho amostral efetivo.

### 13.3. Gaussian Naive Bayes

Usar `naivebayes::gaussian_naive_bayes(x, y)`, atributos numéricos e frequências de classe do treino; obter `predict(..., type="prob")[,"1"]`. As distribuições por classe são gaussianas e condicionalmente independentes na especificação. A hipótese pode ser uma aproximação fraca para atributos correlacionados de redes, devendo ser avaliada por previsão e calibração [documentação do pacote][P14]; [Niculescu-Mizil e Caruana][R16].

Essa probabilidade classificatória não constitui uma posterior de parâmetros de transmissão, nem um modelo de atualização das crenças dos investidores. O nome “prior” das frequências de classe no classificador tem papel diferente dos priors sobre coeficientes na etapa bayesiana. **Distinção metodológica:** [Acemoglu et al., 2011][R07] e [Gelman et al.][R17].

### 13.4. Regressão logística ridge

Usar `glmnet::glmnet(x, y, family="binomial", alpha=0, lambda=grade, standardize=FALSE)`, pois a padronização já terá sido feita no treino. Escolher `lambda` em `{0.0001, 0.001, 0.01, 0.1, 1}` usando o desempenho temporal médio no desenvolvimento, com a mesma rotina de calibração da execução final. Em empate numérico dentro de `1e-6` de Brier, preferir maior penalização. **Grade e desempate:** decisões do projeto; **estimador:** [glmnet][P13].

Selecionar a penalização separadamente por bloco M1–M4 usando a mesma grade e orçamento. Não exigir a mesma penalização entre modelos de dimensões distintas. Se o desenvolvimento mostrar que a grade não cobre uma região estável, ampliar e registrar antes da validação final, sem consultar 2025–2026. **Decisão do projeto.**

**Entrega:** objetos ajustados, hiperparâmetros, transformações, exclusões e `predictions_raw.parquet`. **Critério:** probabilidades finitas, classe positiva conferida e mesma amostra por comparação. A demonstração no TXT original não é um resultado estimado; tabelas de probabilidades finais só serão preenchidas após executar esta etapa.

## 14. Etapa 8 — calibrar as probabilidades

A calibração sigmoide será ajustada como `logit(P(Y=1)) = a + b logit(p_bruta)` sobre previsões temporais fora da amostra dos 90 dias anteriores ao ajuste. Usar clipping numérico de `p_bruta` para `[1e-12, 1-1e-12]` antes do logit. Ajustar por `stats::glm(..., family=binomial())`. Calibrar cada modelo/algoritmo separadamente. **Decisão de implementação; fundamentação de calibração em [Niculescu-Mizil e Caruana][R16].**

Exigir pelo menos 50 exemplos de cada classe e 30 datas distintas nessa janela. Caso não haja suporte, ou o ajuste não convergir, tenha coeficientes não finitos ou separação detectada por probabilidades extremas/avisos, usar identidade (`p_calibrada=p_bruta`) e registrar o motivo. Não corrigir manualmente o calibrador olhando o teste. Isotônica fica como extensão, exigindo amostra e avaliação próprias. **Critérios numéricos:** decisões do projeto; **motivação:** [R16].

O calibrador usa resultados de modelos históricos anteriores, não previsões ajustadas sobre seus próprios rótulos. Na data corrente, o modelo-base poderá ser reajustado com rótulos antigos já conhecidos. A transferência da calibração entre esses ajustes é parte da hipótese operacional e será examinada por mês; não é uma garantia de calibração perfeita. Guardar resultados brutos e calibrados, usando **calibrados** na comparação primária. **Decisão do projeto; avaliação das probabilidades em [Gneiting e Raftery][R15].**

**Entrega:** calibradores, amostras de calibração e `predictions.parquet`. **Critério:** todo rótulo de calibração já era conhecido no ajuste, e cada probabilidade histórica usada no calibrador foi gerada fora da amostra temporal correspondente.

## 15. Etapa 9 — avaliar ganho preditivo

### 15.1. Métricas e estimando principal

\[
BS_m=\frac{1}{N}\sum_{i,t}(Y_{i,t}-\widehat p_{m,i,t})^2,
\qquad \Delta BS=BS_{M3}-BS_{M2}.
\]

`ΔBS < 0` favorece o bloco de rede. O estimando principal é a média por **observação ativo–hora elegível com alvo observado**, na mesma amostra dos modelos comparados. Apresentar também média por ativo e por horário, pois históricos e quantidades de ativos variam. O Brier é uma regra própria de avaliação probabilística, mas seu valor isolado não certifica calibração [Gneiting e Raftery][R15]. As ponderações desta proposta são decisões do projeto.

| Métrica / gráfico | Regra de cálculo | Interpretação | Fonte |
| --- | --- | --- | --- |
| Brier Score | Fórmula acima; menor melhor | Qualidade probabilística global | [R15] |
| Log loss | Média de `-Y log(p) -(1-Y) log(1-p)` | Penaliza erros probabilísticos confiantes; usar clipping apenas numérico | [R15] |
| ROC-AUC | Classe positiva `"1"`, `event_level="second"` | Ordenação entre classes; não calibração | Implementação [yardstick][P26] |
| Average precision | Reportar com esse nome e prevalência | Resumo da curva precisão–revocação por média ponderada | [Documentação][P16] |
| PR-AUC trapezoidal | Complementar, identificada separadamente | Não intercambiável numericamente com average precision | [Documentação][P15] |
| Calibração | Frequência observada por grupos de probabilidade e mês | Compatibilidade entre probabilidades e eventos | [R16] |
| F1 e matriz de confusão | Apenas se houver limiar escolhido no desenvolvimento | Decisão binária; não avaliação principal de probabilidade | Decisão do projeto |

Quando um grupo só tiver uma classe, manter as métricas indefinidas como `NA` com motivo; não substituir por zero. Informar prevalência, número de horas e número de datas distintas com perdas. Classificações horárias de 24 horas não são eventos de crise independentes. **Decisão do projeto; dependência temporal considerada em [R19].**

### 15.2. Cobertura e alvos ausentes

Apresentar todas as previsões emitidas, a fração de alvos observados e os motivos de ausência por ativo/ano. Métricas com alvos observados respondem a uma pergunta condicionada à cobertura, que pode ser informativa após suspensão/deslistagem. Como sensibilidade para a diferença de Brier, calcular seus extremos possíveis em cada rótulo ausente usando `Y=0` e `Y=1`, mantendo fixos as previsões e o denominador das previsões emitidas. Isso fornece limites descritivos da diferença, não recuperação do preço ausente. **Decisão de auditoria e análise algébrica do projeto.**

**Entrega:** tabelas por modelo, algoritmo, período e ativo; diferença principal e curvas de calibração. **Critério:** nenhuma comparação mistura conjuntos de observações ou confunde métricas brutas e calibradas.

## 16. Etapa 10 — quantificar incerteza da comparação

O alvo de 24 horas gera perdas sobrepostas quando as previsões são horárias. Para a comparação principal, calcular as diferenças individuais de Brier e agregá-las por **dia UTC da origem**, guardando numerador `S_d=soma(delta_loss)` e denominador `N_d=numero de observacoes`. A estimativa será `soma(S_d)/soma(N_d)`, preservando a ponderação principal por observação. Não trocar silenciosamente por média das médias diárias quando `N_d` variar. **Dedução do estimando definido na seção 15.**

Aplicar bootstrap estacionário aos pares diários `(S_d,N_d)` com `boot::tsboot(..., sim="geom", l=7, R=2000)`, recalculando a razão em cada amostra. Reamostrar dias completos preserva o conjunto transversal e a comparação pareada. Usar intervalos percentis de 95% e repetir com comprimentos médios 3, 14 e 30 dias. Os números são **decisões do projeto**; o método de blocos é fundamentado em [Politis e Romano, 1994][R21] e implementado no [pacote boot][P17].

Construir o calendário diário completo. Dias sem observações terão `S_d=0,N_d=0` no registro, sem inventar erros; uma reamostra com denominador zero será inválida e contabilizada. Não comprimir silenciosamente lacunas de vários dias como se os vizinhos fossem consecutivos. Analisar resultados por ano/regime e estabilidade das diferenças, porque pressupostos de dependência fraca e estacionariedade não são garantidos em toda a série cripto. Bootstrap não converte uma crise única em milhares de choques independentes. **Decisões de aplicação; condições metodológicas em [R21].**

A comparação principal será uma só: ridge M3−M2 no limiar de 5%. Demais algoritmos, cortes e janelas serão secundários ou exploratórios, identificados como tal. Não procurar a combinação com menor p-valor para apresentá-la como hipótese inicial. Intervalos do bootstrap condicionam-se à sequência de previsões produzida; não representam toda a incerteza de seleção do projeto. **Decisão de transparência do estudo.**

**Entrega:** intervalo da diferença principal, gráfico temporal e tabela de sensibilidade aos blocos. **Critério:** reamostragem pareada, ponderação preservada e pressupostos/limites descritos.

## 17. Etapa 11 — inferência bayesiana em painel diário

Esta etapa faz parte do plano de análise, após validar o núcleo preditivo. Será executada em origens diárias às 00h UTC, com alvos de 24 horas entre fechamentos. A redução evita a sobreposição intradia dos rótulos; não elimina dependência temporal ou entre ativos. Comparar versões sem/com rede na **mesma amostra diária**, inclusive com as referências clássicas reavaliadas nesses horários. **Decisão de escala computacional; validação temporal em [R19].**

### 17.1. Preparação e ajuste preliminar

Instalar `brms`, `posterior`, `bayesplot` e `loo`; instalar `cmdstanr` conforme o repositório oficial e verificar a ferramenta C++ antes de instalar CmdStan. No Windows, seguir o compilador/Rtools compatível indicado pela documentação, sem presumir que instalar o pacote R instala também o compilador e CmdStan. Registrar a versão do executável separadamente de `renv.lock`. **Fonte:** [CmdStanR][P21].

```r
source("config/projeto.R", encoding = "UTF-8")
renv::install(cfg$packages_bayesian)
install.packages(
  "cmdstanr",
  repos = c("https://stan-dev.r-universe.dev", getOption("repos"))
)
cmdstanr::check_cmdstan_toolchain()
cmdstanr::install_cmdstan(cores = 2)
renv::snapshot(prompt = FALSE)
```

Antes do modelo temporal completo, validar escala, priors e interceptos por ativo com uma regressão `brms::brm(..., family=bernoulli(), backend="cmdstanr")`. Esse ajuste preliminar verifica a execução; suas hipóteses não substituem o componente temporal da especificação principal. Não acrescentar ingenuamente `ar(p=1)` em Bernoulli presumindo o mesmo suporte da regressão gaussiana: a documentação descreve restrições de família e formulação [brms::ar][P25]. **Decisão de implementação; modelo preliminar em [brms][P20].**

### 17.2. Especificação principal

Definir, para ativo `i` e origem diária `d`:

\[
Y_{i,d}\mid p_{i,d}\sim Bernoulli(p_{i,d}),
\]

\[
logit(p_{i,d})=a_i+\gamma'X_{i,d}+\xi'Z_{i,d}+v_d,
\]

\[
a_i=\mu_a+\sigma_a u_i,\quad u_i\sim N(0,1),
\qquad v_d=\phi v_{d-1}+\sigma_v\epsilon_d,\quad \epsilon_d\sim N(0,1).
\]

`X` contém M2; `Z` contém os atributos acrescentados em M3. No modelo B2, omitir `Z`; em B3, incluí-lo. B4 acrescenta a interação de M4, como comparação secundária. `v_d` é um estado comum diário que representa dependência temporal remanescente; não é uma medida observada de confiança. Inicializar `v_1 ~ N(0, σ_v/sqrt(1-φ²))`, com `|φ|<1`. **Especificação e interpretação:** proposta deste projeto, informada por regressão hierárquica [R17] e fluxo de avaliação bayesiana [R18].

Implementar o estado comum explicitamente em Stan via `cmdstanr`. Usar parametrização não centrada para interceptos/estados quando apropriado e conferir identificabilidade numérica entre intercepto global, médias dos atributos e estado temporal. Preservar uma grade de dias de calendário completa; dias sem alvos entram na evolução do estado, sem uma verossimilhança observacional inventada. **Decisões de implementação; interface em [CmdStanR][P21].**

### 17.3. Priors propostos e checagens

Após padronizar atributos pelo treino, adotar inicialmente:

| Parâmetro | Prior proposto | Sentido |
| --- | --- | --- |
| `μ_a` | `Normal(-3, 1.5)` | Regularização da frequência básica; `-3` é hipótese inicial, não frequência estimada |
| `σ_a` | `HalfNormal(1)` | Dispersão dos interceptos por ativo |
| `γ`, `ξ` | `Normal(0, 0.5)` | Regularização de efeitos em escala padronizada |
| `σ_v` | `HalfNormal(0.3)` | Variação diária comum inicialmente moderada |
| `φ` | `Normal(0, 0.5)` truncada em `(-0.95, 0.95)` | Persistência limitada para estabilidade inicial |

Esses priors são **decisões deste projeto**, não os priors específicos publicados em Gelman et al. O artigo fundamenta a importância da escala e da regularização [R17]. Simular dados a priori para verificar frequência de perdas e variabilidade plausíveis; ampliar/revisar priors antes do teste se necessário, registrando o motivo. Repetir com escalas `0.25` e `1` para coeficientes como sensibilidade. Usar checagens preditivas antes e depois do ajuste [Gabry et al.][R18].

### 17.4. Treino e previsão temporal da posterior

Adotar ajustes trimestrais no início de janeiro/abril/julho/outubro, com janela de até 730 dias e alvos já conhecidos. As datas de desenvolvimento e teste são as mesmas do núcleo, mas as previsões são diárias. A menor frequência de reajuste é uma **escolha computacional**, a ser validada no desenvolvimento e congelada antes de 2025.

Para prever um dia futuro, propagar `v_d` a partir de cada amostra posterior do último estado conhecido, sorteando as inovações futuras. Durante o trimestre, condicionar apenas ao posterior do último ajuste e aos atributos observados na origem: não suavizar estados com os desfechos que se quer prever. Pode-se executar esse procedimento sequencialmente, gerando atributos em cada data com seu passado; a simulação não usa atributos futuros ainda não observados. Se houver um salto de `h` dias entre o último rótulo de treino e a origem, propagar os `h` passos correspondentes. **Decisão de previsão; princípio leave-future-out [R19] e [loo/LFO][P24].**

Médias posteriores de `p` serão as probabilidades avaliadas; intervalos de credibilidade resumirão incerteza do parâmetro probabilístico. Sorteios Bernoulli adicionais fornecem resultados preditivos binários. Para ativos que surgirem após o último ajuste, integrar um novo `u_i` da distribuição hierárquica, em vez de usar um intercepto estimado com dados futuros. Comparar B2 e B3 nas mesmas origens e ativos. **Decisões de integração preditiva; fundamentos de inferência em [Gelman et al.][R17] e [Gabry et al.][R18].**

### 17.5. Diagnóstico e limites

Usar inicialmente quatro cadeias, pelo menos 1000 iterações de aquecimento e 1000 retidas por cadeia, aumentando se necessário. Procurar `Rhat < 1.01`, ESS bulk/tail suficientes para os resumos — referência inicial 400 no total —, erro Monte Carlo pequeno e ausência de divergências não resolvidas. Esses números são critérios de diagnóstico do projeto, apoiados na discussão de [Vehtari et al., 2021][R22] e nos recursos de [posterior][P22]. Convergência computacional não comprova que o modelo descreve bem os dados.

Confrontar distribuições preditivas com frequência por ativo, sequências de perdas, concentração de eventos em dias e dependência residual. O estado comum AR(1) é uma aproximação, não uma garantia de capturar toda a dependência financeira. Não aplicar LOO aleatório para justificar previsão futura; preferir reestimações temporais explícitas ou LFO adequado [R19]; [P24].

As posteriores são condicionais à rede estimada tratada como conhecida. Reestimar a rede sob janelas alternativas avalia sensibilidade; não equivale a integrar toda a incerteza de `W`. Um coeficiente de rede diferente de zero continua sendo associação condicional sob o modelo, sem identificação causal de difusão [Manski][R09]; [Bramoullé et al.][R10].

**Entrega:** código Stan, draws, logs de convergência, checagens preditivas e comparação diária B2/B3. **Critério:** diagnóstico computacional aceitável, posterior preditiva avaliada no futuro e restrições inferenciais declaradas. Se o ajuste falhar, corrigir a especificação/parametrização e documentar; não substituir a etapa por resultados fictícios ou chamar Naive Bayes de posterior dos parâmetros.

## 18. Etapa 12 — robustez e análises secundárias

| Exercício previamente previsto | Alteração | Limite e fundamento |
| --- | --- | --- |
| Limiares | 3%, 5% e 10% de perda simples | Cortes são escolhas; não diferentes definições comprovadas de contágio [R08] |
| Janelas | 30, 90 e 180 dias de rede | Regra de elegibilidade recalculada com cada janela; apresentar amostra comum e cobertura |
| Filtro | Correlações >=0.20, 0.30 e 0.50 | Não escolher o corte pelo melhor resultado do teste |
| Atenuação | `κ=0.25, 0.50, 0.75` sob a mesma escala global | Representações alternativas do multiplicador [R01] |
| Dependência monotônica | Rede de correlação de Spearman | Outra construção estatística, sem direção causal |
| Resíduos de fatores | Reestimar correlações após controles estimados só no passado | Sensibilidade a fatores, motivada por [Liu et al.][R12] |
| Composição | Subamostra de ativos definidos por informação disponível no desenvolvimento, sem seleção por resultado de teste | Distinguir estabilidade de composição e população intencional |
| Frequência | Origens diárias às 00h | Menor sobreposição; comparar os mesmos modelos na mesma frequência |
| Latência | Atributos atrasados 1h | Reconstrução conservadora da disponibilidade |
| Calibração | Probabilidades brutas e calibradas | Comparação motivada por [R16] |
| Incerteza | Blocos médios de 3, 7, 14 e 30 dias | Sensibilidade ao método temporal [R21] |
| Censura | Limites da diferença de Brier para alvos ausentes | Não inferir preços não observados |
| Comparadores | MUSD/PAXG confirmados, em painéis separados | Não misturar interpretações de ativos com referências econômicas distintas |

Para a rede residual, ajustar para cada ativo-alvo uma regressão de retornos horários contra BTC e proxy de mercado excluindo o próprio ativo/BTC, usando apenas os 90 dias anteriores ao snapshot. Para BTC, usar a proxy dos demais ativos. Conferir posto/condicionamento; se a regressão não for identificável numericamente, marcar o snapshot residual inválido. Esses resíduos vêm de regressões distintas por nó; não alegar que a matriz representa uma rede causal ou uma decomposição comum exata. **Decisão de sensibilidade; motivação dos controles em [R12].**

Remover fatores pode retirar parte da variação que o mecanismo de interesse utiliza. Portanto, persistência de ganho na rede residual fortalece uma interpretação de informação adicional a esses controles; desaparecimento do ganho não prova ausência de conexões econômicas. Um VAR com decomposições de variância seria outra extensão, fundamentada em [Diebold e Yilmaz][R11], com custo e hipóteses próprios. Não é obrigatório para concluir o núcleo deste protocolo.

Testes em redes reconfiguradas podem ajudar a avaliar se o resultado depende de detalhes topológicos. Precisam preservar simetria, não negatividade e atributos escolhidos do modelo nulo, com código documentado. Não atribuir a uma permutação de rede observacional as garantias de um experimento aleatório. **Decisão exploratória; limites de identificação em [Manski][R09] e [Bramoullé et al.][R10].**

**Entrega:** tabela de especificações com resultados e cobertura, identificando principal/secundária/exploratória. **Critério:** cada alteração é apresentada com sua população, definição e efeito sobre as conclusões, incluindo resultados desfavoráveis à hipótese.

## 19. Etapa 13 — redação, rastreabilidade e reprodução

Produzir: tabela de cobertura/listagens observadas; prevalência de perdas; descrição dos atributos e snapshots; comparação M0–M4; curvas de calibração; diferença principal com intervalo; análise de ausências; comparação bayesiana diária e diagnósticos; sensibilidades; apêndice de fontes. **Decisão de apresentação; avaliação probabilística em [R15] e fluxo bayesiano em [R18].**

Cada previsão deve conter pelo menos `asset_id`, `forecast_at`, `label_end`, `label_available_at`, `Y`, `model_id`, `algorithm`, `p_raw`, `p_calibrated`, `fit_id`, `graph_id`, `protocol_version`, `data_manifest_hash` e motivo de fallback/ausência. Registrar em cada ajuste o último rótulo usado, a amostra de calibração e as versões dos pacotes. **Decisão de rastreabilidade**, operacionalizada por [targets][P19], [renv][P01] e [digest][P03].

Gerar citações dos pacotes efetivamente usados com `citation("nome_do_pacote")` e incluir R com `citation()`. Conservar as referências acadêmicas completas na seção 22 e no [CSV bibliográfico](bibliografia_avaliacao.csv). As fontes técnicas não substituem a literatura econômica: descrevem como a implementação funciona. **Decisão de documentação.**

Para reproduzir, restaurar `renv.lock`, conferir acesso aos arquivos brutos/hash e executar as dependências do projeto. O `targets` deve separar coleta, auditoria, atributos, snapshots, splits, modelos, previsões e relatórios. Não executar novamente downloads históricos quando o manifesto selecionado não mudou; atualizações deliberadas devem gerar nova versão. **Fontes:** [targets][P19] e [renv][P01].

## 20. Ordem de execução e critérios de passagem

Os prazos abaixo são estimativas de organização, não garantias de duração ou resultados. A disponibilidade dos dados e o custo da etapa bayesiana serão medidos no piloto. **Decisão de planejamento.**

| Ordem | Trabalho | Arquivo/entrega | Critério para avançar | Estimativa |
| --- | --- | --- | --- | --- |
| 0 | Preparar ambiente | Script entregue; lockfile e versões | Pacotes carregam | 1 dia |
| 1 | Auditar candidatos e piloto | Script entregue; manifesto inicial | Identidade e unidades compreendidas | 2–3 dias |
| 2 | Implementar coletor completo | Manifesto e arquivos por par/mês | Cobertura e lacunas descritas | 3–5 dias |
| 3 | Limpar e armazenar | Painel Parquet e QA | Chaves, UTC, ausências e conflitos resolvidos | 2–4 dias |
| 4 | Construir alvo/atributos | Dicionário e tabelas analíticas | Nenhum atributo futuro; alvo por horário exato | 2–4 dias |
| 5 | Construir redes | Snapshots e atributos | Escala, espectro e BTC conferidos | 2–4 dias |
| 6 | Construir avaliações temporais | Splits e auditoria de informação | Rótulos conhecidos em cada ajuste | 2–3 dias |
| 7–8 | Estimar e calibrar | M0–M4 e previsões | Amostra comum; calibração fora da amostra | 3–5 dias |
| 9–10 | Comparar e quantificar incerteza | Métricas, cobertura e bootstrap | Pareamento e ponderação corretos | 2–3 dias |
| 11 | Inferência bayesiana | Modelo diário, draws e diagnósticos | Convergência e previsão temporal válidas | 5–10 dias |
| 12 | Robustez | Tabelas completas | Variações e limites documentados | 3–5 dias |
| 13 | Redação e reprodução | Relatório e apêndices | Conclusões proporcionais à evidência | 4–7 dias |

**Primeira ação executável:** executar os scripts 00 e 01 em R e revisar `manifesto_piloto.csv`. A próxima entrega de desenvolvimento será o coletor completo da etapa 2; este plano não deve ser confundido com um pipeline integral já implementado. Os scripts iniciais não fazem negociação, não usam API privada e não baixam automaticamente todos os anos.

## 21. Auditoria das correções incorporadas

| Problema do plano anterior | Correção aplicada neste documento | Onde verificar |
| --- | --- | --- |
| Confiança sem medida própria | Estresse de BTC observável; confiança fora do desfecho | Seções 1 e 10 |
| Queda chamada de contágio | Perda futura em USDT; alcance associativo/preditivo | Seções 1 e 10 |
| Rede sem camada definida | Dependência positiva de retornos spot | Seção 11 |
| Katz potencialmente constante por normalização | Escala global; prova e diagnóstico | Seção 11 |
| Centralidade geral confundida com exposição ao BTC | Vetor homogêneo e coluna BTC separados | Seção 11 |
| Horizonte de 24h sem maturação | `label_available_at` obrigatório em cada ajuste | Seção 12 |
| Separação temporal genérica | Origem única para todo o painel e atualização mensal explícita | Seção 12 |
| Referência preditiva fraca | M2 com fatores e M3/M4 incrementais | Seção 13 |
| Probabilidades sem calibração | Arquivo histórico fora da amostra e regra de fallback | Seção 14 |
| Métricas sem dependência | Bootstrap diário pareado, com numerador e denominador | Seção 16 |
| Naive Bayes tratado como inferência completa | Etapa hierárquica com estado temporal e posterior | Seção 17 |
| Universo e datas inconsistentes | 17 candidatos auditáveis, USDT, datas e papéis explícitos | Seções 2–3 e configuração |
| Código anunciado como pronto | Separação entre scripts entregues e implementações pendentes | Seções 5 e 20 |
| Citações genéricas | Fontes diretas por decisão e bibliografia | Todas as seções e seção 22 |

Este protocolo define uma pesquisa executável em etapas. A confirmação de cobertura, o sucesso dos ajustes e os resultados dependem das auditorias descritas; nenhuma probabilidade ou conclusão empírica foi antecipada.

## 22. Referências acadêmicas e documentação

Os IDs R01–R20 são mantidos do parecer para facilitar rastreabilidade; nem todos precisam ser utilizados no núcleo atual. R21–R22 acrescentam fundamentos de bootstrap temporal e diagnóstico MCMC. D03–D05 e P01–P26 documentam a implementação em R. Links técnicos foram conferidos em 02/11/2026; as versões efetivamente instaladas devem ser registradas na execução.

### 22.1. Literatura acadêmica

- **R01.** Ballester, C.; Calvó-Armengol, A.; Zenou, Y. (2006). Who's Who in Networks. Wanted: The Key Player. *Econometrica*, 74(5), 1403–1417. [DOI][R01].
- **R02.** Acemoglu, D.; Carvalho, V. M.; Ozdaglar, A.; Tahbaz-Salehi, A. (2012). The Network Origins of Aggregate Fluctuations. *Econometrica*, 80(5), 1977–2016. [DOI][R02].
- **R03.** Acemoglu, D.; Ozdaglar, A.; Tahbaz-Salehi, A. (2015). Systemic Risk and Stability in Financial Networks. *American Economic Review*, 105(2), 564–608. [Artigo][R03].
- **R04.** Haldane, A. G.; May, R. M. (2011). Systemic risk in banking ecosystems. *Nature*, 469, 351–355. Perspective. [Artigo][R04].
- **R05.** Bardoscia, M.; Barucca, P.; Battiston, S.; Caccioli, F.; Cimini, G.; Garlaschelli, D.; Saracco, F.; Squartini, T.; Caldarelli, G. (2021). The physics of financial networks. *Nature Reviews Physics*, 3, 490–507. [Versão dos autores][R05]. DOI: 10.1038/s42254-021-00322-5.
- **R07.** Acemoglu, D.; Dahleh, M. A.; Lobel, I.; Ozdaglar, A. (2011). Bayesian Learning in Social Networks. *Review of Economic Studies*, 78(4), 1201–1236. [Página dos autores][R07]. DOI: 10.1093/restud/rdr004.
- **R08.** Forbes, K. J.; Rigobon, R. (2002). No Contagion, Only Interdependence: Measuring Stock Market Comovements. *Journal of Finance*, 57(5), 2223–2261. [DOI][R08].
- **R09.** Manski, C. F. (1993). Identification of Endogenous Social Effects: The Reflection Problem. *Review of Economic Studies*, 60(3), 531–542. [DOI][R09].
- **R10.** Bramoullé, Y.; Djebbari, H.; Fortin, B. (2009). Identification of peer effects through social networks. *Journal of Econometrics*, 150(1), 41–55. [DOI][R10].
- **R11.** Diebold, F. X.; Yilmaz, K. (2014). On the network topology of variance decompositions: Measuring the connectedness of financial firms. *Journal of Econometrics*, 182(1), 119–134. [DOI][R11].
- **R12.** Liu, Y.; Tsyvinski, A.; Wu, X. (2022). Common Risk Factors in Cryptocurrency. *Journal of Finance*, 77(2), 1133–1177. [DOI][R12].
- **R13.** Ji, Q.; Bouri, E.; Lau, C. K. M.; Roubaud, D. (2019). Dynamic connectedness and integration in cryptocurrency markets. *International Review of Financial Analysis*, 63, 257–272. [Artigo][R13]. DOI: 10.1016/j.irfa.2018.12.002.
- **R14.** Będowska-Sójka, B.; Wójcik, P.; Giordano, S. (2025; online 2024). Has bitcoin been dethroned too quickly? The cryptocurrency return networks. *Network Science*, 13, e1. [DOI][R14].
- **R15.** Gneiting, T.; Raftery, A. E. (2007). Strictly Proper Scoring Rules, Prediction, and Estimation. *JASA*, 102(477), 359–378. [DOI][R15].
- **R16.** Niculescu-Mizil, A.; Caruana, R. (2005). Predicting Good Probabilities With Supervised Learning. *ICML*, 625–632. Conferência. [Versão dos autores][R16]. DOI: 10.1145/1102351.1102430.
- **R17.** Gelman, A.; Jakulin, A.; Pittau, M. G.; Su, Y.-S. (2008). A weakly informative default prior distribution for logistic and other regression models. *Annals of Applied Statistics*, 2(4), 1360–1383. [DOI][R17].
- **R18.** Gabry, J.; Simpson, D.; Vehtari, A.; Betancourt, M.; Gelman, A. (2019). Visualization in Bayesian workflow. *JRSS: Series A*, 182(2), 389–402. [DOI][R18].
- **R19.** Bürkner, P.-C.; Gabry, J.; Vehtari, A. (2020). Approximate leave-future-out cross-validation for Bayesian time series models. *Journal of Statistical Computation and Simulation*, 90(14), 2499–2523. [DOI][R19].
- **R20.** Amihud, Y. (2002). Illiquidity and stock returns: cross-section and time-series effects. *Journal of Financial Markets*, 5(1), 31–56. [DOI][R20].
- **R21.** Politis, D. N.; Romano, J. P. (1994). The Stationary Bootstrap. *JASA*, 89(428), 1303–1313. [DOI][R21]. Ver também o algoritmo documentado em [boot][P17].
- **R22.** Vehtari, A.; Gelman, A.; Simpson, D.; Carpenter, B.; Bürkner, P.-C. (2021). Rank-Normalization, Folding, and Localization: An Improved R-hat for Assessing Convergence of MCMC (with discussion). *Bayesian Analysis*, 16(2), 667–718. [Artigo dos autores][R22]. DOI: 10.1214/20-BA1221.

### 22.2. Dados e software

- **D01.** Binance Public Data: [formatos, timestamps, checksums e revisões][D01].
- **D03.** Binance: [Exchange information][D03].
- **D04.** Binance: [Market Data Only URLs][D04].
- **D05.** Binance: [Kline/Candlestick data][D05].
- **P01–P26.** As fontes oficiais dos pacotes estão ligadas diretamente na tabela da seção 4 e nas etapas correspondentes. As referências de software usadas na redação final devem vir de `citation()` da versão instalada, incluindo o pacote R e o executável CmdStan quando pertinente.

### 22.3. Materiais locais utilizados

- Jackson, M. O. (2008). *Social and Economic Networks*. Caps. 2, 7–9, especialmente 9.5.2. [TXT local](../referencias/livro_jackson.txt).
- Newman, M. (2018). *Networks*, 2ª ed. Caps. 6–7 e 15–17, especialmente 7.1.3. [TXT local](../referencias/livro_newman_networks_2ed.txt).
- Easley, D.; Kleinberg, J. (2010). *Networks, Crowds, and Markets*. Caps. 4, 16 e 19. [TXT local](../referencias/livro_easley_kleinberg.txt).
- Aulas locais de centralidade, complementaridades, cascatas e aprendizado: [aula 02](../referencias/aula_02.txt), [aula 06](../referencias/aula_06.txt), [aula 07](../referencias/aula_07.txt), [aula 08](../referencias/aula_08.txt).
- Sadler, E. Notas de *Economics of Networks*: [complementaridades](../referencias/sadler_networks_06_network_effects_part_2.txt), [mercados em rede](../referencias/sadler_networks_08_networked_markets.txt), [aprendizado](../referencias/sadler_networks_10_social_learning.txt), [difusão](../referencias/sadler_networks_11_diffusion_part_1.txt).

## 23. Verificação técnica desta entrega

Foi validada a sintaxe dos dois scripts iniciais e da configuração no R 4.4.1 disponível, além dos três blocos R executáveis deste documento. A configuração foi carregada para conferir datas e horizonte; o inventário foi conferido para 17 identificadores únicos e 14 alvos potenciais. Também foram conferidos os vínculos locais, os identificadores das referências e a ausência de IDs bibliográficos duplicados.

Os scripts de instalação e download não foram executados nesta revisão. A instalação das dependências, o acesso aos servidores, os checksums remotos e a cobertura histórica serão verificados nas etapas 0–2. As análises completas e o modelo Stan ainda precisam ser implementados conforme as etapas descritas. Validação de sintaxe não equivale à validação empírica do pipeline.

[R01]: https://doi.org/10.1111/j.1468-0262.2006.00709.x
[R02]: https://doi.org/10.3982/ECTA9623
[R03]: https://www.aeaweb.org/articles?id=10.1257/aer.20130456
[R04]: https://www.nature.com/articles/nature09659
[R05]: https://arxiv.org/abs/2103.05623
[R07]: https://asu.mit.edu/publication/bayesian-learning-social-networks/
[R08]: https://doi.org/10.1111/0022-1082.00494
[R09]: https://doi.org/10.2307/2298123
[R10]: https://doi.org/10.1016/j.jeconom.2008.12.021
[R11]: https://doi.org/10.1016/j.jeconom.2014.04.012
[R12]: https://doi.org/10.1111/jofi.13119
[R13]: https://www.sciencedirect.com/science/article/pii/S1057521918305416
[R14]: https://doi.org/10.1017/nws.2024.17
[R15]: https://doi.org/10.1198/016214506000001437
[R16]: https://www.cs.cornell.edu/~alexn/papers/calibration.icml05.crc.rev3.pdf
[R17]: https://doi.org/10.1214/08-AOAS191
[R18]: https://doi.org/10.1111/rssa.12378
[R19]: https://doi.org/10.1080/00949655.2020.1783262
[R20]: https://doi.org/10.1016/S1386-4181(01)00024-6
[R21]: https://doi.org/10.1080/01621459.1994.10476870
[R22]: https://sites.stat.columbia.edu/gelman/research/published/Vehtari_etal_2020_rhat_ess.pdf
[D01]: https://github.com/binance/binance-public-data/blob/master/README.md
[D03]: https://developers.binance.com/en/docs/catalog/core-trading-spot-trading/api/rest-api/general
[D04]: https://github.com/binance/binance-spot-api-docs/blob/master/faqs/market_data_only.md
[D05]: https://developers.binance.com/en/docs/catalog/core-trading-spot-trading/api/rest-api/market
[P01]: https://rstudio.github.io/renv/articles/renv.html
[P02]: https://httr2.r-lib.org/reference/req_perform.html
[P02R]: https://httr2.r-lib.org/reference/req_retry.html
[P03]: https://eddelbuettel.github.io/digest/
[P04]: https://jeroen.r-universe.dev/jsonlite/doc/manual.html
[P05]: https://rdatatable.gitlab.io/data.table/reference/fread.html
[P06]: https://lubridate.tidyverse.org/
[P07]: https://slider.r-lib.org/reference/slide_index.html
[P08]: https://arrow.apache.org/docs/r/articles/arrow.html
[P09]: https://dbi.r-dbi.org/
[P10]: https://r.duckdb.org/
[P11]: https://r.igraph.org/reference/graph_from_adjacency_matrix.html
[P12]: https://r.igraph.org/reference/betweenness.html
[P13]: https://glmnet.stanford.edu/articles/glmnet.html
[P14]: https://majkamichal.github.io/naivebayes/reference/gaussian_naive_bayes.html
[P15]: https://yardstick.tidymodels.org/reference/pr_auc.html
[P16]: https://yardstick.tidymodels.org/reference/average_precision.html
[P17]: https://cran.r-project.org/web/packages/boot/boot.pdf
[P18]: https://ggplot2.tidyverse.org/
[P19]: https://books.ropensci.org/targets/
[P20]: https://paulbuerkner.com/brms/reference/brm.html
[P21]: https://mc-stan.org/cmdstanr/articles/cmdstanr.html
[P22]: https://mc-stan.org/posterior/reference/diagnostics.html
[P23]: https://mc-stan.org/bayesplot/
[P24]: https://mc-stan.org/loo/articles/loo2-lfo.html
[P25]: https://paulbuerkner.com/brms/reference/ar.html
[P26]: https://yardstick.tidymodels.org/reference/roc_auc.html
