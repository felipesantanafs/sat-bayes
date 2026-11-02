# Redes econômicas e sociais em blockchain e criptomoedas: contexto e desenhos empíricos

Pesquisa bibliográfica e documental: 1º de novembro de 2026.

Este documento transforma os materiais de redes da pasta em uma agenda de pesquisa aplicada. Contém cinco projetos alternativos, literatura relacionada, estratégias empíricas e especificações das bases a construir. As hipóteses e especificações abaixo são propostas de pesquisa; não representam resultados estimados.

Foram examinados os sumários dos três livros, os temas dos 13 conjuntos de notas de Evan Sadler e as sete aulas disponíveis, com leitura de trechos sobre formação estratégica, difusão, aprendizado e mensuração. O guia de QGIS foi considerado para avaliar uma possível extensão espacial. Não se trata de uma revisão sistemática exaustiva: a busca priorizou artigos, páginas de autores, repositórios universitários e documentação dos provedores de dados. Na etapa inicial, as bases completas não foram baixadas. No aprofundamento do projeto 5, os dois arquivos SNAP foram baixados e auditados; a especificação revisada está em [desenho_empirico_aprofundado.md](projeto5_reputacao/desenho_empirico_aprofundado.md). Nenhuma regressão foi executada.

## 1. Contexto de pesquisa que pode orientar o projeto

### Texto-base para uma introdução

Blockchain e criptomoedas oferecem um ambiente para investigar como a organização das interações econômicas afeta coordenação, adoção tecnológica, concentração e fragilidade financeira. O acesso público a registros de transações permite observar relações que frequentemente permanecem ocultas em mercados tradicionais. Entretanto, a descentralização do registro não implica distribuição uniforme de recursos, influência ou poder decisório. Por isso, o objeto econômico relevante inclui tanto as características dos ativos quanto a estrutura das relações entre seus participantes.

