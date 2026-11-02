# Etapa 4: alvos e atributos individuais/de mercado (secao 10 do plano).
# O painel chega gradeado por simbolo (uma linha por hora, NA quando ausente),
# de modo que defasagens por linha equivalem a juncoes por horario exato.
features_version <- "atributos-1.0.0"

# Soma movel retrospectiva que exige cobertura integral da janela.
soma_movel <- function(x, n) data.table::frollsum(x, n, align = "right", na.rm = FALSE)

# Desvio-padrao movel com cobertura integral (NA se faltar qualquer hora).
dp_movel <- function(x, n) {
  s1 <- soma_movel(x, n); s2 <- soma_movel(x^2, n)
  v <- (s2 - s1^2 / n) / (n - 1)
  sqrt(pmax(v, 0))
}

# Beta historico cov/var em pares coincidentes, com cobertura minima.
beta_movel <- function(y, x, n, cobertura) {
  ok <- !is.na(y) & !is.na(x)
  y0 <- data.table::fifelse(ok, y, 0); x0 <- data.table::fifelse(ok, x, 0)
  k <- data.table::frollsum(as.numeric(ok), n, align = "right")
  sx <- data.table::frollsum(x0, n, align = "right"); sy <- data.table::frollsum(y0, n, align = "right")
  sxy <- data.table::frollsum(x0 * y0, n, align = "right"); sxx <- data.table::frollsum(x0^2, n, align = "right")
  cov <- (sxy - sx * sy / k) / (k - 1)
  var <- (sxx - sx^2 / k) / (k - 1)
  b <- cov / var
  b[is.na(k) | k < ceiling(cobertura * n) | !is.finite(b) | var <= 0] <- NA_real_
  b
}

# Bloco M1 e alvo, por simbolo. `t` e o fechamento do candle (candle_end).
construir_individuais <- function(painel, cfg) {
  p <- data.table::copy(painel)
  data.table::setorder(p, symbol, open_time)
  p[, t := candle_end]
  p[, `:=`(
    ret_1h = close / data.table::shift(close, 1L) - 1,
    ret_24h = close / data.table::shift(close, 24L) - 1,
    ret_168h = close / data.table::shift(close, 168L) - 1,
    lr_1h = log(close / data.table::shift(close, 1L))
  ), by = symbol]
  p[, `:=`(
    vol_24h = dp_movel(lr_1h, 24L) * sqrt(24),
    vol_168h = dp_movel(lr_1h, 168L) * sqrt(24),
    log_quote_volume_24h = log1p(soma_movel(quote_volume, 24L))
  ), by = symbol]
  # Amihud adaptado: media de |ret_1h|/volume USDT nas horas com volume positivo.
  p[, illiq_valida := !is.na(ret_1h) & !is.na(quote_volume) & quote_volume > 0]
  p[, illiq_x := data.table::fifelse(illiq_valida, abs(ret_1h) / quote_volume, 0)]
  p[, `:=`(illiq_n_validas = data.table::frollsum(as.numeric(illiq_valida), 168L, align = "right"),
           illiq_soma = data.table::frollsum(illiq_x, 168L, align = "right")), by = symbol]
  p[, illiq_168h := data.table::fifelse(
    illiq_n_validas >= ceiling(cfg$illiquidity_positive_volume_coverage * 168),
    illiq_soma / illiq_n_validas, NA_real_)]
  obs <- p[!is.na(close), .(primeira_obs = min(t), ultima_obs = max(t)), by = symbol]
  p <- merge(p, obs, by = "symbol", all.x = TRUE, sort = FALSE)
  data.table::setorder(p, symbol, open_time)
  p[, observed_age_days := as.numeric(difftime(t, primeira_obs, units = "days"))]

  # Alvo entre fechamentos t e t+24h, por horario exato na grade.
  p[, close_t24 := data.table::shift(close, cfg$horizon_hours, type = "lead"), by = symbol]
  p[, ret_fwd_24h := close_t24 / close - 1]
  p[, y := as.integer(ret_fwd_24h < cfg$loss_threshold)]
  p[, `:=`(
    max_source_time = t,
    feature_available_at = t + cfg$availability_delay_seconds,
    forecast_at = t + cfg$availability_delay_seconds,
    label_end = t + cfg$horizon_hours * 3600,
    label_available_at = t + cfg$horizon_hours * 3600 + cfg$availability_delay_seconds
  )]
  p[, motivo_y_ausente := data.table::fifelse(
    !is.na(y), NA_character_,
    data.table::fifelse(is.na(close), "preco_t_ausente",
      data.table::fifelse(label_end > ultima_obs, "alem_da_coleta", "preco_t24_ausente")))]
  p[]
}

