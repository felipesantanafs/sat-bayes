# Etapas 9-10: ganho preditivo e incerteza da comparacao (secoes 15-16).

metricas_prob <- function(y, p, eps = 1e-12) {
  ok <- !is.na(y) & !is.na(p)
  y <- y[ok]; p <- p[ok]
  base <- list(n = length(y), prevalencia = if (length(y)) mean(y) else NA_real_,
               brier = if (length(y)) mean((y - p)^2) else NA_real_,
               log_loss = if (length(y)) {
                 pc <- pmin(pmax(p, eps), 1 - eps); mean(-y * log(pc) - (1 - y) * log(1 - pc))
               } else NA_real_,
               roc_auc = NA_real_, average_precision = NA_real_, pr_auc = NA_real_,
               motivo_na = NA_character_)
  if (length(unique(y)) < 2) { base$motivo_na <- "uma_classe"; return(data.table::as.data.table(base)) }
  df <- data.frame(truth = factor(y, levels = c("0", "1")), p = p)
  base$roc_auc <- yardstick::roc_auc_vec(df$truth, df$p, event_level = "second")
  base$average_precision <- yardstick::average_precision_vec(df$truth, df$p, event_level = "second")
  base$pr_auc <- yardstick::pr_auc_vec(df$truth, df$p, event_level = "second")
  data.table::as.data.table(base)
}

# Tabela de metricas por modelo/algoritmo/fase, brutas e calibradas.
tabela_metricas <- function(pred, por = c("fase")) {
  chave <- c("model_id", "algorithm", por)
  cal <- pred[!is.na(y), metricas_prob(y, p_calibrated), by = chave][, tipo := "calibrada"]
  bru <- pred[!is.na(y), metricas_prob(y, p_raw), by = chave][, tipo := "bruta"]
  data.table::rbindlist(list(cal, bru))[order(tipo, model_id, algorithm)]
}

# Diferenca pareada de Brier (a - b) agregada por dia UTC da origem, com
# numerador S_d e denominador N_d preservados (estimando por observacao).
diferenca_diaria <- function(pred, a, b, algoritmo, fase_alvo) {
  sel <- pred[algorithm == algoritmo & fase == fase_alvo & model_id %in% c(a, b) & !is.na(y)]
  w <- data.table::dcast(sel, symbol + t + y ~ model_id, value.var = "p_calibrated")
  w <- w[!is.na(get(a)) & !is.na(get(b))]
  w[, delta := (y - get(a))^2 - (y - get(b))^2]
  w[, dia := as.Date(t, tz = "UTC")]
  diario <- w[, .(S_d = sum(delta), N_d = .N), by = dia]
  calendario <- data.table::data.table(dia = seq(min(diario$dia), max(diario$dia), by = "day"))
  diario <- merge(calendario, diario, by = "dia", all.x = TRUE)
  diario[is.na(N_d), `:=`(S_d = 0, N_d = 0L)]
  list(pares = w, diario = diario[order(dia)])
}

# Bootstrap estacionario dos dias completos (Politis e Romano, 1994).
bootstrap_delta <- function(diario, l, R, seed) {
  set.seed(seed)
  est <- function(d) if (sum(d[, 2]) > 0) sum(d[, 1]) / sum(d[, 2]) else NA_real_
  m <- as.matrix(diario[, .(S_d, N_d)])
  b <- boot::tsboot(m, est, R = R, sim = "geom", l = l)
  validas <- b$t[is.finite(b$t)]
  data.table::data.table(
    l_medio = l, R = R, estimativa = b$t0, ic95_inf = stats::quantile(validas, 0.025),
    ic95_sup = stats::quantile(validas, 0.975), reamostras_invalidas = sum(!is.finite(b$t)),
    dias = nrow(diario), dias_com_obs = sum(diario$N_d > 0), obs = sum(diario$N_d)
  )
}

# Limites descritivos da diferenca de Brier para rotulos ausentes (secao 15.2):
# cada Y ausente e fixado em 0 ou 1, escolhendo o extremo de cada parcela.
limites_censura <- function(pred, a, b, algoritmo, fase_alvo) {
  sel <- pred[algorithm == algoritmo & fase == fase_alvo & model_id %in% c(a, b)]
  w <- data.table::dcast(sel, symbol + t + y ~ model_id, value.var = "p_calibrated")
  w <- w[!is.na(get(a)) & !is.na(get(b))]
  d0 <- (0 - w[[a]])^2 - (0 - w[[b]])^2
  d1 <- (1 - w[[a]])^2 - (1 - w[[b]])^2
  obs <- !is.na(w$y)
  dobs <- (w$y[obs] - w[[a]][obs])^2 - (w$y[obs] - w[[b]][obs])^2
  n <- nrow(w)
  data.table::data.table(
    previsoes_emitidas = n, alvos_observados = sum(obs), alvos_ausentes = sum(!obs),
    delta_observados = mean(dobs),
    delta_limite_inf = (sum(dobs) + sum(pmin(d0, d1)[!obs])) / n,
    delta_limite_sup = (sum(dobs) + sum(pmax(d0, d1)[!obs])) / n
  )
}

# Frequencia observada por faixa de probabilidade (curva de calibracao).
tabela_calibracao <- function(pred, n_faixas = 10) {
  p <- pred[!is.na(y)]
  # Quantis repetidos (ex.: M0 constante no mes) sao fundidos em uma faixa.
  faixar <- function(x) {
    q <- unique(stats::quantile(x, seq(0, 1, length.out = n_faixas + 1), na.rm = TRUE))
    if (length(q) < 2) return(rep(1L, length(x)))
    findInterval(x, q, rightmost.closed = TRUE, all.inside = TRUE)
  }
  p[, faixa := faixar(p_calibrated), by = .(model_id, algorithm, fase)]
  p[, .(p_media = mean(p_calibrated), freq_observada = mean(y), n = .N),
    by = .(model_id, algorithm, fase, faixa)][order(model_id, algorithm, fase, faixa)]
}
