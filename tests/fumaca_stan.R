# Teste de fumaca da etapa 11: compila o modelo e ajusta uma janela curta.
# Nao e resultado do estudo; apenas verifica codigo, dados e previsao.
Sys.setenv(TZ = "UTC")
for (f in c("R/utils.R", "R/atributos.R", "R/modelos.R", "R/bayes.R")) source(f, encoding = "UTF-8")
cfg <- carregar_cfg()
amostra <- data.table::as.data.table(arrow::read_parquet(file.path("dados", "analiticos", "amostra_principal.parquet")))
diaria <- amostra_diaria(amostra)
treino <- diaria[t >= as.POSIXct("2023-01-01", tz = "UTC") & t < as.POSIXct("2023-07-01", tz = "UTC") & !is.na(y)]
prev <- diaria[t >= as.POSIXct("2023-07-02", tz = "UTC") & t < as.POSIXct("2023-07-10", tz = "UTC")]
cx <- blocos_modelo()$M2; cz <- colunas_m3_extra
esc <- list(x = preparar_escala(as.matrix(treino[, cx, with = FALSE]), treino$y, cfg$class_sd_floor_after_scaling),
            z = preparar_escala(as.matrix(treino[, cz, with = FALSE]), treino$y, cfg$class_sd_floor_after_scaling))
ds <- dados_stan(treino, esc$x$cols, esc$z$cols, esc)
modelo <- cmdstanr::cmdstan_model("modelos/painel_diario.stan")
fit <- modelo$sample(data = ds$stan, chains = 2, parallel_chains = 2, iter_warmup = 300,
                     iter_sampling = 300, seed = cfg$seed, refresh = 0)
d <- diagnostico_bayes(fit)
print(d[c("divergencias", "max_rhat", "min_ess_bulk")])
draws <- posterior::as_draws_matrix(fit$draws(c("mu_a", "sigma_a", "u", "gamma", "xi", "sigma_v", "phi", "v_ultimo")))
p <- prever_bayes(draws, prev, esc$x$cols, esc$z$cols, esc, ds$ativos, max(ds$dias), 1L)
stopifnot(nrow(p) == nrow(prev), all(p$p_media > 0 & p$p_media < 1), all(p$p_q05 <= p$p_q95))
print(summary(p$p_media))
message("Fumaca Stan ok: ", nrow(treino), " obs de treino, ", nrow(prev), " previsoes.")
