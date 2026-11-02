# Registro de execução do protocolo v1.0.0

Execução de 02/11/2026 (UTC), branch `estrutura-pipeline`. Os arquivos de `dados/` e `resultados/` não são versionados; este registro guarda o que foi executado, as decisões tomadas durante a execução e os números que sustentam a leitura dos resultados. Fontes e definições: [plano_execucao_R.md](../contexto/plano_execucao_R.md).

## Ambiente

- R 4.4.1, `renv` com 100 pacotes do núcleo e os bayesianos (`renv.lock`). Binários do Posit Package Manager: o CRAN não publica mais binários atuais para R 4.4, e entradas do cache do renv vindas da primeira tentativa continham versões trocadas (ex.: pasta `rlang/1.3.0` com o pacote 1.2.0). Elas foram removidas com `renv::purge()`.
- Rtools44 (instalador assinado do CRAN) e CmdStan 2.40.0; o toolchain C++ foi validado por `cmdstanr::check_cmdstan_toolchain()`.

## Etapas 1–2: catálogo e coleta

- O catálogo atual (`exchangeInfo`) traz 16 dos 17 candidatos com status `TRADING`, spot e cotação em USDT. **MUSDUSDT** não existe no catálogo nem nos arquivos históricos e fica `nao_localizado`. O comparador MUSD não entra no estudo até que se documente outra identidade.
- 1.231 arquivos mensais e 16 diários (2026-11-01) baixados. Todos tiveram o SHA-256 conferido contra o `.CHECKSUM`, sem erros transitórios, divergências ou esquemas inesperados. A API não foi necessária.
- HYPEUSDT tem histórico spot apenas a partir de 2026-09-24, menos que a janela de 90 dias da rede, e fica fora da amostra principal.

## Etapa 3: painel

- 16 ativos na grade UTC de 1h, sem conflitos entre fontes.
- **Decisão de auditoria** tomada na execução: candles de paradas da Binance não representam o fechamento em `candle_end`. Há dois casos: abertura fora da grade (43 candles de BTC entre 09 e 11/02/2018, abrindo às hh:28:14) e fechamento antes ou depois do fim da hora (ex.: SOL em 2021-12-24 04h, 476 ms depois). Esses candles ficam registrados em `resultados/auditoria/painel/anomalias/` e fora da grade analítica, com `motivo_ausencia`. Só um desvio sistemático, que indicaria unidade temporal errada, interrompe a leitura.

## Etapas 4–5: atributos e redes

- 2.496 snapshots diários, todos válidos (BTC presente; 7 a 14 nós).
- Rede quase completa: com o corte de ρ ≥ 0,30, a mediana é de 78 arestas para 78 pares possíveis. A variação entre ativos de Katz e da exposição ao BTC existe, mas é pequena (desvio-padrão transversal médio de 0,06 e 0,005 no teste). Esse é o risco de pouca informação topológica que o parecer já antecipava; as sensibilidades de corte (0,20/0,50) e de rede residual da seção 18 passam a ser prioritárias.
- Amostra principal (13 alvos, origens horárias com todos os atributos de M0–M4): 683.344 origens. Prevalência de perda acima de 5% em 24h: 14,9% (inicialização), 9,8% (desenvolvimento), 9,4% (validação) e 9,3% (teste). Nenhum alvo ausente no período.

## Etapas 6–8: modelos e calibração

- 79 ajustes mensais (abr/2020 a out/2026); nenhum rótulo usado após o instante de ajuste (auditoria em `splits.parquet`).
- λ escolhido no desenvolvimento, sem consultar 2025–2026: 0,1 em M1–M4, valor interno à grade.
- Calibração: 1.949 ajustes sigmoides, 25 identidades por falta de suporte (meses iniciais) e 1 por problema de ajuste.

## Etapas 9–10: resultados

Teste final (01/01/2025 a 31/10/2026), probabilidades calibradas, 208.728 previsões e 669 dias:

| Modelo | Brier | Log loss | ROC-AUC | Average precision |
| --- | --- | --- | --- | --- |
| M0 frequência | 0,08789 | 0,3294 | 0,477 | 0,091 |
| M2 ridge | 0,08334 | 0,3029 | 0,619 | 0,136 |
| M3 ridge | 0,08314 | 0,3022 | 0,620 | 0,138 |
| M4 ridge | 0,08314 | 0,3021 | 0,620 | 0,138 |

**H1 (principal, ridge M3 − M2):** ΔBS = −0,000198, cerca de 0,24% do Brier de M2. Intervalos do bootstrap estacionário a 95%:

| Bloco médio (dias) | Intervalo |
| --- | --- |
| 3 | [−0,00043; −0,000004] |
| 7 (principal) | [−0,00042; +0,000007] |
| 14 | [−0,00045; +0,000015] |
| 30 | [−0,00045; +0,000014] |

O sinal favorece a rede, mas o intervalo principal inclui zero e o ganho é pequeno. Na validação (2º semestre de 2024): ΔBS = −0,000074, com intervalo [−0,00024; +0,00007].

**H2 (M4 − M3, ridge):** +0,0000017 no teste, intervalo [−0,000016; +0,000020]. Não há evidência de informação adicional da interação exposição × estresse do BTC.

**H3 (estabilidade):** o ganho não é homogêneo. Em 2025, M3 foi ligeiramente pior que M2 (Brier 0,09978 contra 0,09975); em 2026, foi melhor (0,06261 contra 0,06280).

**Naive Bayes (complementar):** M3 − M2 = −0,00027, intervalo [−0,00058; −0,00004]. O NB fica abaixo da ridge em todos os blocos e, na validação, abaixo do próprio M0.

Ressalvas: todos os modelos superam pouco a frequência de referência (Brier de 0,0833 contra 0,0879), o que indica baixa previsibilidade do desfecho. Os intervalos condicionam-se à sequência de previsões e não cobrem a incerteza de seleção do projeto. Os resultados são associações preditivas, sem interpretação causal (seções 1.3 e 16 do plano).

## Pendências

- Etapa 11 (bayesiana): o modelo Stan compila e passou no teste de fumaça (`tests/fumaca_stan.R`). Com 300 iterações, o R-hat chegou a 1,44, o que exige examinar a identificação entre `mu_a`, `u` e `v` antes da execução trimestral completa (20 ajustes × 3 variantes; estimativa de várias horas).
- Etapa 12 (robustez): limiares de 3% e 10%, janelas de 30 e 180 dias, cortes de 0,20 e 0,50, κ de 0,25 e 0,75, rede de Spearman, rede residual, atraso de 1h e comparadores (PAXG).
- O pacote `tzdb` não está instalado, e o Arrow emite um aviso sobre fusos. As datas são gravadas e lidas como POSIXct UTC, sem impacto observado.
