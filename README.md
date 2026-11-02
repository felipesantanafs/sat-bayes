# sat-bayes

Projeto de redes de dependência entre criptoativos e previsão probabilística de perdas, com execução planejada em R.

O protocolo vigente está em [contexto/plano_execucao_R.md](contexto/plano_execucao_R.md). Ele define dados, extração, pacotes, amostra, rede, modelos, calibração, validação temporal, inferência bayesiana e referências diretas. O [parecer crítico](contexto/avaliacao_critica_plano.md) e o [histórico inicial](contexto/contexto.txt) documentam a revisão.

Para começar, abra a raiz deste repositório em R/RStudio e execute em uma sessão nova:

```r
source("scripts/00_preparar_ambiente.R", encoding = "UTF-8")
source("scripts/01_piloto_extracao.R", encoding = "UTF-8")
```

O primeiro script instala os pacotes do núcleo em um ambiente `renv` e registra as versões. O segundo baixa três arquivos mensais de BTC/ETH, verifica checksums e formato e gera um manifesto de auditoria. Consulte os parâmetros em [config/projeto.R](config/projeto.R) e os candidatos em [config/ativos_solicitados.csv](config/ativos_solicitados.csv).

Os scripts iniciais ainda não executam a coleta integral, as redes ou os modelos. Essas implementações estão especificadas em etapas no plano. A disponibilidade histórica dos 17 candidatos permanece sujeita à auditoria; não há resultados empíricos estimados.
