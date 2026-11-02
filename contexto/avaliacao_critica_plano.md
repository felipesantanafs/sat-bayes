# Parecer sobre o plano: redes, previsão de perdas e inferência bayesiana

Data da avaliação: 2 de novembro de 2026.

**Desdobramento:** o [plano consolidado de execução em R](plano_execucao_R.md) incorpora este parecer e fixa as escolhas operacionais vigentes. Este documento permanece como avaliação do desenho anterior.

**Parecer: revisões substanciais antes da execução integral.** A proposta é defensável como pesquisa de previsão probabilística de perdas usando atributos de redes de dependência entre retornos. O desenho atual não permite concluir que identificou transmissão causal de confiança, contágio financeiro ou risco sistêmico. A álgebra central é válida sob condições específicas, mas a interpretação econômica, a mensuração e a validação ainda precisam ser conectadas.

Este parecer distingue o que está escrito, o que a literatura sustenta e as alterações que proponho. As especificações e janelas sugeridas são escolhas de desenho a validar no piloto; não são resultados empíricos nem exigências universais da literatura.

Interpretei “modelagem de dispersão” como difusão ou propagação de choques em redes, conforme o conteúdo do plano; modelos físicos de dispersão espacial não são o objeto desta proposta.

## 1. Documentos examinados e alcance

O plano principal está em [contexto.txt](contexto.txt), especialmente nas linhas 1–94 e 302–313. O arquivo contém uma conversa com versões sucessivas da proposta, instruções de coleta e uma promessa de código. A lista de ativos está em [moedas.txt](moedas.txt).

Inventariei os três livros, os sete conjuntos de aulas disponíveis, os treze conjuntos de slides de Sadler, o guia de QGIS e o documento [contexto_desenho_empirico_blockchain.md](../referencias/contexto_desenho_empirico_blockchain.md). Nos livros e slides, a leitura foi temática: sumários e trechos pertinentes a representação, centralidade, complementaridades, aprendizado, difusão e mensuração. Não se trata de leitura integral dos três livros nem de revisão sistemática exaustiva da literatura.

A busca externa priorizou artigos originais, páginas dos periódicos, manuscritos dos autores e documentação oficial. Quando o texto integral editorial estava restrito, usei o resumo e, quando disponível, a versão dos autores. Não atribuo a um resumo uma verificação de todos os resultados do artigo. As referências bibliográficas selecionadas estão na seção 11 e em [bibliografia_avaliacao.csv](bibliografia_avaliacao.csv).

**Limite material:** não há base de dados nem programa Python completo nesta cópia do projeto. A linha 252 de `contexto.txt` contém somente um fragmento concatenado de cabeçalho e imports. Logo, é possível avaliar o desenho e suas inconsistências, mas não certificar funcionamento, ausência de vazamento no código, cobertura dos ativos ou desempenho dos modelos.

## 2. O que está correto e deve ser preservado

1. **Pergunta sobre informação adicional das redes.** Verificar se características da rede melhoram previsões além de atributos individuais é uma pergunta empiricamente testável.
2. **Separação entre nós e pesos.** Representar ativos por nós e dependências por arestas ponderadas é compatível com análise de redes, desde que a ligação observada seja definida.
3. **Estabilidade da inversa.** Para `W` não negativa e `β ≥ 0`, a condição `βρ(W) < 1` garante a expansão convergente e não negativa de `(I − βW)⁻¹`.
4. **Naive Bayes como referência simples.** A fórmula da classificação está correta sob a hipótese de independência condicional dos atributos. Compará-lo com regressão logística é pertinente.
5. **Comparações incrementais e teste temporal.** Comparar informações individuais, estresse e rede é uma boa estrutura inicial de avaliação.
6. **Métricas probabilísticas.** Brier Score, PR-AUC e ROC-AUC são úteis, com funções distintas; o Brier é particularmente relevante para previsões de probabilidade [R15].
7. **Ressalvas já reconhecidas.** As linhas 305–309 distinguem estresse de confiança e associação de causalidade. Isso é um avanço real. O problema é que essas ressalvas ainda não foram incorporadas ao título, à definição do desfecho e às afirmações principais.

## 3. Problemas que precisam ser corrigidos

| Gravidade | Ponto do plano | Diagnóstico | Correção necessária |
| --- | --- | --- | --- |
| Crítica | Título e objetivo, linhas 3–7 | Confiança, contágio e risco sistêmico excedem os objetos medidos | Delimitar previsão de perdas ou acrescentar dados e identificação compatíveis com cada mecanismo |
| Crítica | Rede, linhas 14–26 | Pares negociáveis, correlações e exposições financeiras representam relações diferentes | Escolher uma camada principal e definir sua interpretação |
| Crítica | Desfecho, linhas 28–39 | Perda acima de 5% não identifica contágio | Nomear o desfecho como perda futura e definir separadamente qualquer teste de transmissão |
| Crítica | Validação, linha 82 | Ordem cronológica sozinha não resolve rótulos futuros sobrepostos | Separar por tempo para todos os ativos e excluir rótulos ainda desconhecidos na data de ajuste |
| Alta | Equação, linhas 16–26 | Multiplicador estático não especifica velocidade nem trajetória da difusão | Derivar o equilíbrio ou formular dinâmica e variáveis observáveis |
| Alta | Centralidade, linha 55 | Katz geral não equivale à exposição a um choque específico no BTC | Separar centralidade global de resposta à origem BTC |
| Alta | Modelo bayesiano, linhas 41–62 e 94 | GaussianNB usual não fornece posterior dos parâmetros ou modelo de aprendizado dos investidores | Delimitar classificação ou acrescentar modelo bayesiano com priors e diagnóstico |
| Alta | Eventos, linha 7 | Documentação de um evento não prova exogeneidade | Especificar cronologia, exposição anterior, contrafactual e hipóteses de identificação |
| Alta | Controles e referências, linhas 52–62 | Rede pode resumir apenas exposição ao fator de mercado/BTC | Incluir referências competitivas com fatores, betas e persistência de risco |
| Alta | Probabilidades e métricas, linhas 65–84 | Discriminação não assegura calibração; falta incerteza da diferença entre modelos | Adicionar calibração, log loss e comparação pareada com dependência temporal |
| Alta | Universo, linhas 128, 156, 238, 262 | Misturam-se todos os ativos, 30 ativos e duas datas iniciais; lista atual tem 17 ativos | Fixar população-alvo, elegibilidade histórica e regra de composição |
| Alta | Entregas computacionais, linhas 250–298 | Código e arquivos anunciados não estão presentes | Tratar implementação e auditoria como etapas ainda pendentes |
| Moderada | Contribuição, linhas 85–94 | Combinação de rede com algoritmo não estabelece originalidade | Definir lacuna em relação a estudos próximos e teste incremental específico |

