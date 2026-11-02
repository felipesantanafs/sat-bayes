# Grafo computacional do protocolo (secao 19). Executar com targets::tar_make().
# Cada etapa e um script em scripts/ com saidas rastreadas como arquivos.
# A coleta nunca reexecuta sozinha: o cache nao descobre mudancas remotas, e
# uma atualizacao deliberada se faz com targets::tar_invalidate(coleta).
library(targets)

rodar_script <- function(script, saidas, ...) {
  callr::rscript(script, show = TRUE)
  stopifnot(all(file.exists(saidas)))
  saidas
}

r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)

list(
  tar_target(config_files, c("config/projeto.R", "config/ativos_solicitados.csv"), format = "file"),
  tar_target(codigo, r_files, format = "file"),
  tar_target(
    coleta,
    rodar_script("scripts/02_coleta_completa.R", "dados/brutos/coleta_vigente.txt", config_files),
    format = "file", cue = tar_cue(mode = "never")
  ),
  tar_target(
    painel,
    rodar_script("scripts/03_painel.R", "dados/intermediarios/painel_versao.txt", coleta, codigo),
    format = "file"
  ),
  tar_target(
    amostra,
    rodar_script("scripts/04_atributos_rede.R", c(
      "dados/analiticos/amostra_principal.parquet", "dados/analiticos/network_features.parquet"),
      painel, codigo, config_files),
    format = "file"
  ),
  tar_target(
    previsoes,
    rodar_script("scripts/05_modelos.R", "dados/analiticos/predictions/M3_ridge_logit.parquet", amostra, codigo),
    format = "file"
  ),
  tar_target(
    avaliacao,
    rodar_script("scripts/06_avaliacao.R", c(
      "resultados/tabelas/metricas_por_fase.csv", "resultados/tabelas/comparacoes_bootstrap.csv"),
      previsoes, codigo),
    format = "file"
  )
)
