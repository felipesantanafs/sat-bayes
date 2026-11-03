# Etapa 12: robustez e analises secundarias (secao 18 do plano).
# Cada variante altera uma unica escolha e repete a comparacao principal
# (ridge M3 contra M2, mesmas observacoes) com a mesma rotina temporal.

variantes_robustez <- function() {
  list(
    principal   = list(descricao = "Especificacao principal (reproducao)"),
    limiar_3    = list(descricao = "Perda > 3% em 24h", limiar_perda = -0.03),
    limiar_10   = list(descricao = "Perda > 10% em 24h", limiar_perda = -0.10),
    janela_30   = list(descricao = "Rede com janela de 30 dias", janela = 30L),
    janela_180  = list(descricao = "Rede com janela de 180 dias", janela = 180L),
    corte_020   = list(descricao = "Arestas com correlacao >= 0,20", corte = 0.20),
    corte_050   = list(descricao = "Arestas com correlacao >= 0,50", corte = 0.50),
    kappa_025   = list(descricao = "Atenuacao kappa = 0,25", kappa = 0.25),
    kappa_075   = list(descricao = "Atenuacao kappa = 0,75", kappa = 0.75),
    spearman    = list(descricao = "Rede de correlacao de Spearman", metodo = "spearman"),
    residual    = list(descricao = "Rede de residuos apos BTC e mercado", residual = TRUE),
    composicao  = list(descricao = "Ativos com historico antes do desenvolvimento (sem SUI)",
                       composicao = TRUE),
    diaria      = list(descricao = "Origens diarias as 00h UTC (treino e avaliacao)", diaria = TRUE),
    latencia_1h = list(descricao = "Atributos atrasados em 1 hora, mesmo alvo", latencia = TRUE)
  )
}

muda_rede <- function(v) any(c("janela", "corte", "kappa", "metodo", "residual") %in% names(v))

# Rede principal ja gravada pela etapa 5, no formato de construir_redes().
ler_rede_principal <- function(dir) {
  list(resumo = data.table::as.data.table(arrow::read_parquet(file.path(dir, "network_snapshots.parquet"))),
       features = data.table::as.data.table(arrow::read_parquet(file.path(dir, "network_features.parquet"))))
}

colunas_rede <- c("graph_id", "graph_valido", "n_nodes", "strength_mean", "katz_excess", "btc_exposure",
                  "betweenness_w", "a_d", "btc_exposure_stress")

montar_amostra_variante <- function(base, rede, v, alvos, cfg) {
  feat <- juntar_rede(base[, setdiff(names(base), colunas_rede), with = FALSE], rede)
  if (!is.null(v$limiar_perda)) feat[, y := as.integer(ret_fwd_24h < v$limiar_perda)]
  if (isTRUE(v$latencia)) {
    # Cada origem usa os atributos disponiveis uma hora antes; o alvo nao muda.
    data.table::setorder(feat, symbol, t)
    cols <- blocos_modelo()$M4
    feat[, (cols) := lapply(.SD, data.table::shift, n = 1L), by = symbol, .SDcols = cols]
    feat[, graph_valido := data.table::shift(graph_valido, 1L), by = symbol]
  }
  am <- feat[symbol %in% alvos & t >= cfg$analysis_start & t < cfg$test_end_exclusive]
  obrig <- blocos_modelo()$M3
  am <- am[stats::complete.cases(am[, obrig, with = FALSE]) & graph_valido %in% TRUE]
  if (isTRUE(v$diaria)) am <- am[format(t, "%H:%M:%S", tz = "UTC") == "00:00:00"]
  if (isTRUE(v$composicao)) {
    inicio_dev <- as.POSIXct("2022-01-01", tz = "UTC")
    primeiras <- base[!is.na(ret_1h), .(primeira = min(t)), by = symbol]
    am <- am[symbol %in% primeiras[primeira < inicio_dev, symbol]]
  }
  am[, fase := fase_origem(t, cfg)]
  data.table::setorder(am, t, symbol)
  am[, c("symbol", "t", "forecast_at", "label_end", "label_available_at", "y", "fase", obrig), with = FALSE]
}

avaliar_variante <- function(am, cfg) {
  specs <- especificacoes(cfg, modelos = c("M0", "M2", "M3"), naive_bayes = FALSE)
  aj <- ajustar_todos(am, cfg, specs = specs, progresso = FALSE)
  cal <- calibrar_todos(am, aj, cfg)
  esc <- escolher_lambda(am, cal$P_cal, specs, cfg)
  lam <- stats::setNames(esc$escolha$lambda_escolhido, esc$escolha$model_id)
  s2 <- specs[model_id == "M2" & lambda == lam[["M2"]], spec]
  s3 <- specs[model_id == "M3" & lambda == lam[["M3"]], spec]
  linhas <- function(f) which(am$fase == f & !is.na(am$y) & !is.na(cal$P_cal[, s2]) & !is.na(cal$P_cal[, s3]))
  pred <- data.table::rbindlist(lapply(c("validacao", "teste"), function(f) {
    i <- linhas(f)
    data.table::rbindlist(list(
      data.table::data.table(symbol = am$symbol[i], t = am$t[i], y = am$y[i], fase = f, model_id = "M2",
                             algorithm = "ridge_logit", p_calibrated = cal$P_cal[i, s2]),
      data.table::data.table(symbol = am$symbol[i], t = am$t[i], y = am$y[i], fase = f, model_id = "M3",
                             algorithm = "ridge_logit", p_calibrated = cal$P_cal[i, s3])))
  }))
  met <- pred[, metricas_prob(y, p_calibrated), by = .(fase, model_id)]
  dt <- diferenca_diaria(pred, "M3", "M2", "ridge_logit", "teste")
  dv <- diferenca_diaria(pred, "M3", "M2", "ridge_logit", "validacao")
  b <- bootstrap_delta(dt$diario, cfg$bootstrap_mean_days, cfg$bootstrap_replicates, cfg$seed)
  m <- function(f, mod, col) met[fase == f & model_id == mod][[col]]
  data.table::data.table(
    origens = nrow(am), ativos = data.table::uniqueN(am$symbol),
    n_teste = m("teste", "M2", "n"), prevalencia_teste = m("teste", "M2", "prevalencia"),
    lambda_M2 = lam[["M2"]], lambda_M3 = lam[["M3"]],
    brier_M2 = m("teste", "M2", "brier"), brier_M3 = m("teste", "M3", "brier"),
    delta_brier = b$estimativa, ic95_inf = b$ic95_inf, ic95_sup = b$ic95_sup,
    delta_rel_pct = 100 * b$estimativa / m("teste", "M2", "brier"),
    auc_M2 = m("teste", "M2", "roc_auc"), auc_M3 = m("teste", "M3", "roc_auc"),
    delta_validacao = sum(dv$diario$S_d) / sum(dv$diario$N_d),
    calibracoes_identidade = sum(cal$log$regra != "sigmoide")
  )
}