### 3.1. Confiança precisa de uma mensuração própria

O plano chama uma variação negativa de um índice de “choque de confiança”, mas não define esse índice. Retornos, volatilidade e volume são observáveis de mercado; não revelam, isoladamente, crenças sobre solvência, segurança da corretora ou valor futuro do Bitcoin.

Se o índice for construído com queda e volatilidade do BTC, a interpretação defensável será **estresse do BTC**. Seu uso defasado pode ser útil para prever outras perdas. Isso não estabelece um canal de confiança. Se usar dados posteriores à previsão, haverá ainda vazamento.

Para manter “confiança”, será necessário definir o construto, fonte independente, protocolo de construção e horário de disponibilidade, além de avaliar validade e ruído. Sentimento de notícias ou fluxos podem complementar a mensuração, mas também respondem aos preços e não resolvem identificação automaticamente. Modelos de aprendizado social tratam de agentes, sinais, observações e decisões; essa estrutura aparece nas aulas 07–08 e em Acemoglu et al. [R07]. A passagem de agentes para ativos precisa de uma hipótese de agregação que hoje está ausente.

### 3.2. Perda, interdependência e contágio são objetos distintos

Uma queda simultânea de BTC e ETH pode refletir um fator agregado, reavaliação macroeconômica, liquidação de posições ou transmissão entre mercados. A classificação `Y = 1` não distingue essas explicações.

Forbes e Rigobon mostram por que mudanças de volatilidade podem distorcer comparações de correlação e testes de contágio [R08]. Seu conceito de aumento de comovimento após um choque é uma definição operacional importante, mas não a única possível. O trabalho deve declarar qual definição adota e qual evidência a diferencia de interdependência habitual.

O problema da reflexão de Manski e os resultados de identificação de Bramoullé et al. ajudam a organizar a distinção entre efeitos dos vizinhos, características dos vizinhos e fatores comuns [R09–R10]. As garantias desses modelos dependem de hipóteses específicas; não são automaticamente transferidas para preços de ativos.

**Mudança recomendada:** substituir “probabilidade de contágio” por “probabilidade de perda superior a 5% nas próximas 24 horas” no núcleo preditivo. Reservar “contágio” para uma análise própria de transmissão, com hipótese e contraste definidos.

### 3.3. A rede precisa ter uma única definição principal

| Construção | A aresta registra | Uso defensável | Limite |
| --- | --- | --- | --- |
| Correlação de retornos | Comovimento estatístico | Diversificação, estrutura de dependência e atributos preditivos | Não observa obrigações financeiras nem direção causal |
| Disponibilidade de par na Binance | Possibilidade de conversão entre ativos | Topologia de negociação e rotas de conversão | Não revela quem mantém exposição ou transfere perdas |
| VAR e decomposição da variância de previsão | Conectividade estatística orientada segundo o modelo | Direção de contribuições à incerteza de previsão | Direção estatística não estabelece causalidade estrutural |
| Reservas, colateral ou obrigações | Exposição econômica reconstruída | Mecanismos financeiros de transmissão | Exige dados adicionais e reconstrução institucional |

Diebold e Yilmaz fundamentam a terceira alternativa [R11]. Bardoscia et al. revisam diferentes representações de redes financeiras e mecanismos de contágio [R05]. Para a base OHLCV proposta, recomendo a primeira alternativa como núcleo inicial. Denominar `W` como **rede de dependência entre retornos** é adequado.

O documento local `contexto_desenho_empirico_blockchain.md`, seção 3, já explicita que correlações não identificam quem deve a quem. Ele deve orientar a redação do plano da pasta `contexto`.

Também é necessário:

- Fixar se `W_ij` representa influência de `j` sobre `i` ou ligação de `i` para `j`; isso altera multiplicações e centralidades dirigidas.
- Fixar diagonal, janela, frequência de atualização, tratamento de ausências e regra de esparsificação.
- Se houver truncamento de correlações negativas, declarar que se estuda comovimento positivo. Usar valor absoluto mistura associação positiva e proteção potencial.
- Em intermediação ponderada, transformar similaridade em distância/custo de modo justificado. Usar a correlação diretamente como comprimento faz ligações fortes parecerem mais longas.
- Avaliar sensibilidade à definição de aresta; uma rede quase completa com pesos semelhantes pode produzir pouca informação topológica adicional.

### 3.4. A fórmula está correta, mas a interpretação exige condições adicionais

A expressão do plano resolve o sistema:

\[
c=\alpha+\beta Wc.
\]

Ela pode representar um equilíbrio linear de complementaridades. Isso está diretamente relacionado à seção 9.5.2 de Jackson, às páginas extraídas 25–27 da aula 06 e às páginas 54–58 de Sadler 06. Ballester, Calvó-Armengol e Zenou fornecem o fundamento de jogos em rede [R01].

Para `W ≥ 0` e `β ≥ 0`, sob `βρ(W) < 1`:

\[
(I-\beta W)^{-1}=I+\beta W+\beta^2W^2+\cdots.
\]

Cada potência agrega **passeios na rede**, que podem repetir nós; não apenas caminhos simples. A condição garante a interpretação convergente do multiplicador. A mera invertibilidade é uma condição mais fraca e não basta para essa interpretação.

Há quatro lacunas no uso econômico proposto:

1. **Escala:** uma solução real não é automaticamente uma probabilidade entre 0 e 1. Se `c` for um índice, explicitar unidade e escala; se for crença probabilística, garantir os limites.
2. **Observação:** o plano não mede `c` nem `α`. Sem equação de mensuração e restrições adicionais, não há estratégia para estimar `β` como transmissão de confiança.
3. **Temporalidade:** a expressão é estática. Uma possível dinâmica seria `c_s = α + βWc_{s-1}`, com `α` e `W` fixas durante o ajuste. A condição espectral garante convergência nesse caso. O plano precisa justificar o que significa um passo `s` e como ele se relaciona às horas observadas.
4. **Vínculo empírico:** calcular a inversa ou uma centralidade e inseri-la no classificador não estima automaticamente os parâmetros econômicos que geraram a rede.

