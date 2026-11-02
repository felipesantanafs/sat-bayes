# Checagem preditiva a priori (secao 17.3), so com dados anteriores ao teste.
# Compara prevalencia e concentracao diaria das perdas (fracao de ativos com
# perda no mesmo dia) entre dados de desenvolvimento e priors candidatos.
Sys.setenv(TZ = "UTC")
for (f in c("R/utils.R", "R/atributos.R", "R/modelos.R", "R/bayes.R")) source(f, encoding = "UTF-8")
cfg <- carregar_cfg()
amostra <- data.table::as.data.table(arrow::read_parquet(file.path("dados", "analiticos", "amostra_principal.parquet")))
d <- amostra_diaria(amostra)[fase %in% c("inicializacao", "desenvolvimento") & !is.na(y)]
dia <- d[, .(frac = mean(y), n = .N), by = data]
obs <- c(prevalencia = mean(d$y), sd_frac_diaria = sd(dia$frac),
         p_dias_metade = mean(dia$frac >= 0.5), p_dias_zero = mean(dia$frac == 0))

simular <- function(sd_mu, media_mu, sd_sigma_a, sd_sigma_v, escala_coef, S = 400, D = 730, I = 13, K = 18) {
  set.seed(cfg$seed)
  res <- t(replicate(S, {
    mu <- stats::rnorm(1, media_mu, sd_mu); sa <- abs(stats::rnorm(1, 0, sd_sigma_a))
    sv <- abs(stats::rnorm(1, 0, sd_sigma_v))
    phi <- repeat { x <- stats::rnorm(1, 0, 0.5); if (abs(x) < 0.95) break }
    phi <- x
    a <- mu + sa * stats::rnorm(I)
    v <- numeric(D); v[1] <- stats::rnorm(1, 0, sv / sqrt(1 - phi^2))
    for (k in 2:D) v[k] <- phi * v[k - 1] + sv * stats::rnorm(1)
    # Atributos padronizados: contribuicao com variancia K * escala^2.
    xb <- matrix(stats::rnorm(D * I, 0, sqrt(K) * escala_coef * 0.5), D, I)
    p <- stats::plogis(outer(v, a, "+") + xb)
    y <- matrix(stats::rbinom(D * I, 1, p), D, I)
    fr <- rowMeans(y)
    c(prevalencia = mean(y), sd_frac_diaria = stats::sd(fr), p_dias_metade = mean(fr >= 0.5),
      p_dias_zero = mean(fr == 0))
  }))
  apply(res, 2, stats::quantile, c(0.05, 0.5, 0.95))
}

cat("Observado (2020 a jun/2024, origens diarias):\n"); print(round(obs, 3))
cat("\nPrior original: mu_a ~ N(-3, 1.5), sigma_v ~ HN(0.3)\n")
print(round(simular(1.5, -3, 1, 0.3, 0.5), 3))
cat("\nPrior revisado: mu_a ~ N(-3, 2), sigma_v ~ HN(2)\n")
print(round(simular(2, -3, 1, 2, 0.5), 3))
