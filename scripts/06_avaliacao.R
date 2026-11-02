# Etapas 9-10: metricas, cobertura, calibracao e bootstrap da comparacao principal.
if (!file.exists("config/projeto.R")) stop("Execute na raiz sat-bayes.")
Sys.setenv(TZ = "UTC")
for (f in c("R/utils.R", "R/avaliacao.R")) source(f, encoding = "UTF-8")
cfg <- carregar_cfg()
tab_dir <- garantir_dir(file.path("resultados", "tabelas"))

pred <- data.table::as.data.table(as.data.frame(arrow::open_dataset(file.path("dados", "analiticos", "predictions"))$NewScan()$Project(c("symbol", "t", "y", "fase", "model_id", "algorithm", "p_raw", "p_calibrated", "motivo_y_ausente"))$Finish()$ToTable()))

metricas <- tabela_metricas(pred, por = "fase")
data.table::fwrite(metricas, file.path(tab_dir, "metricas_por_fase.csv"))
pred[, ano := format(t, "%Y")]
data.table::fwrite(tabela_metricas(pred[fase == "teste"], por = c("ano")), file.path(tab_dir, "metricas_teste_por_ano.csv"))
data.table::fwrite(tabela_metricas(pred[fase == "teste"], por = c("symbol")), file.path(tab_dir, "metricas_teste_por_ativo.csv"))
data.table::fwrite(tabela_calibracao(pred[fase %in% c("validacao", "teste")]), file.path(tab_dir, "calibracao_faixas.csv"))

cobertura <- pred[model_id == "M0", .(previsoes = .N, alvos_observados = sum(!is.na(y)),
                                      ausentes = sum(is.na(y))), by = .(symbol, ano, motivo_y_ausente)]
data.table::fwrite(cobertura, file.path(tab_dir, "cobertura_alvos.csv"))

# Comparacao principal (H1): ridge M3 - M2 no teste, limiar de 5%.
comparacoes <- data.table::data.table(
  a = c("M3", "M4", "M3", "M4"), b = c("M2", "M3", "M2", "M3"),
  algoritmo = c("ridge_logit", "ridge_logit", "gaussian_nb", "gaussian_nb"),
  status = c("principal", "secundaria", "complementar", "complementar"))
boot_res <- list(); censura <- list()
for (k in seq_len(nrow(comparacoes))) {
  cmp <- comparacoes[k]
  for (fase_alvo in c("validacao", "teste")) {
    d <- diferenca_diaria(pred, cmp$a, cmp$b, cmp$algoritmo, fase_alvo)
    if (!nrow(d$pares)) next
    ls <- if (cmp$status == "principal" && fase_alvo == "teste") c(3L, cfg$bootstrap_mean_days, 14L, 30L) else cfg$bootstrap_mean_days
    for (l in ls) {
      r <- bootstrap_delta(d$diario, l, cfg$bootstrap_replicates, cfg$seed)
      boot_res[[length(boot_res) + 1L]] <- cbind(cmp, fase = fase_alvo, r)
    }
    censura[[length(censura) + 1L]] <- cbind(cmp, fase = fase_alvo,
                                             limites_censura(pred, cmp$a, cmp$b, cmp$algoritmo, fase_alvo))
    if (cmp$status == "principal") {
      data.table::fwrite(d$diario, file.path(tab_dir, paste0("delta_brier_diario_", fase_alvo, ".csv")))
    }
  }
}
boot_res <- data.table::rbindlist(boot_res)
data.table::fwrite(boot_res, file.path(tab_dir, "comparacoes_bootstrap.csv"))
data.table::fwrite(data.table::rbindlist(censura), file.path(tab_dir, "limites_censura.csv"))

print(metricas[tipo == "calibrada" & fase %in% c("validacao", "teste"),
               .(fase, model_id, algorithm, n, prevalencia, brier, log_loss, roc_auc, average_precision)])
print(boot_res)