Acemoglu et al. demonstram propagação e agregação por vínculos de insumo-produto [R02]. A aplicação às criptomoedas precisa de uma analogia econômica explicitada; o artigo não valida substituir vínculos produtivos por correlações de preços.

**Diferença para DeGroot:** a aula 08 utiliza `p_s = Tp_{s-1}`, com `T` estocástica por linhas. Nesse caso, `T1 = 1` e `ρ(T) = 1`; o consenso preserva o modo unitário. Não se pode usar `(I − T)⁻¹` como se esse fosse o mesmo modelo. Uma dinâmica ancorada, `p_s = (1 − λ)a + λTp_{s-1}`, com `0 ≤ λ < 1`, admite solução `(1 − λ)(I − λT)⁻¹a`. Essa é uma especificação adicional, não uma equação já estimada pelo plano.

### 3.5. Centralidade global não é exposição específica ao BTC

Definindo `K = (I − βW)⁻¹1`, a centralidade agrega respostas a uma entrada homogênea em todos os nós. Para uma alteração somente no componente BTC de `α`, mantendo `W` fixa, a resposta é:

\[
\Delta c=\delta(I-\beta W)^{-1}e_{BTC}.
\]

Portanto, o elemento relevante para a resposta do ativo `i` é a entrada `(i,BTC)` do multiplicador. Para isolar efeitos que percorrem pelo menos uma ligação, usar `[(I − βW)⁻¹ − I]e_BTC`. Esses resultados são consequências algébricas do modelo; não são evidência de que o canal exista nos dados.

**Cuidado com a normalização:** se `W1 = 1`, então, para `0 ≤ β < 1`,

\[
(I-\beta W)^{-1}1=\frac{1}{1-\beta}1.
\]

Nesse caso, essa definição de Katz é constante entre os ativos, e a soma dos pesos recebidos em cada linha também é constante. A conclusão vale para a orientação e a normalização escritas; usar a transposta ou normalizar colunas produz outro objeto. O plano ainda não escolheu a normalização: trata-se de um risco a prevenir, não de um erro de implementação já constatado.

Recomendo guardar a matriz de intensidade original e a matriz normalizada separadamente. Para Katz global, uma escala comum que preserve heterogeneidade pode ser mais apropriada; para agregação de estresse dos vizinhos, a normalização por linhas pode ter interpretação útil. Validar numericamente estabilidade, variância da centralidade e orientação antes de treinar modelos.

### 3.6. Naive Bayes, inferência bayesiana e aprendizado social precisam ser separados

A aplicação do teorema de Bayes à classificação é legítima. Entretanto, `GaussianNB` usual estima médias, variâncias e frequências de classe e as insere na regra de classificação; isso não fornece, por si só, uma posterior sobre parâmetros de transmissão em rede. A documentação oficial descreve a hipótese de independência e as limitações das probabilidades produzidas [D02].

As centralidades, força dos vínculos, volatilidade e exposição ao BTC provavelmente compartilham informação. A violação da independência não torna o algoritmo proibido; exige avaliar as consequências fora da amostra. A literatura de calibração documenta que Naive Bayes pode produzir probabilidades excessivamente extremas [R16].

Se a inferência bayesiana for parte central da contribuição, deve existir uma distribuição a priori e uma verossimilhança explícitas:

\[
p(\vartheta\mid D)\propto p(D\mid\vartheta)p(\vartheta),
\qquad
p(\widetilde Y=1\mid D,X)=\int p(\widetilde Y=1\mid X,\vartheta)p(\vartheta\mid D)d\vartheta.
\]

Priors e posterior preditiva permitem representar incerteza dos parâmetros. Eles não resolvem fatores omitidos, erro de mensuração ou causalidade. Gelman et al. discutem regularização por priors em regressão logística [R17]; Gabry et al. fundamentam um fluxo de construção, checagem e avaliação bayesiana [R18].

### 3.7. Validação temporal: o horizonte do rótulo muda a separação

Definir o alvo, por exemplo, como:

\[
R_{i,t}^{(24)}=\frac{P_{i,t+24h}}{P_{i,t}}-1,
\qquad Y_{i,t}=1\{R_{i,t}^{(24)}<-0{,}05\}.
\]

Aqui `t` é o horário da previsão; o rótulo só fica conhecido em `t+24h`. A variável mede perda entre os preços inicial e final, não a maior queda intraperíodo. Com retornos logarítmicos, o limiar equivalente é `log(0,95)`, e não exatamente `−0,05`.

Se o ajuste termina em `T`, só podem entrar rótulos cujo término seja observável até `T`, respeitando também o atraso da fonte. Exemplo: uma previsão originada às 12h de segunda e avaliada até 12h de terça não pode ser usada para ajustar um modelo às 0h de terça. Isso gera uma exclusão de cerca de 24 horas nas fronteiras; os timestamps exatos definem a regra.

Todos os ativos devem compartilhar as mesmas fronteiras temporais. Dividir linhas aleatoriamente, ou aplicar um separador temporal sobre uma tabela ordenada primeiro por ativo, pode misturar o mesmo choque entre treino e teste.

Dentro do teste, alvos horários de 24 horas continuam sobrepostos. Isso não impede avaliação preditiva, mas cria dependência nos erros e reduz a quantidade efetiva de informação. Usar diferenças de perdas agregadas por horário e inferência por blocos temporais suficientemente longos, com sensibilidade ao tamanho dos blocos; um único episódio não vira centenas de choques por ter centenas de ativos. Avaliar também origens diárias sem sobreposição, mantendo explícita a mudança de frequência.

Janelas históricas de atributos podem ser compartilhadas entre treino e teste quando só contêm informação já conhecida; esse compartilhamento não exige automaticamente excluir toda a janela de correlação. O que precisa ser bloqueado é acesso a dados futuros e a rótulos ainda não observados. O princípio de avaliar o futuro usando apenas o passado está alinhado à literatura de leave-future-out [R19].

Ajustar seleção de atributos, hiperparâmetros, imputação, padronização e calibração somente no treinamento e na validação anteriores. Durante o teste, atualizar a rede com preços já observados é permitido se isso fizer parte do protocolo operacional; usar rótulos futuros para escolher a rede não é.