# Bloco M2: BTC, proxy de mercado da amostra, betas e estresse do BTC.
# A composicao da proxy usa apenas informacao de `t`: alvos candidatos com
# retorno valido e historico observado >= janela da rede.
construir_mercado <- function(ind, ativos, cfg) {
  alvos <- ativos[papel_proposto == "alvo_candidato", symbol_candidate]
  btc <- ativos[papel_proposto == "ancora_rede", symbol_candidate]
  d <- ind[, .(symbol, t, ret_1h, observed_age_days)]
  d[, contribui := symbol %in% alvos & !is.na(ret_1h) & observed_age_days >= cfg$graph_window_days]
  agg <- d[contribui == TRUE, .(soma_ret = sum(ret_1h), n_contrib = .N), by = t]
  out <- merge(ind, agg, by = "t", all.x = TRUE, sort = FALSE)
  out[is.na(n_contrib), `:=`(soma_ret = 0, n_contrib = 0L)]
  out <- merge(out, d[, .(symbol, t, contribui)], by = c("symbol", "t"), all.x = TRUE, sort = FALSE)
  # Exclui o proprio ativo da media quando ele contribui.
  out[, n_mkt := n_contrib - as.integer(contribui %in% TRUE)]
  out[, mkt_ret_1h := data.table::fifelse(
    n_mkt >= cfg$minimum_market_contributors,
    (soma_ret - data.table::fifelse(contribui %in% TRUE, ret_1h, 0)) / n_mkt, NA_real_)]
  data.table::setorder(out, symbol, t)
  out[, mkt_ret_24h := exp(soma_movel(log1p(mkt_ret_1h), 24L)) - 1, by = symbol]

  b <- ind[symbol == btc, .(t, btc_ret_1h = ret_1h, btc_ret_24h = ret_24h)]
  out <- merge(out, b, by = "t", all.x = TRUE, sort = FALSE)
  data.table::setorder(out, symbol, t)
  n_beta <- cfg$graph_window_days * 24L
  out[, `:=`(
    beta_btc_90d = beta_movel(ret_1h, btc_ret_1h, n_beta, cfg$pair_return_coverage),
    beta_mkt_90d = beta_movel(ret_1h, mkt_ret_1h, n_beta, cfg$pair_return_coverage)
  ), by = symbol]
  out[, s_btc := pmax(0, -btc_ret_24h)]
  out[, c("soma_ret", "n_contrib", "contribui") := NULL]
  out[, features_version := features_version]
  out[]
}

colunas_m1 <- c("ret_1h", "ret_24h", "ret_168h", "vol_24h", "vol_168h",
                "log_quote_volume_24h", "illiq_168h", "observed_age_days")
colunas_m2_extra <- c("btc_ret_1h", "btc_ret_24h", "mkt_ret_24h", "beta_btc_90d",
                      "beta_mkt_90d", "s_btc", "n_nodes")
colunas_m3_extra <- c("strength_mean", "katz_excess", "btc_exposure")
colunas_m4_extra <- c("btc_exposure_stress")

separar_tabelas <- function(feat) {
  chave <- c("symbol", "t", "forecast_at")
  alvo <- c(chave, "close", "close_t24", "ret_fwd_24h", "y", "label_end", "label_available_at",
            "motivo_y_ausente")
  atr <- setdiff(names(feat), c("close_t24", "ret_fwd_24h", "y", "label_end", "label_available_at",
                                "motivo_y_ausente", "illiq_x", "illiq_soma", "illiq_valida", "lr_1h"))
  list(features = feat[, ..atr], targets = feat[, ..alvo])
}