A literatura de redes organiza essa investigação em três problemas complementares. Primeiro, agentes escolhem conexões considerando custos e benefícios privados, que podem produzir estruturas diferentes das socialmente desejáveis. Segundo, conexões transmitem informação e alteram os benefícios de adotar tecnologias e comportamentos. Terceiro, a interdependência entre participantes pode propagar choques originalmente localizados. Esses mecanismos oferecem uma ponte entre formação estratégica de redes, aprendizado social e fragilidade de mercados. As referências teóricas são [Jackson e Wolinsky, 1996](https://doi.org/10.1006/jeth.1996.0108), [Golub e Jackson, 2010](https://doi.org/10.1257/mic.2.1.112) e [Acemoglu et al., 2012](https://doi.org/10.3982/ECTA9623).

O ambiente cripto permite operacionalizar esses mecanismos por meio de redes distintas: canais de pagamento, transferências de tokens, exposições financeiras entre contratos, reputação entre usuários e delegação de votos. A escolha da rede determina a pergunta que os dados podem responder. Uma transferência registra um movimento econômico, mas não comprova uma relação de amizade ou uma transmissão de informação. Uma conexão entre nós Lightning permite estudar infraestrutura, mas não revela todos os pagamentos que passam por ela. O desenho empírico precisa, portanto, vincular uma relação observável a um mecanismo econômico específico.

Uma pergunta abrangente seria: **como a posição dos participantes e a estrutura de suas conexões se relacionam com a formação de mercados, a difusão de comportamentos e a transmissão de choques em ecossistemas de criptomoedas?** Para uma dissertação ou artigo, essa pergunta deve ser reduzida a um dos cinco projetos da seção 4.

### O que a literatura aplicada já estabeleceu

Makarov e Schoar construíram uma base de endereços e entidades para estudar transações, mineração e concentração no Bitcoin. Seu trabalho é particularmente útil para entender o problema de passar de endereços a agentes econômicos. A versão inicial é o [NBER Working Paper 29396, de 2021](https://www.nber.org/papers/w29396); a [página do autor](https://personal.lse.ac.uk/makarov1/) registra uma versão futura na American Economic Review. A reprodução integral pode exigir fontes proprietárias e algoritmos de identificação de entidades.

Na Lightning Network, centralização e vulnerabilidade topológica já foram estudadas por [Martinazzi e Flori, 2020](https://doi.org/10.1371/journal.pone.0225966) e [Lin et al., 2020](https://arxiv.org/abs/2002.02819). Há também uma análise longitudinal de estabilidade publicada em [2026 por Valko e Marx Gómez](https://doi.org/10.1007/s41109-026-00820-4). Assim, apenas calcular centralidades e mostrar concentração provavelmente oferece uma contribuição limitada. É necessário delimitar um mecanismo adicional, uma comparação ou uma avaliação econômica.

Em adoção, [Cong, Li e Wang, 2021](https://academic.oup.com/rfs/article-abstract/34/3/1105/5891182) fornecem um modelo teórico de externalidades de rede e valorização de tokens. [Morales et al., 2023](https://dspace.mit.edu/entities/publication/9c192aff-3b23-42c2-a924-1bbc79b4054e) estudam redes de transações ERC-20 e diversidade de uso. Essa combinação ajuda a distinguir a teoria de adoção da evidência descritiva sobre interação entre endereços.

Para crises, [Liu, Makarov e Schoar, 2026](https://doi.org/10.1016/j.jfineco.2026.104359), publicado no Journal of Financial Economics, relacionam a corrida de Terra a concentração, incentivos e observabilidade das saídas. Para governança, [Born et al., 2026](https://www.ecb.europa.eu/pub/pdf/scpwps/ecb.wp3208~051a880042.en.pdf) examinam concentração e identificação de atores; [Fan, Shu e Xie, 2025, revisão de 2026](https://www.ecgi.global/publications/working-papers/is-there-wisdom-among-the-dao-crowd-evidence-from-vote-delegation), estudam delegação na MakerDAO. Estes dois últimos trabalhos são working papers, não artigos apresentados aqui como já publicados em periódico.

## 2. Como os seus arquivos sustentam o desenho

| Arquivos locais | Conceito que orienta a pesquisa | Aplicação empírica |
| --- | --- | --- |
| `aula_01.txt`; Newman, cap. 6 | Redes direcionadas, ponderadas, bipartidas e multicamadas | Definir nó, aresta, peso, direção e unidade temporal antes de calcular métricas |
| `aula_02.txt`; Newman, cap. 7 | Grau, autovetor, Katz, intermediação, homofilia e reciprocidade | Medir concentração, intermediação, comunidades e reputação |
| `aula_04.txt`; Jackson, caps. 4–5 | Grafos aleatórios e ligação preferencial | Comparar a rede observada com modelos de referência e analisar entrada de novas conexões |
| `aula_05.txt`; `sadler_networks_13_network_formation.txt`; Jackson, cap. 6 | Formação estratégica; estabilidade aos pares versus eficiência | Investigar abertura e manutenção de canais Lightning |
| `aula_06.txt`; Sadler, partes 5–6; Jackson, cap. 9 | Jogos em redes e complementaridades estratégicas | Relacionar uso de protocolos às escolhas dos vizinhos |
| `aula_07.txt`; Sadler, partes 9 e 11–12; Easley–Kleinberg, caps. 16 e 19 | Cascatas informacionais, coordenação e limiares | Investigar adoção e sequências de saída em crises |
| `aula_08.txt`; `sadler_networks_10_social_learning.txt`; Jackson, cap. 8 | DeGroot, influência e velocidade de consenso | Formular hipóteses sobre delegação e concentração da influência |
| `sadler_networks_04_traffic_flow_and_congestion_games.txt` | Congestionamento, roteamento e paradoxo de Braess | Analisar custos de canais e simular rotas sob hipóteses explícitas |
| `sadler_networks_07_repeated_games_cooperation_and_network_applications.txt` | Cooperação e reputação em interações repetidas | Estudar redes de confiança Bitcoin OTC e Alpha |
| `sadler_networks_08_networked_markets.txt`; Jackson, cap. 10 | Mercados em redes e propagação de choques | Construir redes de exposição a stablecoins e protocolos |
| Newman, cap. 9 | Erro de mensuração de redes | Auditar ausência de conexões, cobertura temporal e classificação de nós |
| `ex_pib_sp_guia_qgis_pib_sp.txt` | Associação espacial de indicadores e municípios | Extensão espacial somente com localização validada dos agentes |

As partes 1–3 de Sadler fornecem a introdução e os fundamentos de teoria dos jogos necessários às partes aplicadas. Os livros são referências conceituais; as propostas não pressupõem que eles estudem especificamente criptomoedas.

Na aula 05, a definição de estabilidade aos pares aparece nas páginas 7–8 do arquivo extraído; a discussão de eficiência começa na página 9. Na aula 07, as páginas 15–18 distinguem informação, coordenação e adoção por limiar. Essa distinção é central: a mesma sequência de compras pode ser compatível com mecanismos diferentes. Na aula 08, crenças são objetos do modelo de aprendizado; saldos e transações não são medidas diretas dessas crenças.

## 3. Qual rede será observada?

| Camada | Nós | Aresta observada | O que permite estudar |
| --- | --- | --- | --- |
| Transferências | Endereços ou entidades identificadas | Movimento de um ativo entre origem e destino | Circulação, concentração e conexões econômicas |
| Infraestrutura Lightning | Chaves públicas de nós | Canal público; políticas podem diferir por direção | Formação de infraestrutura, conectividade e resiliência topológica |
| Exposições DeFi | Carteiras, posições, pools e protocolos | Colateral, reservas ou obrigações explicitamente reconstruídas | Transmissão financeira de choques |
| Reputação | Identificadores de usuários | Avaliação dirigida e assinada em escala de confiança | Reciprocidade, confiança e formação de relações |
| Governança | Detentores, delegados e propostas | Delegação, voto ou participação em proposta | Concentração de poder e coordenação |
| Comunicação, se adicionada | Contas e mensagens | Resposta, menção ou vínculo de seguimento observado | Exposição informacional e interação social |

**Regra de interpretação:** um endereço não equivale automaticamente a uma pessoa, um nó Lightning não equivale necessariamente a uma empresa e uma comunidade de transferências não equivale a um grupo social. Trabalhar na unidade diretamente observada e apresentar agrupamentos de entidades apenas quando houver documentação verificável.

Não construir uma rede financeira apenas correlacionando retornos e denominá-la rede de exposições. Correlações podem ser úteis para estudar comovimento, mas não identificam quem deve a quem nem por onde um choque foi transmitido.

## 4. Cinco projetos possíveis

### Projeto 1 — Formação e persistência de conexões na Lightning Network

**Pergunta:** novos canais se concentram em nós já centrais? A posição dos nós e os custos anunciados se relacionam com a persistência das conexões?

**Mecanismo:** abrir e manter canais envolve custos e recursos comprometidos; conectar-se a nós bem posicionados pode ampliar acesso à rede. As escolhas individuais podem produzir concentração e dependência de intermediários. Estabilidade aos pares, da aula 05, oferece a motivação teórica. Sua verificação direta exigiria conhecer benefícios, custos e alternativas de cada agente, que não são integralmente observados.

**Hipóteses:** H1: nós com maior grau prévio recebem mais novas conexões, condicionalmente à idade e à capacidade observada. H2: conexões entre regiões pouco conectadas da rede apresentam persistência diferente das conexões redundantes. H3: retirar nós centrais causa maior perda de conectividade simulada do que retirar nós aleatórios com igual orçamento de remoção.

**Base indicada:** começar com os snapshots de [Valko e Marx Gómez, 2025](https://www.nature.com/articles/s41597-025-06413-7), disponibilizados no [Harvard Dataverse, DOI 10.7910/DVN/2OAVO6](https://doi.org/10.7910/DVN/2OAVO6). O artigo documenta 336 snapshots entre 2019 e 2023. Para reconstrução em outra frequência e exame das políticas direcionais, usar os arquivos de [gossip do lnresearch](https://github.com/lnresearch/topology). Código de preparação: [ln-data-preparation](https://github.com/ellariel/ln-data-preparation).

**Amostra proposta:** usar inicialmente 2020–2023, dentro da cobertura efetiva dos arquivos, e comparar com a extensão a 2019. Não presumir observações diárias uniformes: datas, espaçamento e disponibilidade de cada atributo precisam ser auditados. Um piloto com 12 snapshots pode validar o processamento; o painel final deve aproveitar a série elegível.

**Unidades:** nó × snapshot; canal × snapshot; e par de nós × intervalo para formação de ligações. A rede binária deve agregar canais paralelos entre o mesmo par. A análise de canais preserva cada canal separadamente. Políticas de roteamento requerem duas observações direcionais por canal quando ambas estiverem disponíveis.

| Tabela proposta | Campos mínimos | Uso |
| --- | --- | --- |
| `ln_nodes` | `snapshot_time`, `node_pubkey`, `first_seen`, `degree`, `strength_sat`, indicadores de cobertura | Centralidade, entrada e recursos conectados |
| `ln_channels` | `snapshot_time`, `channel_id`, `node_u`, `node_v`, `capacity_sat`, `observed_present` | Persistência de canais e concentração |
| `ln_policies` | `observed_time`, `channel_id`, `direction`, `fee_base_msat`, `fee_rate_ppm`, `disabled`, fonte | Custos anunciados por direção; extensão dependente de cobertura |
| `ln_pairs` | início/fim do intervalo, par, ligação anterior, primeira aparição posterior, distância e covariáveis anteriores | Formação de relações |

Campos são o esquema desejado, não garantia de presença em todo snapshot. Se capacidade ou políticas estiverem ausentes, completar por fonte documentada ou reduzir a pergunta. Grau e persistência observada permitem um primeiro estudo sem esses atributos.

**Método:** comparar a escolha de parceiros por novos entrantes com conjuntos de nós que já existiam no intervalo anterior. Um logit condicional de escolha de parceiro pode usar `log(1 + grau anterior)`, idade e atributos prévios. Para relações entre incumbentes, definir o conjunto de pares ainda sem conexão. A enumeração de todos os pares pode ser inviável; usar amostragem dos não eventos com probabilidades registradas e correção apropriada ao estimador.

Persistência pode ser estudada por sobrevivência em tempo discreto. Um canal que deixa de aparecer fica inicialmente classificado como ausência observada; fechamento confirmado exige reconciliação com a saída de financiamento no Bitcoin. Comparar regras de ausência em dois ou três snapshots e tratar censura à direita e lacunas de coleta. O tempo entre snapshots deve entrar no modelo quando desigual.

**Métricas:** grau, força, intermediação aproximada com erro documentado, componentes, assortatividade e persistência de arestas. Para concentração de capacidade conectada, definir `s_i = soma das capacidades dos canais incidentes em i` e `p_i = s_i / soma_j s_j`; então `HHI = soma_i p_i²`. Essa é concentração de capacidade por extremidade de canal, com cada canal contado em seus dois nós, e não distribuição de riqueza entre pessoas.

**Exercício complementar:** simular remoções por grau, intermediação e sorteio. Reportar pares conectados, componente gigante e eficiência topológica com denominador fixado à população original; atribuir contribuição zero a pares desconectados ou removidos. Isso evita aumentos artificiais da métrica por redução da amostra. Se houver roteamento, variar valores de pagamentos e hipóteses de saldo direcional.

**Limite de inferência:** associação temporal na formação de conexões e contrafactuais de simulação. Capacidade pública não revela saldo disponível por direção, tráfego ou lucro. Portanto, não estimar receita efetiva nem anunciar taxa real de sucesso dos pagamentos a partir de gossip. A literatura já trata centralização e estabilidade; a contribuição candidata é relacionar escolha de parceiros e persistência a incentivos observáveis, cuja novidade ainda deve ser delimitada frente a [Martinazzi–Flori](https://doi.org/10.1371/journal.pone.0225966), [Lin et al.](https://arxiv.org/abs/2002.02819) e [Valko–Marx Gómez, 2026](https://doi.org/10.1007/s41109-026-00820-4).

**Viabilidade:** média; melhor equilíbrio inicial entre teoria dos arquivos e existência de uma base pública estruturada.

### Projeto 2 — Exposição em rede e contágio na crise do USDC

**Pergunta:** carteiras ou pools com maior exposição prévia ao USDC responderam de forma diferente à crise de março de 2023? Conexões indiretas ajudam a explicar a resposta além da exposição direta?

**Mecanismo:** uma perda de confiança em um ativo pode afetar participantes que o mantêm diretamente e outros conectados por reservas, colateral ou liquidez compartilhada. A crise do USDC permite aproximar a discussão de mercados em redes das notas de Sadler. A [nota de Du, Sonawane e Watsky, 2025](https://www.federalreserve.gov/econres/notes/feds-notes/in-the-shadow-of-bank-run-lessons-from-the-silicon-valley-bank-failure-and-its-impact-on-stablecoins-20251217.html) documenta o episódio e o papel de conexões com DAI. É uma nota de pesquisa do Federal Reserve, distinta de artigo de periódico.

**Hipóteses:** H1: maior parcela prévia de USDC está associada a maior probabilidade de venda ou recomposição da carteira. H2: entre unidades com exposição direta comparável, maior exposição indireta está associada a maior resposta. H3: maior concentração de contrapartes amplifica ou modifica a velocidade do ajuste.

**Delimitação recomendada:** Ethereum mainnet; USDC, DAI e USDT; eventos entre 1º e 20 de março de 2023. Essa é uma janela proposta. O histórico anterior para reconstruir saldos pode ser muito mais longo. Escolher **carteiras** como unidade principal ou **pools** como unidade principal; não misturar ambos na mesma observação.

**Fontes:** transferências e logs no [Google Blockchain Analytics](https://docs.cloud.google.com/blockchain-analytics/docs/schema), mais swaps na [tabela `dex.trades` do Dune](https://docs.dune.com/data-catalog/curated/dex-trades/evm/dex-trades). Também é possível usar logs dos contratos diretamente via [JSON-RPC Ethereum](https://ethereum.org/en/developers/docs/apis/json-rpc/). Eventos financeiros devem ser decodificados com ABIs e endereços válidos no período histórico.

| Tabela proposta | Campos mínimos | Uso |
| --- | --- | --- |
| `transfers_raw` | chain, bloco, timestamp, hash, índice do log, token, origem, destino, quantidade bruta | Movimentos de tokens |
| `balances_pre` | bloco anterior ao evento, endereço, token, saldo, método de reconstrução | Exposição fixada antes do choque |
| `dex_swaps` | timestamp, hash, evento, pool, token vendido/comprado, quantidades, executor | Vendas, compras e preço relativo |
| `financial_positions` | timestamp, protocolo, posição, ativo, colateral, dívida, quantidade | Extensão para exposição financeira contratual |
| `event_timeline` | evento, horário original, fuso original, horário UTC, URL primária | Cronologia verificável |
| `wallet_hour` | endereço, hora, exposição direta/indireta, vendas, entradas, saídas, atividade | Painel principal de carteiras |

**Exposição:** no bloco anterior ao primeiro evento escolhido, calcular `E_i = valor prévio em USDC / valor prévio do portfólio observado`. Fixar preços de referência anteriores ao choque para impedir que o próprio depeg altere mecanicamente a classificação de exposição. Declarar quais ativos entram no denominador; patrimônio fora da cadeia permanece não observado.

Construir `W_pre` com relações anteriores ao evento. Se a relação for colateral ou reserva, a interpretação é financeira. Se for transferência entre carteiras, a interpretação é proximidade transacional. Definir `N_i = soma_j W_pre[i,j] E_j`, com normalização das linhas e regra explícita para isolados. Na hipótese social, pode-se excluir do desfecho o fluxo bilateral usado para definir a exposição, reduzindo relações mecânicas.

**Especificação orientadora:**

```text
y_it = α_i + τ_t
     + Σ(k ≠ -1) β_k E_i 1[tempo relativo = k]
     + Σ(k ≠ -1) θ_k N_i 1[tempo relativo = k]
     + controles prévios interagidos com tempo + ε_it
```

Usar vendas brutas de USDC ou participação dessas vendas na carteira inicial como desfecho principal. Saídas de tokens não são automaticamente vendas, e transferências para exchanges não comprovam resgate em dólar. Não adotar variação do valor em dólares da carteira como único desfecho: há efeito de marcação a mercado, mesmo sem decisão do usuário.

**Comparação:** unidades com intensidades diferentes de exposição prévia, com suporte comum em tamanho, idade e atividade. A referência não é um grupo seguramente não afetado. Efeitos de hora absorvem parte do choque agregado, mas não resolvem seleção na exposição. Delimitar separadamente a falência do SVB, a divulgação sobre reservas e o anúncio de proteção aos depositantes, com horários convertidos para UTC.

**Validação e inferência:** examinar tendências anteriores, datas placebo, redes reconfiguradas preservando características relevantes, diferentes janelas e definições de `W_pre`. Não usar milhares de carteiras como se fossem milhares de choques independentes. Há um episódio sistêmico, dependência entre carteiras e contaminação dos controles. Inferência por blocos temporais e sensibilidade à dependência em rede deve ser acompanhada dessa limitação; permutar exposição observacional não cria um experimento aleatório válido.

**Limite de inferência:** o primeiro resultado defensável é uma resposta diferencial associada à exposição anterior. Interpretar `θ_k` causalmente exige justificar que unidades com diferentes exposições indiretas teriam trajetórias comparáveis, que a exposição direta foi medida adequadamente e que não há canais omitidos que reproduzam o padrão. A extensão teórica da propagação de choques vem de [Acemoglu et al., 2012](https://doi.org/10.3982/ECTA9623); a evidência de corridas em ambiente cripto pode ser comparada a [Liu et al., 2026](https://doi.org/10.1016/j.jfineco.2026.104359), sem tratar Terra e USDC como arranjos institucionais equivalentes.

**Viabilidade:** média a alta em dificuldade; melhor opção se o objetivo central for choques e transmissão econômica.

### Projeto 3 — Difusão do uso de protocolos entre carteiras conectadas

**Pergunta:** o primeiro uso ativo de um protocolo por uma carteira é precedido pelo uso do mesmo protocolo por carteiras com as quais ela já se relacionava?

**Mecanismo:** informação transmitida por pares e complementaridades de uso podem contribuir para a adoção. No entanto, endereços semelhantes podem conectar-se e adotar os mesmos produtos sem influência entre si. A diferença entre coordenação e informação, trabalhada na aula 07, é a questão econômica a investigar.

**Hipóteses:** H1: a probabilidade de primeiro uso aumenta com a parcela de vizinhos previamente usuários. H2: a exposição a usuários de outras comunidades pode diferir da exposição dentro da comunidade. H3: usuários com diferentes graus de experiência reagem de forma diferente à exposição observada.

**Delimitação:** uma blockchain, um protocolo e um conjunto de contratos versionado. Escolher uma coorte de carteiras ativas antes do início do acompanhamento. Usar 90 dias anteriores para construir a rede e seis meses posteriores para acompanhar adoção, como desenho inicial sujeito ao piloto. Recuperar o histórico do protocolo desde seu lançamento para verificar se o uso é realmente o primeiro; caso contrário, denominar o evento “primeiro uso observado na cobertura disponível”.

**Base indicada:** eventos de uso do protocolo, transferências ERC-20 e metadados de contratos no [Google](https://docs.cloud.google.com/blockchain-analytics/docs/schema) ou no [Dune](https://docs.dune.com/data-catalog/curated/token-transfers/evm/token-transfers). O estudo de [Morales et al., 2023](https://dspace.mit.edu/entities/publication/9c192aff-3b23-42c2-a924-1bbc79b4054e) oferece uma aplicação relacionada de redes de tokens; [Cong et al., 2021](https://academic.oup.com/rfs/article-abstract/34/3/1105/5891182) fornece a motivação de externalidades.

**Rede:** construir relações econômicas anteriores a partir de transferências repetidas entre endereços, preservando versões com diferentes critérios de valor e frequência. Excluir contratos de infraestrutura da definição principal de pares e apresentar sensibilidade com e sem esses nós. Não transformar todos os usuários de um mesmo router em amigos uns dos outros: essa projeção criaria relações artificiais em grande escala.

**Adoção:** evento iniciado pelo usuário que represente uso econômico do protocolo, por exemplo depósito ou swap qualificado. Receber tokens por airdrop, spam ou transferência não solicitada não equivale a adoção ativa. Identificar o usuário exige observar o iniciador e o contexto da chamada; `tx_to` pode ser um router.

| Tabela proposta | Campos mínimos |
| --- | --- |
| `economic_ties_pre` | origem, destino, início/fim da janela, quantidade de interações, volume, regra da aresta |
| `protocol_actions` | carteira, protocolo, contrato/versão, timestamp, evento, hash, tipo de ação, qualificação |
| `wallet_protocol_day` | carteira, protocolo, dia, em risco, primeira adoção, exposição aos vizinhos, atividade prévia |
| `wallet_features_pre` | idade observada, ativos, atividade, comunidades, classificação de endereço, fonte |

**Método:** modelo de duração discreta, como logit ou complementary log-log, aplicado somente às carteiras ainda em risco de adotar. Definir `exposição_it = soma_j W_pre[i,j] adotou_j,t-1`. Usar exposição defasada, efeitos de calendário, duração do acompanhamento e características anteriores. Se a rede for atualizada, a atualização deve usar apenas informações já disponíveis no início de cada intervalo.

**Identificação:** defasagem temporal, efeitos fixos e muitos controles não demonstram efeito causal dos pares. [Bramoullé, Djebbari e Fortin, 2009](https://doi.org/10.1016/j.jeconom.2008.12.021) apresentam condições de identificação em modelos específicos; instrumentos baseados em amigos de amigos só são defensáveis sob suas hipóteses estruturais e de exclusão. Não transportar essa solução automaticamente para redes de carteiras. [Shalizi e Thomas, 2011](https://arxiv.org/abs/1004.4704) mostram a dificuldade de separar homofilia e contágio em dados observacionais.

**Caminho para causalidade:** com um parceiro de pesquisa, distribuir aleatoriamente convites informativos para uma funcionalidade não financeira e medir adoção de usuários e vizinhos, com rede anterior e mapeamento de exposição definidos antes da intervenção. O desenho precisa considerar interferência e probabilidades de exposição, como em [Aronow e Samii, 2017](https://arxiv.org/abs/1305.6156). Esta é uma extensão que exige nova coleta e parceria; não existe pronta nas fontes acima.

**Limite de inferência:** com os dados públicos propostos, o projeto começa como estudo de difusão observada em rede econômica. Para afirmar aprendizado social, adicionar comunicação observada e ligação validada entre identidades. Séries agregadas de buscas, sentimento e preços ajudam a estudar atenção, mas não substituem a rede individual; [Garcia et al., 2014](https://www.sg.ethz.ch/publications/2014/garcia2014the-digital-traces/rsif.2014.0623.pdf) é uma referência relacionada a esses sinais agregados.

**Viabilidade:** média para associação temporal; maior dificuldade para identificação causal de influência social.

### Projeto 4 — Delegação, concentração e participação em DAOs

**Pergunta:** a delegação de votos amplia a participação representada e concentra o poder decisório? Delegados centrais ocupam posições semelhantes em diferentes propostas ou organizações?

**Mecanismo:** delegação pode reduzir o custo de participação e concentrar informação em especialistas, ao mesmo tempo que concentra influência. A teoria de aprendizado e a distinção entre estabilidade e eficiência ajudam a formular o problema, mas votos não são medidas diretas de crenças e convergência de votos não comprova aprendizado correto.

**Hipóteses:** H1: a fração de poder delegado está associada a maior concentração do poder exercido. H2: delegados com posição central participam de mais propostas. H3: o aumento da representação via delegação pode coexistir com redução do número efetivo de decisores.

**Literatura próxima:** [Born et al., 2026](https://www.ecb.europa.eu/pub/pdf/scpwps/ecb.wp3208~051a880042.en.pdf) examinam detentores e votantes em quatro protocolos. [Fan et al., 2025, revisão de 2026](https://www.ecgi.global/publications/working-papers/is-there-wisdom-among-the-dao-crowd-evidence-from-vote-delegation) estudam decisões de delegação e comportamento dos delegados. A contribuição candidata é comparar representação, concentração e posição na rede sob regras de votação bem documentadas; não afirmar apenas que existe concentração.

**Base indicada:** propostas e votos pela [API oficial do Snapshot](https://github.com/snapshot-labs/snapshot-docs/blob/master/tools/api/README.md), combinados com eventos dos contratos de governança para delegação e poder de voto. O endpoint documentado para o Hub é `https://hub.snapshot.org/graphql`. Não confundir a cobertura do Hub clássico com outras versões de infraestrutura. Confirmar endpoint, paginação e histórico do espaço escolhido durante a coleta.

**Amostra:** selecionar inicialmente duas ou três DAOs com regras comparáveis e arquivos históricos acessíveis. Uma DAO que vota em contratos próprios pode não ter no Snapshot a decisão final. É preciso distinguir consulta preliminar, votação vinculante e execução, e registrar migrações de contratos e plataformas. Um período de 12–24 meses é um ponto de partida, condicionado à cobertura.

| Tabela proposta | Campos mínimos | Uso |
| --- | --- | --- |
| `dao_rules` | DAO, intervalo de validade, plataforma, estratégia, quórum, regra de aprovação, contrato | Comparabilidade institucional |
| `proposals` | DAO, ID, autor, abertura/fim, bloco de referência, tema, status, execução | Conteúdo e resultado |
| `votes` | DAO, proposta, eleitor, escolha original, peso, timestamp, fonte | Participação efetiva |
| `delegation_events` | DAO, delegante, delegado anterior/novo, bloco, timestamp, contrato | Reconstrução da rede dirigida |
| `voting_power_snapshots` | DAO, bloco de referência, endereço, saldo elegível, poder próprio/delegado | Poder disponível em cada proposta |

**Mensuração:** rede dirigida delegante → delegado; rede bipartida eleitor → proposta. Para cada proposta, calcular concentração do poder disponível e do poder efetivamente exercido, participação ponderada, quantidade de votantes e `número efetivo de votantes = 1 / HHI`, com denominadores explícitos. Não somar saldo do delegante e poder recebido pelo delegado como se fossem votos adicionais.

**Método:** começar por decomposição da participação e análise em painel de eleitor × proposta. Uma análise de mudança de regras pode ser acrescentada se houver alteração documentada, unidades comparáveis e ausência de mudanças concomitantes dominantes. Adoção endógena de delegação não é um experimento natural por si só.

**Cautelas:** copiar escolhas de um grande delegado não demonstra influência, pois escolhas podem ter causa comum. Projeções de co-votação exigem normalização pela popularidade das propostas. Poder pivô depende da regra de votação; propostas com escolhas múltiplas ou voto quadrático exigem métodos próprios. Retorno positivo do token após uma votação não basta para classificar a decisão como correta.

**Viabilidade:** média; boa opção para aproximar redes econômicas de interação coletiva e governança.

### Projeto 5 — Reputação e reciprocidade em mercados Bitcoin

**Atualização após auditoria:** os arquivos retêm a avaliação mais recente de cada par, e a Alpha tem resolução temporal de dia. A proposta abaixo deve ser lida com essa restrição: o desenho principal passa a ser mensuração da reputação, comparação de vínculos recíprocos e validação fora da díade, conforme o [aprofundamento específico](projeto5_reputacao/desenho_empirico_aprofundado.md). Não reconstruir entrada de relações ou tempos de reação como se os arquivos fossem históricos completos. [Lepomäki, Kanniainen e Hansen (2021)](https://doi.org/10.1016/j.econlet.2021.109822) já estudam reciprocidade nessas plataformas e documentam a substituição de avaliações.

**Pergunta:** reputação recebida de usuários bem posicionados se associa à formação de novas relações e ao conteúdo de avaliações posteriores? Quanto da confiança observada pode ser explicado por reciprocidade?

**Mecanismo:** reputação e repetição de interações podem sustentar relações em ambientes com identidades pseudônimas. O projeto se conecta às aulas de centralidade e reciprocidade e às notas de Sadler sobre cooperação em jogos repetidos.

**Base indicada:** [Bitcoin OTC no SNAP](https://snap.stanford.edu/data/soc-sign-bitcoinotc.html) e [Bitcoin Alpha no SNAP](https://snap.stanford.edu/data/soc-sign-bitcoinalpha.html). As páginas documentam, respectivamente, 5.881 nós e 35.592 arestas, e 3.783 nós e 24.186 arestas. Cada linha contém `SOURCE`, `TARGET`, `RATING`, `TIME`; a avaliação varia de −10 a +10. A referência de origem é [Kumar et al., 2016](https://cs.stanford.edu/~srijan/pubs/wsn-icdm16.pdf).

**Base a construir:** tabela de avaliações retidas; tabela de díades; indicadores por usuário; e divisões amostrais por par não ordenado para validação. Acrescentar grau de entrada e saída, reciprocidade, composição de sinais e indicadores calculados sem a díade cujo desfecho será avaliado. Um painel de reputação efetivamente exibida no passado exigiria dados adicionais de revisões.

**Hipóteses revisadas:** H1: indicadores de reputação mudam ao excluir vínculos recíprocos. H2: notas inversas apresentam concordância mesmo ao considerar os padrões dos avaliadores e avaliações por terceiros. H3: indicadores construídos sem a díade avaliada contêm informação para reconstruir suas notas ocultadas. Essas hipóteses são de mensuração e associação; efeitos temporais exigem histórico completo adicional.

**Método revisado:** comparar indicadores completos e sem reciprocidade na mesma população, reportando cobertura; analisar concordância bilateral e reconstruir notas ocultadas em díades inteiras, com atributos que não utilizem essas notas. A auditoria confirmou uma linha por par dirigido, sem revisões completas. Divisão temporal dos registros retidos é apenas sensibilidade e não validação prospectiva do estado histórico da plataforma. Usar métricas adequadas ao desequilíbrio de sinais e distinguir reconstrução de notas de previsão futura.

**Comparação útil:** repetir a especificação nas duas plataformas, sem presumir equivalência de usuários entre elas. Uma análise de tríades pode usar modelos nulos que preservem graus e frequências de sinais, com tratamento explícito da estrutura temporal.

**Limite de inferência:** avaliações medem confiança declarada, não volume de negócios, lucro, fraude comprovada ou garantias de entrega. Descrever o resultado como formação de reputação. O caráter histórico limita a generalização para os mercados atuais.

**Viabilidade:** a mais alta para um primeiro exercício executável, devido ao tamanho reduzido e aos arquivos prontos para download.

## 5. Qual projeto escolher?

As avaliações abaixo são julgamento de desenho e viabilidade, não um ranking bibliométrico.

| Projeto | Encaixe com os textos | Acesso e processamento | Principal obstáculo | Indicação |
| --- | --- | --- | --- | --- |
| 1. Lightning | Formação estratégica, centralidade e congestionamento | Base estruturada pública; processamento médio | Fluxos e saldos direcionais ocultos; cobertura do gossip | Melhor ponto de partida geral |
| 2. USDC/DeFi | Propagação, cascatas e mercados em redes | Dados públicos consultáveis; engenharia maior | Saldos históricos, exposição endógena e choque único | Melhor para transmissão de choques |
| 3. Adoção | Externalidades, difusão e aprendizado | Requer eventos, coortes e rede anterior | Separar influência de seleção e incentivos comuns | Melhor para difusão; causalidade depende de desenho adicional |
| 4. DAOs | Coordenação, influência e concentração | API de votos mais contratos de governança | Reconstruir poder histórico e regras comparáveis | Melhor para governança e ação coletiva |
| 5. Reputação | Cooperação, reciprocidade e redes assinadas | Arquivos pequenos e públicos | Ausência de resultados econômicos das negociações | Melhor piloto ou trabalho de disciplina |

**Recomendação principal:** iniciar pelo projeto 1, com o título provisório “Formação e persistência de conexões na Lightning Network: centralidade, custos anunciados e concentração”. Fazer primeiro o núcleo de topologia e persistência; incluir taxas somente após confirmar cobertura das políticas. O exercício de remoção é complementar, pois sozinho se aproxima de perguntas já bem estudadas.

Se houver exigência de um efeito econômico associado a um evento, priorizar o projeto 2 e formular a pergunta como resposta diferencial por exposição prévia. Se o prazo ou a capacidade de engenharia forem muito restritos, começar pelo projeto 5.

## 6. Arquitetura das bases a construir

### Núcleo comum

Preservar eventos brutos, depois derivar redes e painéis. Não guardar somente a matriz de adjacência final: isso impediria verificar diferentes definições de conexão.

| Tabela | Granularidade e chave | Campos indispensáveis |
| --- | --- | --- |
| `source_manifest` | extração/arquivo | provedor, URL, consulta, versão, data de extração UTC, intervalo, licença/condições, hash e observações de cobertura |
| `nodes` | camada, cadeia, identificador | tipo de nó, primeira/última observação, método de classificação |
| `entity_labels` | cadeia, endereço, fonte, validade | rótulo, entidade hipotética, evidência, confiança, início/fim de validade |
| `raw_events` | identificador nativo da fonte | timestamp e ordenação nativa, payload original, fonte, versão do parser |
| `edges_period` | camada, período, origem, destino, ativo ou relação | número de eventos, peso bruto, peso ajustado, regra de construção, cobertura |
| `node_period` | camada, período, nó | atividade, atributos anteriores, métricas de rede e indicadores de ausência |
| `event_timeline` | evento e versão da cronologia | informação pública, timestamp UTC, fonte, incerteza do horário |
| `analysis_sample` | unidade e período | elegibilidade, motivo de inclusão/exclusão, desfecho, exposição e especificação |

### Identificadores e unidades

- Em EVM, guardar cadeia e endereço juntos; um mesmo texto de endereço em cadeias distintas não comprova identidade econômica comum.
- Para logs, usar cadeia, hash da transação e índice do log; guardar também bloco e hash do bloco para integridade. Eventos derivados podem exigir chave adicional.
- Para transferências nativas via traces, o índice do log não existe; usar a posição do trace ou a chave própria do provedor.
- Em Lightning, preservar canal e endpoints, sem substituir vários canais do mesmo par por um único registro bruto.
- Em governança, incluir plataforma, DAO e proposta. Um voto pode ter estrutura de escolha complexa; preservar o formato original.
- Guardar quantidades brutas como inteiros de precisão suficiente ou texto sem perda; calcular a quantidade ajustada por `raw_amount / 10^decimals`. Não usar ponto flutuante como registro canônico dos valores brutos.
- Horários analíticos em UTC. Em Ethereum, ordenar eventos por bloco, transação e log; o timestamp do bloco não revela o instante exato de cada decisão.

### Mensuração econômica

Valores em dólares precisam registrar preço, fonte, horário e cobertura. Para estudar depeg, não fixar stablecoins artificialmente em US$ 1. Manter também resultados em unidades do token e exposições calculadas a preços anteriores ao evento.

A documentação do [Dune para transferências](https://docs.dune.com/data-catalog/curated/token-transfers/evm/token-transfers) informa que `amount_usd` usa preços externos e pode estar ausente para tokens sem cobertura. Sua tabela atualmente documentada é `tokens_evm.transfers`; conferir nomes e esquemas durante a implementação. Na tabela [`dex.trades`](https://docs.dune.com/data-catalog/curated/dex-trades/evm/dex-trades), uma operação roteada pode gerar diferentes registros de execução. Definir se o objeto é volume por pool ou operação do usuário antes de agregar.

Saldos anteriores ao choque não podem ser obtidos somando apenas transferências da janela de análise. É necessário saldo inicial confiável mais fluxo completo subsequente, ou estado histórico validado. Rebases, tokens com regras especiais, migrações e versões de contratos podem exigir reconstrução específica. Para posições de empréstimo, transferências isoladas não substituem a contabilidade de colateral, dívida e juros.

### Acesso e custo

“Dado público” e “consulta gratuita ilimitada” são condições diferentes. Os arquivos do SNAP e os repositórios de pesquisa permitem começar com downloads. BigQuery, Dune e serviços RPC podem exigir conta, quotas ou cobrança de consulta/exportação; verificar o plano efetivamente disponível e estimar volume antes de uma extração extensa. Não pressupor acesso a dados históricos completos de X, Reddit, Telegram ou provedores de rótulos.

Há uma mudança operacional relevante na documentação consultada: o [Google](https://docs.cloud.google.com/blockchain-analytics/docs/schema) informa que os listings antigos de compartilhamento Ethereum mainnet deixam de receber atualizações após 31/10/2026. A referência indicada passa a ser `bigquery-public-data.goog_blockchain_ethereum_mainnet_us`. Não copiar um identificador antigo de um tutorial sem conferir o esquema atual e a cobertura.

### Controles de qualidade mínimos

1. Verificar unicidade das chaves, cobertura temporal, quantidade de eventos e registros ausentes por fonte.
2. Auditar pequena amostra de transações/canais/votos com a origem antes de calcular a rede completa.
3. Diferenciar zero de atividade, ausência de cobertura, nó fora da amostra e nó ainda não observado.
4. Separar transferências econômicas de mint, burn, spam, auto transferências identificáveis e eventos internos de infraestrutura; preservar versões com diferentes filtros.
5. Medir sensibilidade a nós de exchanges, routers e contratos, que podem dominar centralidades por função operacional.
6. Calcular comunidades e exposições usando apenas o histórico permitido pela pergunta. Comunidades estimadas com todo o período podem introduzir informação futura.
7. Em rede dirigida, explicitar orientação. Em caminhos mínimos, um valor alto pode ser capacidade ou custo: não usar o mesmo peso com interpretações opostas.
8. Apresentar sensibilidade a janela temporal, definição de conexão e erro de mensuração. Muitas métricas semelhantes não substituem uma hipótese econômica.

## 7. Regras para interpretação empírica

Há quatro resultados diferentes possíveis: descrição de estrutura, previsão de comportamento, simulação de cenários e identificação causal. Cada projeto deve declarar qual deles oferece.

**Homofilia e seleção:** indivíduos semelhantes podem conectar-se e agir de forma semelhante. Congelamento da rede, controles e defasagens ajudam a organizar a sequência temporal, mas não eliminam confundimento não observado. A referência é [Shalizi e Thomas, 2011](https://arxiv.org/abs/1004.4704).

**Reflexão e efeitos correlacionados:** o comportamento do vizinho e o do indivíduo podem responder ao mesmo fator. A possibilidade de usar estrutura de rede para identificar efeitos depende de hipóteses específicas, como mostra [Bramoullé et al., 2009](https://doi.org/10.1016/j.jeconom.2008.12.021).

**Interferência:** um tratamento ou choque em um participante pode afetar outros. Esse é frequentemente o mecanismo de interesse. Definir exposições diretas e indiretas antes de escolher o estimador, em vez de presumir independência entre unidades. [Aronow e Samii, 2017](https://arxiv.org/abs/1305.6156) tratam de inferência baseada em randomização sob interferência; suas garantias não são automaticamente transferíveis para um choque observacional.

**Concentração e bem-estar:** concentração não comprova ineficiência econômica. Um argumento de bem-estar exige função de custo/benefício e contrafactual. Eficiência topológica baseada em caminhos mínimos, eficiência de Pareto e excedente econômico são objetos diferentes.

**Previsão e causalidade:** boa previsão fora da amostra não demonstra que alterar a centralidade mudará o comportamento. Um teste de precedência temporal, inclusive em séries de preços e atenção, não identifica sozinho um canal causal social.

## 8. Execução sugerida para o projeto Lightning

O cronograma é uma estimativa de trabalho, condicionada ao acesso e à qualidade dos arquivos.

| Etapa | Entrega concreta | Critério para avançar |
| --- | --- | --- |
| 1. Delimitação, cerca de 1 semana | Pergunta, revisão focada, hipótese e definição de ligação nova | Separação clara entre contribuição proposta e estudos de 2020–2026 |
| 2. Piloto, cerca de 1 semana | 12 snapshots, inventário de atributos, grau e retenção de arestas | Identificadores estáveis, datas auditadas e lacunas descritas |
| 3. Painel, cerca de 2 semanas | Nós, canais e pares em risco; políticas se disponíveis | Cobertura suficiente e ausência separada de fechamento |
| 4. Análise, cerca de 2 semanas | Escolha de parceiros, persistência e modelos de referência | Resultados reproduzíveis e inferência compatível com dependência |
| 5. Robustez e redação, cerca de 2 semanas | Janelas alternativas, simulações e limites | Conclusões formuladas na unidade observada e sem extrapolar tráfego |

O piloto deve decidir se taxas entram no trabalho. Caso a cobertura não seja adequada, manter um projeto de formação e persistência baseado em grau, distância e idade da conexão. Se o objetivo final exigir lucro de roteamento, será necessária outra fonte de observações operacionais.

## 9. Extensão brasileira ou espacial

O guia de QGIS permite estruturar uma visualização territorial, mas não fornece a localização das carteiras. Geolocalização de servidor, IP ou nó Lightning não identifica município de residência dos usuários, nem necessariamente o local da empresa operadora. Não associar endereços a PIB municipal sem uma ligação territorial válida.

Uma pergunta brasileira exigiria outra unidade observável, como respondentes de pesquisa com consentimento e município, estabelecimentos identificados ou agregados territoriais documentados. Essa extensão depende de nova coleta ou de uma base institucional específica e deve ser tratada como projeto separado, não como simples junção do blockchain com o CSV de PIB.

## 10. Literatura selecionada e ordem de leitura

Os IDs abaixo correspondem ao arquivo `bibliografia_rede_cripto.csv`. Cada entrada indica a função do trabalho no desenho; não há alegação de que todos identifiquem efeitos causais.

| ID | Referência e fonte | Tipo | Uso no projeto |
| --- | --- | --- | --- |
| R01 | Jackson; Wolinsky (1996). [A Strategic Model of Social and Economic Networks](https://doi.org/10.1006/jeth.1996.0108). Journal of Economic Theory | Teórico | Incentivos de formação; estabilidade e eficiência; projeto 1 |
| R02 | Golub; Jackson (2010). [Naïve Learning in Social Networks and the Wisdom of Crowds](https://doi.org/10.1257/mic.2.1.112). AEJ: Microeconomics | Teórico | Influência e aprendizado; projetos 3–4 |
| R03 | Acemoglu; Carvalho; Ozdaglar; Tahbaz-Salehi (2012). [The Network Origins of Aggregate Fluctuations](https://doi.org/10.3982/ECTA9623). Econometrica | Teórico | Propagação de choques; projeto 2 |
| R04 | Bramoullé; Djebbari; Fortin (2009). [Identification of Peer Effects through Social Networks](https://doi.org/10.1016/j.jeconom.2008.12.021). Journal of Econometrics | Método e aplicação | Hipóteses para identificar efeitos de pares; projeto 3 |
| R05 | Shalizi; Thomas (2011). [Homophily and Contagion Are Generically Confounded in Observational Social Network Studies](https://arxiv.org/abs/1004.4704). Sociological Methods & Research | Método | Limites da identificação observacional; projetos 2–4 |
| R06 | Aronow; Samii (2017). [Estimating Average Causal Effects Under General Interference, with Application to a Social Network Experiment](https://arxiv.org/abs/1305.6156). Annals of Applied Statistics | Método | Desenho de exposições sob interferência |
| R07 | Makarov; Schoar (2021; versão posterior anunciada como forthcoming). [Blockchain Analysis of the Bitcoin Market](https://www.nber.org/papers/w29396) | WP inicial; publicação futura anunciada pelo autor | Endereços, entidades e concentração; construção de dados |
| R08 | Cong; Li; Wang (2021). [Tokenomics: Dynamic Adoption and Valuation](https://academic.oup.com/rfs/article-abstract/34/3/1105/5891182). Review of Financial Studies | Teórico | Adoção e externalidades; projeto 3 |
| R09 | Easley; O'Hara; Basu (2019). [From Mining to Markets: The Evolution of Bitcoin Transaction Fees](https://doi.org/10.1016/j.jfineco.2019.03.004). Journal of Financial Economics | Modelo e evidência | Custos de transação e participação; projeto 1 |
| R10 | Martinazzi; Flori (2020). [The Evolving Topology of the Lightning Network: Centralization, Efficiency, Robustness, Synchronization, and Anonymity](https://doi.org/10.1371/journal.pone.0225966). PLOS ONE | Empírico | Referência inicial de topologia; projeto 1 |
| R11 | Lin; Primicerio; Squartini; Decker; Tessone (2020). [Lightning Network: A Second Path towards Centralisation of the Bitcoin Economy](https://arxiv.org/abs/2002.02819). New Journal of Physics | Empírico | Concentração e modelos nulos; projeto 1 |
| R12 | Valko; Marx Gómez (2025). [Geolocated Lightning Network Topology Snapshots: A Dataset Covering 2019–2023](https://www.nature.com/articles/s41597-025-06413-7). Scientific Data | Artigo de dados | Base pública estruturada; projeto 1 |
| R13 | Valko; Marx Gómez (2026). [Topological and Temporal Stability Analysis of the Lightning Network](https://doi.org/10.1007/s41109-026-00820-4). Applied Network Science | Empírico | Fronteira recente sobre estabilidade; projeto 1 |
| R14 | Morales; Somin; Altshuler; Pentland (2023). [Patterns of User Behavior and Token Adoption on ERC20](https://dspace.mit.edu/entities/publication/9c192aff-3b23-42c2-a924-1bbc79b4054e). SN Computer Science | Empírico | Interações e diversidade de tokens; projeto 3 |
| R15 | Garcia; Tessone; Mavrodiev; Perony (2014). [The Digital Traces of Bubbles: Feedback Cycles between Socio-economic Signals in the Bitcoin Economy](https://www.sg.ethz.ch/publications/2014/garcia2014the-digital-traces/rsif.2014.0623.pdf). Journal of the Royal Society Interface | Empírico | Atenção e sinais sociais agregados; extensão do projeto 3 |
| R16 | Liu; Makarov; Schoar (2026). [Anatomy of a Run: The Terra Luna Crash](https://doi.org/10.1016/j.jfineco.2026.104359). Journal of Financial Economics | Empírico | Observabilidade, concentração e corrida; projeto 2 |
| R17 | Born; Gati; Lambert; Naeem; Pellicani (2026). [Who to Regulate? Identifying Actors within DeFi's Governance](https://www.ecb.europa.eu/pub/pdf/scpwps/ecb.wp3208~051a880042.en.pdf). ECB WP 3208 | Working paper | Concentração e identificação de participantes; projeto 4 |
| R18 | Fan; Shu; Xie (2025; revisão em junho de 2026). [Is There Wisdom Among the DAO Crowd? Evidence from Vote Delegation](https://www.ecgi.global/publications/working-papers/is-there-wisdom-among-the-dao-crowd-evidence-from-vote-delegation). ECGI Finance WP 1077/2025 | Working paper | Delegação e incentivos; projeto 4 |
| R19 | Kumar; Spezzano; Subrahmanian; Faloutsos (2016). [Edge Weight Prediction in Weighted Signed Networks](https://cs.stanford.edu/~srijan/pubs/wsn-icdm16.pdf). IEEE ICDM | Método e aplicação | Origem dos dados de confiança; projeto 5 |
| R20 | Du; Sonawane; Watsky (2025). [In the Shadow of Bank Runs: Lessons from the Silicon Valley Bank Failure and Its Impact on Stablecoins](https://doi.org/10.17016/2380-7172.3958). FEDS Notes | Nota de pesquisa | Cronologia e conexões USDC/DAI; projeto 2 |

**Leitura inicial recomendada:** R01 + R10 + R12 para Lightning; R03 + R16 + R20 para crises; R08 + R14 + R04 + R05 para adoção; R17 + R18 para DAOs; R19 para reputação. R06 torna-se central se o trabalho avançar para um experimento com efeitos sobre vizinhos.

As fontes de dados, links e condições de acesso estão organizados separadamente em `catalogo_fontes_dados.csv`. Documentação acessível e repositório anunciado não equivalem a download e validação do conteúdo. Os arquivos SNAP OTC/Alpha foram efetivamente auditados no aprofundamento do projeto 5; as demais fontes continuam dependendo de piloto para confirmar cobertura, integridade e adequação à pergunta escolhida.
