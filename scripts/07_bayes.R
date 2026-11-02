# Etapa 11: modelos bayesianos B2/B3/B4 no painel diario, ajustes trimestrais.
# Pre-requisito (uma vez): scripts/00b_preparar_bayes.R (Rtools + CmdStan).
# Uso:
#   Rscript scripts/07_bayes.R ajustar B2   # uma variante por processo; podem rodar em paralelo
#   Rscript scripts/07_bayes.R avaliar      # junta as variantes e compara na amostra diaria comum
# Cada ajuste trimestral e gravado ao terminar; reexecutar retoma do que falta.
if (!file.exists("config/projeto.R")) stop("Execute na raiz sat-bayes.")
Sys.setenv(TZ = "UTC")
for (f in c("R/utils.R", "R/atributos.R", "R/modelos.R", "R/avaliacao.R", "R/bayes.R")) source(f, encoding = "UTF-8")
cfg <- carregar_cfg()
args <- commandArgs(trailingOnly = TRUE)
modo <- if (length(args)) args[1] else "avaliar"
blocos <- blocos_modelo()
variantes <- list(B2 = list(x = blocos$M2, z = character()),
                  B3 = list(x = blocos$M2, z = colunas_m3_extra),
                  B4 = list(x = blocos$M2, z = c(colunas_m3_extra, colunas_m4_extra)))
escala_coef <- as.numeric(Sys.getenv("SAT_BAYES_ESCALA_COEF", cfg$bayes_coef_prior_scale))
rotulo <- if (escala_coef == cfg$bayes_coef_prior_scale) "principal" else paste0("escala_", escala_coef)
out_dir <- garantir_dir(file.path("resultados", "modelos", "bayes", rotulo))

if (modo == "ajustar") {
  nome <- args[2]
  if (!(nome %in% names(variantes))) stop("Variante invalida: ", nome)
  if (is.null(tryCatch(cmdstanr::cmdstan_version(), error = function(e) NULL))) stop("CmdStan nao instalado.")
  amostra <- data.table::as.data.table(arrow::read_parquet(file.path("dados", "analiticos", "amostra_principal.parquet")))
  diaria <- amostra_diaria(amostra); rm(amostra); invisible(gc())
  modelo <- cmdstanr::cmdstan_model("modelos/painel_diario.stan")
  vv <- variantes[[nome]]
  var_dir <- garantir_dir(file.path(out_dir, nome))
  ajustes <- calendario_bayes(cfg)
  for (k in seq_len(nrow(ajustes))) {
    aj <- ajustes[k]
    destino <- file.path(var_dir, paste0("previsoes_", aj$fit_id, ".parquet"))
    if (file.exists(destino)) next
    treino <- diaria[t >= aj$treino_inicio & t < aj$T & label_available_at <= aj$fit_at & !is.na(y)]
    prev <- diaria[t >= aj$T & t < aj$prev_fim]
    if (!nrow(prev) || sum(treino$y) < cfg$minimum_training_per_class) next
    esc <- list(x = preparar_escala(as.matrix(treino[, vv$x, with = FALSE]), treino$y, cfg$class_sd_floor_after_scaling),
                z = if (length(vv$z)) preparar_escala(as.matrix(treino[, vv$z, with = FALSE]), treino$y,
                                                      cfg$class_sd_floor_after_scaling) else NULL)
    cx <- esc$x$cols; cz <- if (is.null(esc$z)) character() else esc$z$cols
    ds <- dados_stan(treino, cx, cz, esc, mu_a_media = cfg$bayes_mu_a_prior[["media"]],
                     mu_a_dp = cfg$bayes_mu_a_prior[["dp"]], escala_coef = escala_coef,
                     sigma_v_escala = cfg$bayes_sigma_v_prior_scale)
    inicio <- Sys.time()
    fit <- modelo$sample(data = ds$stan, chains = cfg$bayes_chains, parallel_chains = cfg$bayes_chains,
                         iter_warmup = cfg$bayes_warmup, iter_sampling = cfg$bayes_sampling,
                         seed = cfg$seed + k, refresh = 0, show_messages = FALSE)
    diag <- diagnostico_bayes(fit)
    data.table::fwrite(diag$resumo, file.path(var_dir, paste0("resumo_", aj$fit_id, ".csv")))
    data.table::fwrite(data.table::data.table(
      fit_id = aj$fit_id, modelo = nome, n_treino = nrow(treino), dias = ds$stan$D,
      ultimo_dia_treino = max(ds$dias), divergencias = diag$divergencias, max_rhat = diag$max_rhat,
      min_ess_bulk = diag$min_ess_bulk, min_ess_tail = diag$min_ess_tail,
      aceito = diag$max_rhat < cfg$bayes_rhat_max && diag$min_ess_bulk >= cfg$bayes_ess_min && diag$divergencias == 0,
      minutos = as.numeric(difftime(Sys.time(), inicio, units = "mins")),
      cmdstan = cmdstanr::cmdstan_version()), file.path(var_dir, paste0("diagnostico_", aj$fit_id, ".csv")))
    draws <- posterior::as_draws_matrix(fit$draws(c("mu_a", "sigma_a", "u", "gamma", "xi", "sigma_v", "phi", "v_ultimo")))
    p <- prever_bayes(draws, prev, cx, cz, esc, ds$ativos, max(ds$dias), cfg$seed + k)
    arrow::write_parquet(cbind(prev[, .(symbol, t, y, fase)], modelo = nome, fit_id = aj$fit_id, p), destino)
    message("[", agora_utc(), "] ", nome, " ", aj$fit_id, ": rhat max ", round(diag$max_rhat, 3),
            ", ESS bulk min ", round(diag$min_ess_bulk), ", divergencias ", diag$divergencias)
    rm(fit, draws); invisible(gc())
  }
  quit(save = "no")
}

