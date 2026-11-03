# Etapa 11: inferencia bayesiana em painel diario (secao 17 do plano).
# Requer cmdstanr + CmdStan e o compilador C++ (Rtools no Windows).

# Origens diarias as 00h UTC da amostra principal, sem sobreposicao intradia.
amostra_diaria <- function(amostra) {
  d <- amostra[format(t, "%H:%M:%S", tz = "UTC") == "00:00:00"]
  d[, data := as.Date(t, tz = "UTC")]
  d[]
}

# Ajustes trimestrais no inicio de jan/abr/jul/out, janela de ate 730 dias.
calendario_bayes <- function(cfg, inicio = as.POSIXct("2022-01-01", tz = "UTC")) {
  meses <- seq(inicio, cfg$test_end_exclusive, by = "month")
  meses <- meses[as.integer(format(meses, "%m")) %in% cfg$bayesian_refit_months & meses < cfg$test_end_exclusive]
  data.table::data.table(fit_id = format(meses, "%Y-%m"), T = meses,
                         fit_at = meses + cfg$availability_delay_seconds,
                         prev_fim = c(meses[-1], cfg$test_end_exclusive),
                         treino_inicio = pmax(meses - cfg$training_window_days * 86400, cfg$analysis_start))
}

dados_stan <- function(treino, cols_x, cols_z, esc, mu_a_media = -3, mu_a_dp = 2, escala_coef = 0.5,
                       sigma_v_escala = 2) {
  dias <- seq(min(treino$data), max(treino$data), by = "day")
  ativos <- sort(unique(treino$symbol))
  zx <- aplicar_escala(as.matrix(treino[, ..cols_x]), esc$x)
  zz <- if (length(cols_z)) aplicar_escala(as.matrix(treino[, ..cols_z]), esc$z) else matrix(0, nrow(treino), 0)
  list(stan = list(N = nrow(treino), I = length(ativos), D = length(dias), Kx = ncol(zx), Kz = ncol(zz),
                   ativo = match(treino$symbol, ativos), dia = as.integer(treino$data - dias[1]) + 1L,
                   X = zx, Z = zz, y = treino$y, mu_a_media = mu_a_media, mu_a_dp = mu_a_dp,
                   escala_coef = escala_coef, sigma_v_escala = sigma_v_escala),
       ativos = ativos, dias = dias)
}

# Previsao temporal: propaga v a partir do ultimo estado de cada draw, sorteando
# as inovacoes futuras; ativo novo recebe u ~ N(0, 1) da distribuicao hierarquica.
prever_bayes <- function(draws, prev, cols_x, cols_z, esc, ativos, ultimo_dia, seed) {
  set.seed(seed)
  S <- nrow(draws)
  zx <- aplicar_escala(as.matrix(prev[, ..cols_x]), esc$x)
  zz <- if (length(cols_z)) aplicar_escala(as.matrix(prev[, ..cols_z]), esc$z) else NULL
  gamma <- draws[, grep("^gamma\\[", colnames(draws)), drop = FALSE]
  xi <- if (length(cols_z)) draws[, grep("^xi\\[", colnames(draws)), drop = FALSE] else NULL
  u <- draws[, grep("^u\\[", colnames(draws)), drop = FALSE]
  h_max <- as.integer(max(prev$data) - ultimo_dia)
  v <- matrix(NA_real_, S, h_max)
  estado <- draws[, "v_ultimo"]
  for (h in seq_len(h_max)) {
    estado <- draws[, "phi"] * estado + draws[, "sigma_v"] * stats::rnorm(S)
    v[, h] <- estado
  }
  eta <- matrix(draws[, "mu_a"], S, nrow(prev))
  eta <- eta + gamma %*% t(zx)
  if (!is.null(xi)) eta <- eta + xi %*% t(zz)
  idx <- match(prev$symbol, ativos)
  for (k in seq_len(nrow(prev))) {
    uk <- if (is.na(idx[k])) stats::rnorm(S) else u[, idx[k]]
    eta[, k] <- eta[, k] + draws[, "sigma_a"] * uk + v[, as.integer(prev$data[k] - ultimo_dia)]
  }
  p <- stats::plogis(eta)
  data.table::data.table(p_media = colMeans(p), p_q05 = apply(p, 2, stats::quantile, 0.05),
                         p_q95 = apply(p, 2, stats::quantile, 0.95))
}

# Vetores de tamanho zero (xi em B2) nao aparecem na saida do Stan.
variaveis_presentes <- function(fit, vars) {
  tamanhos <- fit$metadata()$stan_variable_sizes
  vars[vapply(vars, function(v) !is.null(tamanhos[[v]]) && prod(tamanhos[[v]]) > 0, logical(1))]
}

diagnostico_bayes <- function(fit) {
  vars <- variaveis_presentes(fit, c("mu_a", "sigma_a", "gamma", "xi", "sigma_v", "phi"))
  s <- posterior::summarise_draws(fit$draws(vars),
                                  "mean", "sd", ~stats::quantile(.x, c(0.05, 0.95)),
                                  "rhat", "ess_bulk", "ess_tail", "mcse_mean")
  d <- fit$diagnostic_summary(quiet = TRUE)
  list(resumo = data.table::as.data.table(s),
       divergencias = sum(d$num_divergent), max_rhat = max(s$rhat, na.rm = TRUE),
       min_ess_bulk = min(s$ess_bulk, na.rm = TRUE), min_ess_tail = min(s$ess_tail, na.rm = TRUE))
}
