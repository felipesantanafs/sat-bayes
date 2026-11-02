# Etapa 11: modelos bayesianos B2/B3/B4 no painel diario, ajustes trimestrais.
# Pre-requisito (uma vez): instalar Rtools compativel com o R, depois
#   renv::install(cfg$packages_bayesian)
#   install.packages("cmdstanr", repos = c("https://stan-dev.r-universe.dev", getOption("repos")))
#   cmdstanr::check_cmdstan_toolchain(); cmdstanr::install_cmdstan(cores = 2)
if (!file.exists("config/projeto.R")) stop("Execute na raiz sat-bayes.")
Sys.setenv(TZ = "UTC")
for (f in c("R/utils.R", "R/atributos.R", "R/modelos.R", "R/avaliacao.R", "R/bayes.R")) source(f, encoding = "UTF-8")
cfg <- carregar_cfg()
faltam <- c(cfg$packages_bayesian, "cmdstanr")[!vapply(c(cfg$packages_bayesian, "cmdstanr"),
                                                      requireNamespace, logical(1), quietly = TRUE)]
if (length(faltam)) stop("Instale antes: ", paste(faltam, collapse = ", "))
if (is.null(tryCatch(cmdstanr::cmdstan_version(), error = function(e) NULL))) stop("CmdStan nao instalado.")

out_dir <- garantir_dir(file.path("resultados", "modelos", "bayes"))
amostra <- data.table::as.data.table(arrow::read_parquet(file.path("dados", "analiticos", "amostra_principal.parquet")))
diaria <- amostra_diaria(amostra)
modelo <- cmdstanr::cmdstan_model("modelos/painel_diario.stan")
blocos <- blocos_modelo()
variantes <- list(B2 = list(x = blocos$M2, z = character()),
                  B3 = list(x = blocos$M2, z = colunas_m3_extra),
                  B4 = list(x = blocos$M2, z = c(colunas_m3_extra, colunas_m4_extra)))
escala_coef <- as.numeric(Sys.getenv("SAT_BAYES_ESCALA_COEF", "0.5"))

ajustes <- calendario_bayes(cfg)
previsoes <- list(); diagnosticos <- list()
for (k in seq_len(nrow(ajustes))) {
  aj <- ajustes[k]
  treino <- diaria[t >= aj$treino_inicio & t < aj$T & label_available_at <= aj$fit_at & !is.na(y)]
  prev <- diaria[t >= aj$T & t < aj$prev_fim]
  if (!nrow(prev) || sum(treino$y) < cfg$minimum_training_per_class) next
  for (nome in names(variantes)) {
    vv <- variantes[[nome]]
    esc <- list(x = preparar_escala(as.matrix(treino[, vv$x, with = FALSE]), treino$y, cfg$class_sd_floor_after_scaling),
                z = if (length(vv$z)) preparar_escala(as.matrix(treino[, vv$z, with = FALSE]), treino$y,
                                                      cfg$class_sd_floor_after_scaling) else NULL)
    cx <- esc$x$cols; cz <- if (is.null(esc$z)) character() else esc$z$cols
    ds <- dados_stan(treino, cx, cz, esc, escala_coef = escala_coef)
    fit <- modelo$sample(data = ds$stan, chains = 4, parallel_chains = 4, iter_warmup = 1000,
                         iter_sampling = 1000, seed = cfg$seed + k, refresh = 0)
    diag <- diagnostico_bayes(fit)
    diagnosticos[[length(diagnosticos) + 1L]] <- data.table::data.table(
      fit_id = aj$fit_id, modelo = nome, n_treino = nrow(treino), divergencias = diag$divergencias,
      max_rhat = diag$max_rhat, min_ess_bulk = diag$min_ess_bulk, min_ess_tail = diag$min_ess_tail,
      aceito = diag$max_rhat < 1.01 && diag$min_ess_bulk >= 400 && diag$divergencias == 0)
    data.table::fwrite(diag$resumo, file.path(out_dir, paste0("resumo_", nome, "_", aj$fit_id, ".csv")))
    draws <- posterior::as_draws_matrix(fit$draws(c("mu_a", "sigma_a", "u", "gamma", "xi", "sigma_v", "phi", "v_ultimo")))
    p <- prever_bayes(draws, prev, cx, cz, esc, ds$ativos, max(ds$dias), cfg$seed + k)
    previsoes[[length(previsoes) + 1L]] <- cbind(prev[, .(symbol, t, y, fase)], modelo = nome, fit_id = aj$fit_id, p)
    message("Ajuste bayesiano ", nome, " ", aj$fit_id, " concluido")
  }
}
pb <- data.table::rbindlist(previsoes)
arrow::write_parquet(pb, file.path(out_dir, "predicoes_bayes_diarias.parquet"))
data.table::fwrite(data.table::rbindlist(diagnosticos), file.path(out_dir, "diagnosticos.csv"))
print(pb[!is.na(y), metricas_prob(y, p_media), by = .(modelo, fase)])