### 3.8. Ganho de rede precisa superar explicações simples

O estudo de Liu, Tsyvinski e Wu encontra fatores de mercado, tamanho e momento relevantes para retornos de criptomoedas [R12]. Isso não prova que esses fatores expliquem perdas extremas, mas exige confrontar a rede com explicações de risco comuns.

Adicionar uma rede a uma referência fraca não demonstra que a topologia oferece informação própria. Uma centralidade de correlação pode resumir beta de mercado, beta de BTC ou volatilidade. Comparar atributos de rede com controles desse tipo, e considerar redes de resíduos estimados apenas com dados passados. A remoção de fatores também altera o objeto e pode remover parte do canal de interesse; apresentar a comparação como sensibilidade, não como identificação causal automática.

O título não deve prometer que a posição “influencia” a perda quando a evidência será somente associação preditiva. Usar “acrescenta informação para prever” é uma formulação compatível com o desenho.

### 3.9. Risco sistêmico exige um resultado agregado

Probabilidades marginais de perdas individuais não determinam a distribuição conjunta dos eventos. Mesmo conhecendo `p_i`, a probabilidade de muitos ativos caírem juntos continua dependendo das relações entre eles.

É possível definir `S_t = Σ_i ω_iY_it`, com pesos predeterminados, e avaliar perdas amplas ou excedência de uma fração de ativos. Nesse caso, `E[S_t | informação] = Σ_i ω_ip_it`, mas essa igualdade não fornece `P(S_t > q | informação)`. Para probabilidades de eventos conjuntos, é necessário um modelo conjunto ou uma estimação específica desse desfecho agregado.

Haldane e May discutem estabilidade do sistema e cascatas em redes bancárias [R04]; Acemoglu, Ozdaglar e Tahbaz-Salehi mostram que a relação entre conectividade e estabilidade depende da natureza e intensidade dos choques [R03]. Não há fundamento geral para impor que maior centralidade sempre aumentará perdas. Para o núcleo sugerido, recomendo retirar “risco sistêmico” do título e tratar o tema como motivação ou extensão delimitada.

## 4. Coerência com os materiais locais

| Material | Trecho pertinente | Avaliação do encaixe |
| --- | --- | --- |
| Jackson, *Social and Economic Networks* (2008) | Cap. 2; caps. 7–8; seção 9.5.2, pp. impressas 290–292 | Sustenta métricas, distinção entre difusão e aprendizado e equilíbrio de complementaridades. Não oferece uma mensuração de confiança em criptomoedas |
| Newman, *Networks*, 2ª ed. (2018) | Caps. 6–7; seção 7.1.3, pp. 163–164; caps. 15–17 | Sustenta matriz, Katz, condição espectral, resiliência e dinâmica. Uma analogia epidêmica exige estados e transições próprios |
| Easley e Kleinberg, *Networks, Crowds, and Markets* (2010) | Caps. 4, 16, 19 e 21; cap. 19, pp. 497–499 | Distingue seleção, influência, efeitos informacionais, incentivos e epidemias. Queda de preço não equivale automaticamente a adoção ou infecção |
| Aulas 01–02 | Representação; aula 02, páginas extraídas 8–9 | Base adequada para métricas, orientação e distinção entre Katz e PageRank |
| Aulas 04–05 | Grafos aleatórios e formação estratégica | Podem apoiar referências de estrutura; não é necessário encaixar esses modelos se a pergunta não estudar formação de vínculos |
| Aula 06 | Páginas extraídas 25–27 | É a ligação mais direta com a inversa usada no plano; requer identificar ação, incentivos e pesos |
| Aulas 07–08 | Cascatas informacionais, limiares e DeGroot | Adequadas para distinguir mecanismos; não demonstram que investidores seguem o Naive Bayes do pesquisador |
| Sadler 01–05 | Introdução, jogos, congestionamento e externalidades | Contexto teórico; congestionamento não é identificado por OHLCV de ativos |
| Sadler 06 e 08 | Complementaridades; cadeias produtivas e agregação | Fundamentação próxima do multiplicador, com cautela na transposição do mecanismo |
| Sadler 07 e 13 | Cooperação e formação de rede | Relevância secundária para a pergunta preditiva; maior para reputação ou escolha de parceiros |
| Sadler 09–10 | Sinais, ações e aprendizado social | Apoia a crítica à ausência de agentes e crenças observáveis |
| Sadler 11–12 | Coordenação, limiares, campo médio e percolação | Exige processo de transição explícito; não autoriza tratar classificações de perdas como propagação demonstrada |
| Guia de QGIS/PIB | Mapas municipais | Não contribui diretamente ao desenho financeiro sem uma unidade geográfica válida |

Os números de página impressa e os marcadores `=== [pagina ...] ===` dos TXT podem diferir. Há fórmulas com caracteres ou partes ausentes na extração, como na apresentação de Katz da aula 02. Para a redação final, conferir as equações no original quando houver ambiguidade e usar o livro ou o artigo como referência formal.

O documento local sobre desenhos em blockchain é mais explícito que o plano em vários limites de mensuração e identificação. Seu projeto 2 oferece uma alternativa para exposição anterior a uma crise de stablecoin. Isso é uma alternativa de dados e pergunta, não uma exigência para concluir o projeto com a Binance. Referências e arquivos auxiliares mencionados naquele documento não devem ser tratados como entregas existentes sem verificar sua presença e conteúdo.

## 5. Desenho principal recomendado

**Título:** “Redes de dependência entre criptoativos e previsão probabilística de perdas: evidência com dados históricos da Binance”.

**Pergunta:** “Atributos de uma rede estimada exclusivamente com informação passada melhoram a previsão de perdas superiores a 5% em 24 horas, além de volatilidade, liquidez e exposição aos fatores de mercado e ao Bitcoin?”

**Unidade:** ativo–horário de previsão. **População:** ativos spot elegíveis da Binance segundo regra histórica documentada. **Resultado:** ganho preditivo fora da amostra, com avaliação de calibração e estabilidade entre períodos.

Hipóteses propostas:

- H1: a adição do bloco de rede melhora Brier Score ou log loss em relação ao modelo com os mesmos controles sem rede.
- H2: exposição específica ao BTC e sua interação com estresse observado do BTC acrescentam informação além do beta histórico do BTC.
- H3: o ganho, se existir, mantém alguma estabilidade em janelas e subperíodos previamente definidos.

