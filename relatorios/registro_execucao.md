# Registro de execução do protocolo v1.1.0

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

## Etapa 11: modelos bayesianos (protocolo 1.1.0)

Revisão antes da execução (commit `f43e239`):
- A priori HN(0, 3) de `sigma_v` era incompatível com a concentração diária das perdas, e a priori preditiva gerava prevalências implausíveis. A versão adotada usa `mu_a ~ N(−3, 2)`, `sigma_v ~ HN(0, 2)` e coeficientes `N(0, 0,5)`.
- O estado AR(1) passou a ser não centrado. As cadeias são 4, com 1.000 iterações de aquecimento e 2.000 retidas.
- Mesmo assim, `phi` mantém ESS abaixo de 400 em parte dos ajustes. Decidi registrar o critério estrito do protocolo e não reajustar nada: `phi` é parâmetro de incômodo, e `gamma`/`xi` (os coeficientes de interesse) têm ESS ≥ 1.150 em todos os ajustes.

Execução: 60 ajustes trimestrais (2022-01 a 2026-10, 3 variantes), de 8 a 21 min cada, concluídos em 03/11/2026.

| Variante | Aprovados no critério estrito | R-hat máximo | ESS mínimo | Divergências |
| --- | --- | --- | --- | --- |
| B2 | 12/20 | 1,022 | 238 | 0 |
| B3 | 13/20 | 1,019 | 268 | 0 |
| B4 | 13/20 | 1,017 | 334 | 1 (B4 2026-10) |

As reprovações vêm de R-hat entre 1,01 e 1,022 ou de ESS abaixo de 400, concentrados em `phi`. A posteriori de `phi` fica em torno de 0,09, com intervalo de 90% entre −0,22 e 0,42: o estado comum quase não tem persistência entre dias. Já `sigma_v` ≈ 4,05, com intervalo entre 3,3 e 5,2, o que indica grande variação diária comum.

Amostra diária comum (origens às 00h UTC, 8.697 previsões no teste, 669 dias):

| Modelo | Brier desenv. | Brier valid. | Brier teste | AUC teste |
| --- | --- | --- | --- | --- |
| B2 | 0,08600 | 0,09045 | 0,07707 | 0,599 |
| B3 | 0,08619 | 0,09020 | 0,07703 | 0,614 |
| B4 | 0,08618 | 0,09020 | 0,07705 | 0,614 |
| M2 ridge | 0,08666 | 0,08935 | 0,07779 | 0,632 |
| M3 ridge | 0,08668 | 0,08934 | 0,07766 | 0,632 |
| M4 ridge | 0,08667 | 0,08934 | 0,07767 | 0,632 |

Diferenças no teste (bootstrap estacionário, bloco médio de 7 dias):

| Comparação | ΔBS | IC 95% |
| --- | --- | --- |
| B3 − B2 | −0,000037 | [−0,00046; +0,00040] |
| B4 − B3 | +0,000018 | [−0,00002; +0,00006] |
| M3 − M2 (ridge, diária) | −0,000130 | [−0,00039; +0,00011] |
| B3 − M3 ridge | −0,000630 | [−0,00197; +0,00069] |

**H4:** a posteriori dos coeficientes de rede `xi` é centrada perto de zero (médias entre −0,27 e +0,16) e só raramente exclui zero no intervalo de 90%: 1 a 4 ajustes de 20, conforme o atributo. O ganho de B3 sobre B2 é desprezível. No teste, os bayesianos têm Brier menor que a ridge, mas ROC-AUC menor, e na validação ficam piores. O intervalo de B3 − M3 inclui zero, portanto não há evidência de superioridade do modelo bayesiano.

## Etapa 12: robustez (ridge M3 − M2, teste)

| Variante | ΔBS | IC 95% | Δ relativo |
| --- | --- | --- | --- |
| Principal (reprodução) | −0,000198 | [−0,00042; +0,000007] | −0,24% |
| Perda > 3% | +0,000013 | [−0,00023; +0,00025] | +0,01% |
| Perda > 10% | +0,000045 | [−0,00010; +0,00024] | +0,31% |
| Janela de 30 dias | −0,000112 | [−0,00029; +0,00005] | −0,13% |
| Janela de 180 dias | −0,000094 | [−0,00022; +0,00003] | −0,11% |
| Corte de 0,20 | −0,000207 | [−0,00044; +0,000006] | −0,25% |
| Corte de 0,50 | −0,000210 | [−0,00047; +0,00001] | −0,25% |
| κ = 0,25 | −0,000180 | [−0,00038; +0,000002] | −0,22% |
| κ = 0,75 | −0,000222 | [−0,00050; +0,00003] | −0,27% |
| Spearman | −0,000126 | [−0,00028; +0,000009] | −0,15% |
| Rede residual | −0,000045 | [−0,000084; −0,000008] | −0,05% |
| Sem SUI (12 ativos) | −0,000201 | [−0,00050; +0,00004] | −0,25% |
| Origens diárias | −0,000245 | [−0,00059; +0,00012] | −0,31% |
| Atributos com 1h de atraso | −0,000202 | [−0,00042; +0,000001] | −0,24% |

Para as variações de construção da rede (corte, κ, janela, Spearman, composição, atraso), o sinal é o mesmo da especificação principal e a magnitude é parecida. O ganho, porém, desaparece quando o alvo muda para 3% ou 10%. A rede residual tem mediana de 1 aresta e é a única cujo intervalo exclui zero, mas o ganho dela é cerca de 4 vezes menor. A conclusão de H1 não muda: o efeito é pequeno, sensível à definição do desfecho, e o intervalo principal inclui zero.

## Pendências

- O pacote `tzdb` não está instalado, e o Arrow emite um aviso sobre fusos. As datas são gravadas e lidas como POSIXct UTC, sem impacto observado.
- A fila `scripts/rodar_pendentes.ps1` executa robustez → B2+B3 → B4 → avaliação e retoma o que faltar. Dentro de `Start-Job` o `Rscript` travava sem console; por isso os processos são lançados diretamente.