# ---- avaliar ------------------------------------------------------------------
ler <- function(padrao) data.table::rbindlist(lapply(
  list.files(out_dir, pattern = padrao, recursive = TRUE, full.names = TRUE),
  function(f) if (grepl("parquet$", f)) data.table::as.data.table(arrow::read_parquet(f)) else data.table::fread(f)))
pb <- ler("^previsoes_.*\\.parquet$")
diagnosticos <- ler("^diagnostico_.*\\.csv$")
data.table::fwrite(diagnosticos[order(modelo, fit_id)], file.path(out_dir, "diagnosticos.csv"))
arrow::write_parquet(pb, file.path(out_dir, "predicoes_bayes_diarias.parquet"))
print(diagnosticos[, .(ajustes = .N, aceitos = sum(aceito), max_rhat = max(max_rhat),
                       min_ess = min(min_ess_bulk), divergencias = sum(divergencias)), by = modelo])

# Comparacao na mesma amostra diaria: referencias classicas reavaliadas nas
# origens das 00h com previsao bayesiana (secao 17).
classicos <- data.table::as.data.table(as.data.frame(
  arrow::open_dataset(file.path("dados", "analiticos", "predictions"))$NewScan()$Project(
    c("symbol", "t", "model_id", "algorithm", "p_calibrated"))$Finish()$ToTable()))
classicos <- classicos[algorithm == "ridge_logit" & model_id %in% c("M2", "M3", "M4")]
classicos[, modelo := paste0(model_id, "_ridge")]
comuns <- pb[, .N, by = .(symbol, t)][N == length(variantes), .(symbol, t)]
base <- unique(pb[, .(symbol, t, y, fase)])
pc <- merge(merge(comuns, classicos[, .(symbol, t, modelo, p_media = p_calibrated)], by = c("symbol", "t")),
            base, by = c("symbol", "t"))
todos <- data.table::rbindlist(list(merge(comuns, pb, by = c("symbol", "t"))[, .(symbol, t, y, fase, modelo, p_media)],
                                    pc[, .(symbol, t, y, fase, modelo, p_media)]))
met <- todos[!is.na(y), metricas_prob(y, p_media), by = .(modelo, fase)][order(fase, modelo)]
data.table::fwrite(met, file.path(out_dir, "metricas_diarias_comuns.csv"))
print(met[, .(fase, modelo, n, prevalencia, brier, log_loss, roc_auc)])

# Diferencas pareadas no teste, bootstrap por dia (uma origem diaria por ativo).
comp <- todos[, `:=`(algorithm = "comum", model_id = modelo, p_calibrated = p_media)]
boot_res <- data.table::rbindlist(lapply(list(c("B3", "B2"), c("B4", "B3"), c("M3_ridge", "M2_ridge"),
                                              c("B3", "M3_ridge")), function(par) {
  d <- diferenca_diaria(comp, par[1], par[2], "comum", "teste")
  if (!nrow(d$pares)) return(NULL)
  cbind(a = par[1], b = par[2], bootstrap_delta(d$diario, cfg$bootstrap_mean_days, cfg$bootstrap_replicates, cfg$seed))
}))
data.table::fwrite(boot_res, file.path(out_dir, "comparacoes_bootstrap_diario.csv"))
print(boot_res)

# Posteriores dos coeficientes de rede (xi) por ajuste, para H4.
resumos <- data.table::rbindlist(lapply(list.files(out_dir, pattern = "^resumo_", recursive = TRUE, full.names = TRUE),
  function(f) cbind(data.table::fread(f), modelo = basename(dirname(f)), fit_id = sub("^resumo_(.*)\\.csv$", "\\1", basename(f)))))
data.table::fwrite(resumos, file.path(out_dir, "resumos_posteriores.csv"))
