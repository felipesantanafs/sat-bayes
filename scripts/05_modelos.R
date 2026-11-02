# Etapas 6-8: ajustes mensais, calibracao e escolha da penalizacao.
if (!file.exists("config/projeto.R")) stop("Execute na raiz sat-bayes.")
Sys.setenv(TZ = "UTC")
for (f in c("R/utils.R", "R/atributos.R", "R/modelos.R")) source(f, encoding = "UTF-8")
cfg <- carregar_cfg()
set.seed(cfg$seed)
ana_dir <- file.path("dados", "analiticos")
mod_dir <- garantir_dir(file.path("resultados", "modelos"))

amostra <- data.table::as.data.table(arrow::read_parquet(file.path(ana_dir, "amostra_principal.parquet")))
data.table::setorder(amostra, t, symbol)
versao <- readLines(file.path("dados", "intermediarios", "painel_versao.txt"))
manifest_hash <- sub("^data_manifest_hash=", "", grep("^data_manifest_hash=", versao, value = TRUE))

ajustes <- calendario_ajustes(cfg)
# Auditoria dos splits: nenhum rotulo usado depois do instante de ajuste.
splits <- ajustes[, {
  tr <- indices_treino(amostra, .SD)
  .(n_treino = length(tr), treino_primeira = min(amostra$t[tr]), treino_ultima = max(amostra$t[tr]),
    maior_label_available = max(amostra$label_available_at[tr]), n_previsao = length(indices_previsao(amostra, .SD)))
}, by = fit_id]
splits <- merge(ajustes, splits, by = "fit_id")
stopifnot(all(splits$maior_label_available <= splits$fit_at, na.rm = TRUE))
arrow::write_parquet(splits, file.path(ana_dir, "splits.parquet"))

ajustados <- ajustar_todos(amostra, cfg, ajustes)
calibrados <- calibrar_todos(amostra, ajustados, cfg)
escolha <- escolher_lambda(amostra, calibrados$P_cal, ajustados$specs, cfg)
print(escolha$grade[, .(model_id, lambda, brier_dev)])
print(escolha$escolha)

# Especificacoes finais: M0, NB por bloco e ridge com o lambda do desenvolvimento.
specs <- merge(ajustados$specs, escolha$escolha, by = "model_id", all.x = TRUE)
finais <- specs[algorithm != "ridge_logit" | lambda == lambda_escolhido]
fit_por_linha <- format(amostra$t, "%Y-%m", tz = "UTC")
# Um arquivo por especificacao (dataset Parquet), para caber em memoria limitada.
pred_dir <- file.path(ana_dir, "predictions")
if (dir.exists(pred_dir)) unlink(pred_dir, recursive = TRUE)
garantir_dir(pred_dir)
for (k in seq_len(nrow(finais))) {
  s <- finais$spec[k]
  pred <- data.table::data.table(
    asset_id = sub("USDT$", "", amostra$symbol), symbol = amostra$symbol, t = amostra$t,
    forecast_at = amostra$forecast_at, label_end = amostra$label_end,
    label_available_at = amostra$label_available_at, y = amostra$y, fase = amostra$fase,
    model_id = finais$model_id[k], algorithm = finais$algorithm[k], lambda = finais$lambda[k],
    p_raw = ajustados$P_raw[, s], p_calibrated = calibrados$P_cal[, s], fit_id = fit_por_linha,
    graph_id = amostra$graph_id, protocol_version = cfg$protocol_version,
    data_manifest_hash = manifest_hash, motivo_y_ausente = amostra$motivo_y_ausente)
  pred <- merge(pred, ajustados$log[model_id == finais$model_id[k], .(fit_id, fallback)],
                by = "fit_id", all.x = TRUE)
  pred <- pred[!is.na(p_raw)]
  stopifnot(all(is.finite(pred$p_raw)), all(pred$p_raw >= 0 & pred$p_raw <= 1),
            all(is.finite(pred$p_calibrated)))
  arrow::write_parquet(pred, file.path(pred_dir, paste0(finais$model_id[k], "_", finais$algorithm[k], ".parquet")))
  rm(pred); invisible(gc())
}
saveRDS(list(P_raw = ajustados$P_raw, P_cal = calibrados$P_cal, specs = ajustados$specs),
        file.path(mod_dir, "predicoes_todas_especificacoes.rds"))
data.table::fwrite(ajustados$log, file.path(mod_dir, "log_ajustes.csv"))
data.table::fwrite(calibrados$log, file.path(mod_dir, "log_calibracao.csv"))
data.table::fwrite(escolha$grade, file.path(mod_dir, "selecao_lambda_desenvolvimento.csv"))
data.table::fwrite(escolha$escolha, file.path(mod_dir, "lambda_escolhido.csv"))
writeLines(capture.output(sessionInfo()), file.path(mod_dir, "session_info.txt"))