Não fixar o sinal de todas as centralidades como positivo por princípio. A interpretação econômica dependerá do tipo de ligação e dos controles.

### 5.1. Universo e dados

Resolver primeiro as alternativas conflitantes do documento: todos os ativos, trinta ativos ou os dezessete nomes de `moedas.txt`; início em 2020 ou primeira disponibilidade desde 2017. Minha recomendação é começar com um piloto pequeno e uma regra de elegibilidade que possa ser ampliada sem selecionar vencedores retrospectivamente.

Se a lista atual for uma escolha substantiva, declarar que se trata de uma amostra intencional atual e limitar a generalização. Ela inclui ativos com funções e referências distintas, como MUSD e PAXG; verificar documentação e separar grupos na análise. Não presumir que todos estejam listados na Binance, tenham par USDT ou histórico suficiente. A presença de um ticker na lista não comprova disponibilidade.

Uma população histórica exige catálogo de listagens, deslistagens, migrações, mudanças de ticker e pares disponíveis em cada momento. Consulta atual de instrumentos não substitui catálogo histórico. Exigir sobrevivência até o fim da amostra introduz seleção. Se os deslistados não puderem ser recuperados, declarar essa cobertura e avaliar seu efeito; não afirmar que o problema foi resolvido.

Usar painel não balanceado e entrada após histórico mínimo, sem preencher preços anteriores à listagem. Regras iniciais possíveis: pelo menos 90 dias observados e cobertura mínima no período anterior; os valores finais devem ser fixados após o piloto, sem otimização pelo teste final. Diferenciar ausência de negociação, suspensão e ausência do arquivo.

A documentação da Binance confirma arquivos diários e mensais, campos de OHLCV e timestamps spot em microssegundos desde 01/01/2025 [D01]. Isso sustenta a estratégia de coleta, mas não certifica a integridade de todo o período. O catálogo efetivamente extraído deve definir início e fim por par. Manter UTC, hashes/checksums, manifesto de origem e versão do tratamento.

Para retornos em USDT, reconhecer que o numerário também pode variar frente ao dólar. Se converter para USD, usar taxa histórica; não fixar toda stablecoin em US$ 1 durante eventos. Não somar volumes de moedas-base distintas como se tivessem a mesma unidade. O volume agressor identifica lado da execução, não identidade nem confiança dos investidores.

Excluir as últimas 24 horas da amostra de alvos quando não houver observação posterior suficiente. Se a coleta terminar em 31/10/2026, previsões originadas no fim dessa data exigem preços de 01/11/2026 para avaliação.

### 5.2. Construção da rede e dos atributos

Uma especificação inicial simples, a validar, seria:

1. Calcular retornos horários somente com candles encerrados e informação disponível na origem da previsão.
2. Estimar correlações em janela móvel de 90 dias, com mínimo comum de observações, excluindo a diagonal. Avaliar 30 e 180 dias como sensibilidade, sem escolher a janela pelo teste final.
3. Usar uma regra previamente definida de retenção de correlações positivas, calibrada no desenvolvimento. Guardar a matriz densa e a versão filtrada; o filtro não transforma associação em exposição causal.
4. Recalcular a rede em frequência diária no piloto e avaliar se atualização horária traz benefício suficiente para justificar o custo.
5. Extrair força dos vínculos, Katz com escala/atenuação explícitas e exposição específica ao BTC. Intermediação fica como atributo complementar, condicionado à distância escolhida.
6. Repetir como sensibilidade em resíduos de fatores estimados com informação passada. Auditar se as métricas diferem de volatilidade e betas simples.

Para estresse observado, uma opção transparente é `s_BTC,t = max(0, −R_BTC,t^(passado))`, eventualmente dividido por volatilidade estimada antes ou até `t`. Definir precisamente o período passado e não chamar essa variável de confiança.

Uma medida de exposição ao BTC pode ser `q_i,t = [(I − κW_t)⁻¹ − I]_(i,BTC)`, com `κ` definido na fase de desenvolvimento e estabilidade verificada para cada matriz. Usar `q_i,t × s_BTC,t` como atributo preditivo é uma aplicação do multiplicador como representação; não significa que `κ` seja o parâmetro econômico de transmissão estimado.

Liquidez pode incluir volume em numerário comum e uma adaptação documentada da medida de Amihud [R20]. A medida original foi desenvolvida em outro mercado e frequência: justificar a adaptação e tratar volume zero. OHLCV não substitui observação de spread e profundidade do livro de ofertas.

### 5.3. Comparação de modelos

| Modelo | Informação | Função |
| --- | --- | --- |
| M0 | Frequência histórica da perda, global e/ou por ativo, estimada no treino | Referência mínima de probabilidade |
| M1 | Retornos passados, volatilidade, liquidez, idade/listagem e persistência | Risco individual |
| M2 | M1 + BTC, mercado, betas históricos e estresse observado | Referência competitiva com fatores comuns |
| M3 | M2 + atributos da rede | Teste principal do ganho da rede |
| M4 | M3 + interação exposição ao BTC × estresse do BTC | Teste específico de exposição em períodos de estresse |

Estimar M1–M4 com GaussianNB e regressão logística regularizada, mantendo população, alvos, datas e acesso à informação iguais. Para comparar diretamente GaussianNB com logística, usar versões com atributos comparáveis; efeitos específicos por ativo podem constituir uma comparação adicional claramente identificada. Incluir transformação de variáveis muito assimétricas quando pertinente, escolhida no desenvolvimento.

Esse desenho cruza **informações** e **algoritmos**. Assim, um ganho não fica confundido com a troca simultânea de rede, amostra, classificador e ajuste. Fazer ablações separando centralidades globais, exposição ao BTC e estresse dos vizinhos. Não selecionar um grande conjunto de combinações pelo mesmo teste final.

### 5.4. Avaliação e critério de sucesso

Separar desenvolvimento, validação temporal e teste final intocado, todos em blocos comuns aos ativos. As datas exatas dependem da cobertura e do número de eventos; devem ser registradas antes da comparação final. Dentro do desenvolvimento, usar origens de previsão sucessivas e a exclusão dos rótulos não observáveis descrita na seção 3.7.

