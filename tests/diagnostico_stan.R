# Diagnostico do modelo Stan em uma janela de tamanho real (730 dias), com as
# configuracoes do protocolo. Uso: Rscript tests/diagnostico_stan.R [arquivo.stan] [variante]
Sys.setenv(TZ = "UTC")
for (f in c("R/utils.R", "R/atributos.R", "R/modelos.R", "R/bayes.R")) source(f, encoding = "UTF-8")
cfg <- carregar_cfg()
args <- commandArgs(trailingOnly = TRUE)
stan_file <- if (length(args) >= 1) args[1] else "modelos/painel_diario.stan"
variante <- if (length(args) >= 2) args[2] else "B3"
amostra <- data.table::as.data.table(arrow::read_parquet(file.path("dados", "analiticos", "amostra_principal.parquet")))
diaria <- amostra_diaria(amostra)
T0 <- as.POSIXct("2024-01-01", tz = "UTC")
treino <- diaria[t >= T0 - 730 * 86400 & t < T0 & label_available_at <= T0 + 60 & !is.na(y)]
cx <- blocos_modelo()$M2
cz <- if (variante == "B2") character() else colunas_m3_extra
esc <- list(x = preparar_escala(as.matrix(treino[, cx, with = FALSE]), treino$y, cfg$class_sd_floor_after_scaling),
            z = if (length(cz)) preparar_escala(as.matrix(treino[, cz, with = FALSE]), treino$y,
                                                cfg$class_sd_floor_after_scaling) else NULL)
ds <- dados_stan(treino, esc$x$cols, if (is.null(esc$z)) character() else esc$z$cols, esc)
message("N=", ds$stan$N, " I=", ds$stan$I, " D=", ds$stan$D, " Kx=", ds$stan$Kx, " Kz=", ds$stan$Kz)
modelo <- cmdstanr::cmdstan_model(stan_file)
t0 <- Sys.time()
fit <- modelo$sample(data = ds$stan, chains = 4, parallel_chains = 4, iter_warmup = 1000,
                     iter_sampling = 1000, seed = cfg$seed, refresh = 0, show_messages = FALSE)
message("Tempo: ", format(Sys.time() - t0))
s <- data.table::as.data.table(posterior::summarise_draws(fit$draws(), "mean", "sd", "rhat", "ess_bulk", "ess_tail"))
print(fit$diagnostic_summary())
print(s[order(-rhat)][1:15])
print(s[variable %in% c("mu_a", "sigma_a", "tau", "sigma_v", "phi") | grepl("^(gamma|xi)", variable)])
