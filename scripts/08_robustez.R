# Etapa 12: robustez da comparacao principal (ridge M3 - M2) e comparador PAXG.
# Uso: Rscript scripts/08_robustez.R [variante ...]   (sem argumentos: todas)
# Cada variante grava seu resultado ao terminar; reexecutar pula as prontas.
if (!file.exists("config/projeto.R")) stop("Execute na raiz sat-bayes.")
Sys.setenv(TZ = "UTC")
for (f in c("R/utils.R", "R/painel.R", "R/atributos.R", "R/rede.R", "R/modelos.R", "R/avaliacao.R",
            "R/robustez.R")) source(f, encoding = "UTF-8")
cfg <- carregar_cfg()
set.seed(cfg$seed)
ativos <- carregar_ativos()
ana_dir <- file.path("dados", "analiticos")
out_dir <- garantir_dir(file.path("resultados", "tabelas", "robustez"))
btc <- ativos[papel_proposto == "ancora_rede", symbol_candidate]
alvos <- ativos[papel_proposto == "alvo_candidato", symbol_candidate]

todas <- variantes_robustez()
pedidas <- commandArgs(trailingOnly = TRUE)
if (!length(pedidas)) pedidas <- names(todas)
pendentes <- pedidas[!file.exists(file.path(out_dir, paste0(pedidas, ".csv")))]

if (length(pendentes)) {
  # Atributos M1/M2 e alvos ja calculados na etapa 4 (sem recalcular o painel).
  base <- data.table::as.data.table(arrow::read_parquet(file.path(ana_dir, "features_individual_market.parquet")))
  base <- base[symbol %in% c(btc, alvos) & t >= cfg$analysis_start & t < cfg$test_end_exclusive]
  alvo <- data.table::as.data.table(arrow::read_parquet(file.path(ana_dir, "targets.parquet"),
                                                         col_select = c("symbol", "t", "y", "ret_fwd_24h", "label_end", "label_available_at")))
  base <- merge(base, alvo, by = c("symbol", "t"), all.x = TRUE)
  rm(alvo); invisible(gc())
  rede_principal <- ler_rede_principal(ana_dir)
  retornos <- NULL
}

for (nome in pendentes) {
  v <- todas[[nome]]
  if (is.null(v)) stop("Variante desconhecida: ", nome)
  inicio <- Sys.time()
  registrar_log("Robustez ", nome, ": ", v$descricao)
  rede <- rede_principal
  if (muda_rede(v)) {
    if (is.null(retornos)) {
      painel <- ler_painel(simbolos = c(btc, alvos))
      data.table::setorder(painel, symbol, open_time)
      painel[, lr_1h := log(close / data.table::shift(close)), by = symbol]
      retornos <- painel[candle_end >= cfg$analysis_start - 200 * 86400, .(symbol, t = candle_end, lr_1h)]
      rm(painel); invisible(gc())
    }
    cfg_rede <- cfg
    if (!is.null(v$janela)) cfg_rede$graph_window_days <- v$janela
    rede <- construir_redes(retornos, c(btc, alvos), btc, cfg_rede, inicio = cfg$analysis_start,
                            fim = cfg$test_end_exclusive - 3600,
                            kappa = if (is.null(v$kappa)) cfg$katz_attenuation else v$kappa,
                            limiar = if (is.null(v$corte)) cfg$positive_correlation_threshold else v$corte,
                            metodo = if (is.null(v$metodo)) "pearson" else v$metodo,
                            residual = isTRUE(v$residual))
  }
  am <- montar_amostra_variante(base, rede, v, alvos, cfg)
  r <- avaliar_variante(am, cfg)
  r <- cbind(variante = nome, descricao = v$descricao,
             snapshots_validos = sum(rede$resumo$valido),
             arestas_mediana = stats::median(rede$resumo$n_arestas[rede$resumo$valido]),
             sd_katz_transversal = mean(rede$features[, stats::sd(katz_excess), by = graph_id]$V1, na.rm = TRUE),
             r, minutos = round(as.numeric(difftime(Sys.time(), inicio, units = "mins")), 1))
  data.table::fwrite(r, file.path(out_dir, paste0(nome, ".csv")))
  print(r[, .(variante, ativos, n_teste, prevalencia_teste, delta_brier, ic95_inf, ic95_sup, delta_rel_pct)])
  rm(am, rede); invisible(gc())
}

# Comparador PAXG (secao 18): tratado em painel separado, fora da rede.
alvo_paxg <- data.table::as.data.table(arrow::read_parquet(file.path(ana_dir, "targets.parquet"),
                                                            col_select = c("symbol", "t", "y", "ret_fwd_24h")))
alvo_paxg <- alvo_paxg[symbol == "PAXGUSDT" & t >= cfg$analysis_start & t < cfg$test_end_exclusive & !is.na(y)]
alvo_paxg[, fase := fase_origem(t, cfg)]
paxg <- alvo_paxg[, .(origens = .N, perdas_5pct = sum(y), perdas_3pct = sum(ret_fwd_24h < -0.03),
                      prevalencia_5pct = mean(y), menor_retorno_24h = min(ret_fwd_24h)), by = fase]
data.table::fwrite(paxg, file.path(out_dir, "comparador_paxg.csv"))

resumo <- data.table::rbindlist(lapply(list.files(out_dir, pattern = "\\.csv$", full.names = TRUE)[
  sub("\\.csv$", "", list.files(out_dir, pattern = "\\.csv$")) %in% names(todas)], data.table::fread), fill = TRUE)
resumo <- resumo[match(intersect(names(todas), resumo$variante), variante)]
data.table::fwrite(resumo, file.path("resultados", "tabelas", "robustez_resumo.csv"))
print(resumo[, .(variante, ativos, n_teste, delta_brier, ic95_inf, ic95_sup, delta_rel_pct, arestas_mediana)])
print(paxg)