**Métrica principal proposta:** diferença pareada de Brier Score entre M3 e M2. **Complementos:** log loss, PR-AUC, ROC-AUC, curva de calibração e resultados por ativo/período. Fixar como a média trata ativos com históricos longos e curtos: média por observação, média por ativo e ponderação econômica respondem a perguntas distintas.

O Brier combina aspectos de calibração e discriminação; isoladamente não certifica calibração. Para PR-AUC, explicitar se foi usada average precision ou integração da curva, e informar prevalência. F1 depende de um limiar de decisão, escolhido na validação, e não mede qualidade das probabilidades. Se um bloco tiver somente uma classe, algumas métricas não serão definidas; não preencher artificialmente.

Calibração por sigmoide ou isotônica deve usar previsões de um bloco anterior reservado ou previsões fora da amostra geradas temporalmente, com dados suficientes. Nunca calibrar no próprio teste. Evitar reamostragem ou pesos de classe sem avaliar seu efeito na prevalência e na interpretação probabilística.

Reportar a diferença entre modelos no mesmo conjunto de previsões e sua incerteza considerando dependência entre horários e ativos. Redes reconfiguradas com características preservadas podem funcionar como referência de sensibilidade à topologia. Elas não criam um teste causal válido por randomização dos vínculos observados.

O projeto será informativo mesmo se o ganho de rede for pequeno, nulo ou instável. O resultado cientificamente correto será descrever a magnitude e seus limites, sem transformar ausência de ganho preditivo em prova de ausência de mecanismos econômicos.

## 6. Extensão de inferência bayesiana

Se o objetivo incluir posterior de parâmetros e comparação explícita de incerteza, recomendo uma regressão logística bayesiana hierárquica como extensão manejável:

\[
Y_{i,t}\mid p_{i,t}\sim Bernoulli(p_{i,t}),
\]

\[
logit(p_{i,t})=a_i+\gamma'X_{i,t}+\theta q_{i,t}s_{BTC,t}
+\psi\sum_{j\ne i}W_{ij,t}z_{j,t}+v_t.
\]

Aqui `X` contém os controles e atributos previamente definidos; `z_j,t` mede estresse passado já observado, nunca o rótulo futuro dos vizinhos; `a_i` permite heterogeneidade por ativo; `v_t` representa um componente temporal comum. Definir uma dinâmica para `v_t` e prever seu valor futuro sem condicionar ao desfecho do teste. A inclusão desse componente aumenta a complexidade e deve ser avaliada no piloto.

Exemplos iniciais de priors, com atributos contínuos padronizados no treino: `a_i ~ N(μ_a, σ_a²)`, `μ_a ~ N(0, 2,5²)`, `σ_a ~ HalfNormal(1)` e coeficientes de inclinação `~ N(0, 0,5²)`. São escolhas propostas, não os priors específicos recomendados em [R17]. Verificar por simulação a priori se geram frequências plausíveis de perdas e testar sensibilidade; ajustar o prior do intercepto se houver conhecimento anterior documentado sobre raridade.

Realizar checagens preditivas a priori e posteriores, diagnóstico de convergência e tamanho efetivo das amostras; em HMC, examinar divergências. Avaliar a posterior preditiva em blocos futuros. Intervalos resultantes são condicionais ao modelo, aos dados e, nesse exemplo, à rede estimada tratada como conhecida. Propagar incerteza de `W` exigiria uma camada adicional ou reconstruções que respeitem a sequência temporal.

Uma verossimilhança que presume independência condicional entre ativos e horas precisa ser confrontada com a dependência residual, sobretudo quando os alvos de 24 horas se sobrepõem. Priors hierárquicos não eliminam essa dependência. Começar essa extensão com origens diárias não sobrepostas reduz uma fonte do problema, mas não garante independência.

**Limite da extensão:** esse modelo estima associação condicional e previsão com incerteza. Um coeficiente de estresse dos vizinhos não se torna um parâmetro causal de difusão por receber uma distribuição posterior. Para estudar dinâmica de transmissão de retornos, um VAR/BVAR ou modelo autorregressivo em rede com defasagens explicitadas é outra extensão; sua identificação estrutural e suas condições de estabilidade precisam ser especificadas separadamente.

## 7. Se a prioridade for identificar transmissão de um choque

Nesse caso, o desenho precisa mudar antes da estimação. Escolher um evento documentado e uma exposição econômica anterior é um começo. É necessário explicar por que unidades mais expostas teriam trajetórias comparáveis às menos expostas na ausência do evento e quais canais concorrentes existem.

Uma especificação orientadora para eventos seria:

\[
y_{it}=a_i+\tau_t+\sum_{k\ne-1}\delta_k E_i^{pre}1\{t-T_0=k\}
+controles+\varepsilon_{it}.
\]

`E_i^pre` deve ser definido antes do evento e ligado ao mecanismo. O efeito médio do evento é absorvido por `τ_t`; a identificação vem da resposta diferencial por exposição. Incluir exposição indireta demanda uma regra própria e atenção à colinearidade com exposição direta.

Verificar cronologia e antecipação, suporte comum, tendências anteriores, eventos simultâneos e sensibilidade a janelas. Esses exercícios ajudam a avaliar a credibilidade, mas não provam as hipóteses causais. Em interferência de rede, o grupo menos exposto também pode ser afetado.

Um episódio da Binance pode ser resposta endógena ao mesmo estresse que afeta os ativos. Choque da corretora também não equivale a choque específico do BTC. Usar preço do BNB como única medida de estresse da Binance traz canais próprios do token e relações mecânicas. A nota local do projeto USDC é uma alternativa para observar exposições concretas; requer nova base e outra delimitação.

## 8. Originalidade e seleção de referências

Já existem estudos de conectividade entre criptomoedas, como Ji et al. [R13], e de redes de correlação, centralidades e posição do Bitcoin, como Będowska-Sójka et al. [R14]. Portanto, construir uma rede e calcular centralidades não basta para afirmar novidade. A busca não estabelece que inexiste um trabalho com a mesma combinação exata de atributos e Naive Bayes.

Uma contribuição plausível seria avaliar **ganho probabilístico e calibração de atributos de rede além de fatores comuns**, com construção histórica sem informação futura e documentação de entradas e saídas da amostra. Outra seria comparar centralidade geral e exposição específica ao BTC sob estresse. A originalidade final depende de uma revisão focalizada dos estudos mais próximos.

Nature e Econometrica entram pela pertinência, não como um requisito de prestígio. O artigo de Haldane e May é uma *Perspective* na Nature, enquanto Bardoscia et al. é uma revisão na Nature Reviews Physics, periódico distinto. Artigos no domínio `nature.com`, como os de Scientific Reports, não são automaticamente artigos da Nature. Journal of Finance, Journal of Econometrics, Review of Economic Studies, JASA e Annals of Applied Statistics são diretamente pertinentes aos problemas do desenho.

Não foi realizado ranking bibliométrico de autores, revistas ou artigos. As prioridades abaixo indicam utilidade para este projeto.

## 9. Sequência de execução revisada

| Etapa | Entrega | Condição para avançar |
| --- | --- | --- |
| 1. Delimitação | Protocolo com pergunta, população, alvo, rede, hipóteses e alcance inferencial | Cada conceito tem observável ou hipótese explícita; título compatível |
| 2. Piloto de cobertura | Catálogo por ativo/par e auditoria de pequenos arquivos de épocas diferentes | Datas, unidades, lacunas, elegibilidade e mudanças de timestamp compreendidas |
| 3. Painel e rede | Dados brutos preservados, painel e snapshots reproduzíveis | Informação de cada atributo disponível até a origem da previsão; centralidades não degeneradas |
| 4. Referências preditivas | M0–M2 e protocolo de ajuste temporal | Rótulos observáveis no ajuste, amostra comum e prevalência suficiente |
| 5. Teste de rede | M3–M4, ablações e teste final | Comparação pareada, calibração e incerteza documentadas |
| 6. Robustez | Janelas, fatores, numerário, heterogeneidade, cobertura e dependência | Conclusões não dependem de uma escolha isolada sem que isso seja declarado |
| 7. Extensão opcional | Modelo bayesiano ou estudo de evento | Motivação própria, dados suficientes e prazo compatível |
| 8. Redação e reprodução | Texto, bibliografia e scripts com ambiente fixado | Cada conclusão corresponde ao que o desenho efetivamente estima |

O volume computacional de centenas de ativos é manejável em princípio, mas não é o principal critério de qualidade. A expansão deve acontecer após verificar se a mensuração e as comparações funcionam. Não é necessário executar todas as extensões para ter um TCC consistente.

## 10. Alterações diretas sugeridas no plano original

| Trecho atual | Redação ou ação sugerida |
| --- | --- |
| “Confiança no Bitcoin, Contágio Financeiro e Risco Sistêmico...” | Adotar o título preditivo da seção 5, salvo mudança efetiva dos dados e do desenho |
| “choques externos de confiança” | “episódios documentados de estresse, cuja interpretação causal dependerá de estratégia específica” |
| “arestas representam conexões econômicas” | Especificar “arestas representam dependências estatísticas entre retornos”, se essa for a construção escolhida |
| “A propagação de confiança será representada por...” | “O multiplicador linear será utilizado como representação teórica e/ou fonte de atributos, sob as hipóteses explicitadas” |
| “classificar a ocorrência de contágio” | “estimar a probabilidade de perda futura superior ao limiar definido” |
| “Choque de confiança no Bitcoin” | “indicador observado de estresse do BTC”, até existir mensuração independente de confiança |
| “a posição ... influencia sua probabilidade” | “atributos da posição ... acrescentam informação para prever a probabilidade” |
| “Contribuição original” | Formular contribuição proposta e relacioná-la aos estudos empíricos mais próximos |
| “Código Python completo” e entregas anunciadas | Identificar como implementação pendente; o fragmento atual não é programa executável |

**Decisão acadêmica:** prosseguir com um núcleo de previsão de perdas e ganho incremental da rede, após as correções críticas. Manter confiança, causalidade e risco sistêmico como perguntas adicionais somente quando houver mensuração e desenho próprios. Essa delimitação preserva a parte viável do projeto e permite uma conclusão proporcional à evidência.

## 11. Referências selecionadas e função no desenho

### Redes econômicas, dinâmica e estabilidade

- **R01 — Ballester, C.; Calvó-Armengol, A.; Zenou, Y. (2006).** “Who's Who in Networks. Wanted: The Key Player”. *Econometrica*, 74(5), 1403–1417. [Artigo/DOI](https://doi.org/10.1111/j.1468-0262.2006.00709.x). Prioridade alta: fundamentação de complementaridades e relação com Bonacich; não identifica confiança na Binance.
- **R02 — Acemoglu, D.; Carvalho, V. M.; Ozdaglar, A.; Tahbaz-Salehi, A. (2012).** “The Network Origins of Aggregate Fluctuations”. *Econometrica*, 80(5), 1977–2016. [Artigo/DOI](https://doi.org/10.3982/ECTA9623). Prioridade alta: propagação e agregação por ligações produtivas; a transposição a ativos exige mecanismo próprio.
- **R03 — Acemoglu, D.; Ozdaglar, A.; Tahbaz-Salehi, A. (2015).** “Systemic Risk and Stability in Financial Networks”. *American Economic Review*, 105(2), 564–608. [Página editorial](https://www.aeaweb.org/articles?id=10.1257/aer.20130456). Prioridade alta se mantiver risco sistêmico: relação entre estrutura e estabilidade depende dos choques.
- **R04 — Haldane, A. G.; May, R. M. (2011).** “Systemic risk in banking ecosystems”. *Nature*, 469, 351–355. *Perspective*. [Artigo](https://www.nature.com/articles/nature09659). Contexto de estabilidade e cascatas; não substitui identificação empírica do canal cripto.
- **R05 — Bardoscia, M.; Barucca, P.; Battiston, S.; Caccioli, F.; Cimini, G.; Garlaschelli, D.; Saracco, F.; Squartini, T.; Caldarelli, G. (2021).** “The physics of financial networks”. *Nature Reviews Physics*, 3, 490–507. Revisão. [Artigo/DOI](https://doi.org/10.1038/s42254-021-00322-5), [versão dos autores](https://arxiv.org/abs/2103.05623). Prioridade alta: representações de redes e mecanismos financeiros.
- **R06 — Morris, S. (2000).** “Contagion”. *Review of Economic Studies*, 67(1), 57–78. [Versão no MIT](https://economics.mit.edu/sites/default/files/publications/paper_24_contagion.pdf). Para difusão por melhores respostas e condições de propagação; não é modelo de classificação financeira.
- **R07 — Acemoglu, D.; Dahleh, M. A.; Lobel, I.; Ozdaglar, A. (2011).** “Bayesian Learning in Social Networks”. *Review of Economic Studies*, 78(4), 1201–1236. [Página dos autores/MIT](https://asu.mit.edu/publication/bayesian-learning-social-networks/). Para distinguir aprendizado bayesiano de agentes de classificação bayesiana do pesquisador. DOI: 10.1093/restud/rdr004.

### Identificação, comovimento e aplicação ao mercado cripto

- **R08 — Forbes, K. J.; Rigobon, R. (2002).** “No Contagion, Only Interdependence: Measuring Stock Market Comovements”. *Journal of Finance*, 57(5), 2223–2261. [Artigo/DOI](https://doi.org/10.1111/0022-1082.00494). Prioridade máxima: distinguir contágio e interdependência e entender distorções por heterocedasticidade.
- **R09 — Manski, C. F. (1993).** “Identification of Endogenous Social Effects: The Reflection Problem”. *Review of Economic Studies*, 60(3), 531–542. [Artigo/DOI](https://doi.org/10.2307/2298123). Prioridade alta para qualquer interpretação de influência.
- **R10 — Bramoullé, Y.; Djebbari, H.; Fortin, B. (2009).** “Identification of peer effects through social networks”. *Journal of Econometrics*, 150(1), 41–55. [Artigo/DOI](https://doi.org/10.1016/j.jeconom.2008.12.021). Hipóteses para identificação em redes; uso metodológico condicionado.
- **R11 — Diebold, F. X.; Yilmaz, K. (2014).** “On the network topology of variance decompositions: Measuring the connectedness of financial firms”. *Journal of Econometrics*, 182(1), 119–134. [Artigo/DOI](https://doi.org/10.1016/j.jeconom.2014.04.012). Prioridade alta: alternativa econométrica de conectividade estatística dirigida.
- **R12 — Liu, Y.; Tsyvinski, A.; Wu, X. (2022).** “Common Risk Factors in Cryptocurrency”. *Journal of Finance*, 77(2), 1133–1177. [Artigo/DOI](https://doi.org/10.1111/jofi.13119). Prioridade alta: fatores comuns e referências competitivas de risco.
- **R13 — Ji, Q.; Bouri, E.; Lau, C. K. M.; Roubaud, D. (2019).** “Dynamic connectedness and integration in cryptocurrency markets”. *International Review of Financial Analysis*, 63, 257–272. [Página editorial](https://www.sciencedirect.com/science/article/pii/S1057521918305416). Aplicação próxima para situar o projeto; DOI: 10.1016/j.irfa.2018.12.002.
- **R14 — Będowska-Sójka, B.; Wójcik, P.; Giordano, S. (2025; publicação online em 2024).** “Has bitcoin been dethroned too quickly? The cryptocurrency return networks”. *Network Science*, 13, e1. [Artigo/DOI](https://doi.org/10.1017/nws.2024.17). Prioridade alta para originalidade: redes de retornos, centralidades e posição do Bitcoin. A interpretação causal de qualquer estudo continua sujeita ao respectivo desenho.

### Probabilidades, inferência bayesiana e avaliação

- **R15 — Gneiting, T.; Raftery, A. E. (2007).** “Strictly Proper Scoring Rules, Prediction, and Estimation”. *Journal of the American Statistical Association*, 102(477), 359–378. [Artigo/DOI](https://doi.org/10.1198/016214506000001437). Prioridade alta: avaliação de distribuições e probabilidades.
- **R16 — Niculescu-Mizil, A.; Caruana, R. (2005).** “Predicting Good Probabilities With Supervised Learning”. *ICML*, 625–632. Artigo de conferência. [Versão dos autores](https://www.cs.cornell.edu/~alexn/papers/calibration.icml05.crc.rev3.pdf). Prioridade alta: distorção e calibração das probabilidades, inclusive de Naive Bayes. DOI: 10.1145/1102351.1102430.
- **R17 — Gelman, A.; Jakulin, A.; Pittau, M. G.; Su, Y.-S. (2008).** “A weakly informative default prior distribution for logistic and other regression models”. *Annals of Applied Statistics*, 2(4), 1360–1383. [Artigo/DOI](https://doi.org/10.1214/08-AOAS191). Priors e regularização; não autoriza copiar escalas sem adaptar aos atributos.
- **R18 — Gabry, J.; Simpson, D.; Vehtari, A.; Betancourt, M.; Gelman, A. (2019).** “Visualization in Bayesian workflow”. *Journal of the Royal Statistical Society: Series A*, 182(2), 389–402. [Artigo/DOI](https://doi.org/10.1111/rssa.12378). Checagens de modelo e processo de inferência.
- **R19 — Bürkner, P.-C.; Gabry, J.; Vehtari, A. (2020).** “Approximate leave-future-out cross-validation for Bayesian time series models”. *Journal of Statistical Computation and Simulation*, 90(14), 2499–2523. [Artigo/DOI](https://doi.org/10.1080/00949655.2020.1783262). Validação prospectiva; a regra específica para rótulos sobrepostos deve seguir o alvo deste projeto.
- **R20 — Amihud, Y. (2002).** “Illiquidity and stock returns: cross-section and time-series effects”. *Journal of Financial Markets*, 5(1), 31–56. [Artigo/DOI](https://doi.org/10.1016/S1386-4181(01)00024-6). Referência de mensuração de iliquidez, com adaptação explícita para cripto e frequência horária.

### Documentação operacional

- **D01 — Binance Public Data.** [README oficial](https://github.com/binance/binance-public-data/blob/master/README.md). Formatos, campos, publicação e timestamps. Documentação de dados, não evidência de um mecanismo econômico.
- **D02 — scikit-learn.** [Guia oficial de Naive Bayes](https://scikit-learn.org/stable/modules/naive_bayes.html). Hipótese de independência, GaussianNB e limites das probabilidades. Documentação de implementação, não artigo acadêmico.

Leitura prioritária para reformular o texto: **R08 → R01/R02 → R11/R12 → R15/R16 → R19**. Acrescentar **R17/R18** se a extensão bayesiana entrar no escopo, e **R13/R14** para delimitar a contribuição em relação aos trabalhos aplicados.
