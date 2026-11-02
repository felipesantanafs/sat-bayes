# Testes com dados sinteticos das propriedades exigidas pelo plano.
# Executar na raiz: Rscript tests/testes_unitarios.R
Sys.setenv(TZ = "UTC")
for (f in c("R/utils.R", "R/coleta.R", "R/painel.R", "R/atributos.R", "R/rede.R", "R/modelos.R",
            "R/avaliacao.R")) source(f, encoding = "UTF-8")
cfg <- carregar_cfg()
falhas <- 0L
testar <- function(nome, expr) {
  ok <- tryCatch(isTRUE(expr), error = function(e) { message("  erro: ", conditionMessage(e)); FALSE })
  message(if (ok) "ok    " else "FALHA ", nome)
  if (!ok) falhas <<- falhas + 1L
}

# --- classificacao HTTP -------------------------------------------------------
testar("404 nao vira disponivel", classificar_http(404L) == "nao_localizado")
testar("429 e transitorio", classificar_http(429L) == "erro_transitorio")
testar("falha de rede e transitoria", classificar_http(NA_integer_) == "erro_transitorio")

# --- unidade temporal ----------------------------------------------------------
testar("ms antes de 2025", divisor_timestamp_arquivo("2024-12") == 1e3)
testar("us desde 2025", divisor_timestamp_arquivo("2025-01-15") == 1e6)

# --- painel e alvo ---------------------------------------------------------------
set.seed(1)
horas <- seq(as.POSIXct("2024-01-01", tz = "UTC"), by = 3600, length.out = 400)
painel_sint <- function(sym, precos) data.table::data.table(
  symbol = sym, open_time = horas, candle_end = horas + 3600, close = precos,
  quote_volume = 100, trade_count = 10)
p <- painel_sint("AAAUSDT", 100 * cumprod(1 + rnorm(400, 0, 0.01)))
p$close[200] <- NA
ind <- construir_individuais(p, cfg)
testar("alvo usa t+24h exato", {
  k <- 50; isTRUE(all.equal(ind$ret_fwd_24h[k], ind$close[k + 24] / ind$close[k] - 1))
})
testar("lacuna anula retorno e alvo dependentes", is.na(ind$ret_1h[201]) && is.na(ind$y[176]) && is.na(ind$vol_24h[210]))
testar("rotulo disponivel apos label_end + atraso",
       all(ind$label_available_at == ind$t + 24 * 3600 + cfg$availability_delay_seconds))
testar("atributos nao usam o futuro", {
  ind2 <- construir_individuais(data.table::copy(p)[open_time <= horas[300]], cfg)
  a <- ind[t <= horas[300] + 3600, colunas_m1, with = FALSE]
  b <- ind2[, colunas_m1, with = FALSE]
  isTRUE(all.equal(a, b))
})

# --- rede ----------------------------------------------------------------------
btc <- "BTCUSDT"
testar("rede sem arestas gera Q = I", {
  B <- matrix(0, 5, 5); A <- B
  Q <- solve(diag(5) - cfg$katz_attenuation * A)
  all(Q == diag(5))
})
testar("normalizacao por linha tornaria Katz constante", {
  B <- matrix(runif(25), 5); B <- (B + t(B)) / 2; diag(B) <- 0
  Tm <- B / rowSums(B)
  k <- solve(diag(5) - 0.5 * Tm, rep(1, 5))
  isTRUE(all.equal(as.numeric(k), rep(1 / (1 - 0.5), 5)))
})
testar("snapshot valido: simetria, espectro e exposicao", {
  n <- 2160
  f <- rnorm(n)
  m <- sapply(1:6, function(j) 0.7 * f + rnorm(n))
  colnames(m) <- c(btc, paste0("X", 1:5, "USDT"))
  jan <- data.table::data.table(t = seq_len(n), m)
  s <- construir_snapshot(jan, as.POSIXct("2024-06-01", tz = "UTC"), btc, cfg)
  s$valido && cfg$katz_attenuation * s$rho_A < 1 && max(rowSums(s$B / s$a_d)) <= 1 + 1e-12 &&
    all(s$features$btc_exposure[s$features$symbol != btc] > 0) &&
    s$features$btc_exposure[s$features$symbol == btc] >= 0
})
testar("snapshot sem BTC e invalido", {
  n <- 2160
  m <- matrix(rnorm(n * 5), n, 5, dimnames = list(NULL, paste0("X", 1:5, "USDT")))
  jan <- data.table::data.table(t = seq_len(n), m)
  s <- construir_snapshot(jan, as.POSIXct("2024-06-01", tz = "UTC"), btc, cfg)
  !s$valido && s$motivo == "btc_ausente"
})

# --- treino e calibracao -------------------------------------------------------
testar("treino so usa rotulos ja disponiveis", {
  am <- data.table::data.table(t = seq(as.POSIXct("2023-01-01", tz = "UTC"), by = 3600, length.out = 24 * 120))
  am[, label_available_at := t + 24 * 3600 + 60]
  am[, y := 0L]
  aj <- calendario_ajustes(cfg, as.POSIXct("2023-04-01", tz = "UTC"))[1]
  tr <- indices_treino(am, aj)
  all(am$label_available_at[tr] <= aj$fit_at) && max(am$t[tr]) == aj$T - 24 * 3600
})
testar("calibrador sem suporte vira identidade", {
  cal <- ajustar_calibrador(runif(20), rbinom(20, 1, 0.5), rep("2024-01-01", 20), cfg)
  cal$regra == "identidade_suporte"
})
testar("calibrador corrige vies conhecido", {
  n <- 20000; z <- rnorm(n); p_true <- plogis(-2 + z); y <- rbinom(n, 1, p_true)
  p_ruim <- plogis(-2 + 2 * z)
  cal <- ajustar_calibrador(p_ruim, y, rep(as.character(1:100), length.out = n), cfg)
  cal$regra == "sigmoide" && abs(cal$b - 0.5) < 0.1
})

# --- avaliacao -----------------------------------------------------------------
testar("metricas com uma classe ficam NA com motivo", {
  m <- metricas_prob(c(0, 0, 0), c(0.1, 0.2, 0.3)); is.na(m$roc_auc) && m$motivo_na == "uma_classe"
})
testar("bootstrap preserva razao soma(S)/soma(N)", {
  d <- data.table::data.table(dia = as.Date("2024-01-01") + 0:99, S_d = rnorm(100), N_d = rpois(100, 10) + 1L)
  r <- bootstrap_delta(d, 7L, 200L, 1L)
  isTRUE(all.equal(r$estimativa, sum(d$S_d) / sum(d$N_d)))
})

if (falhas) stop(falhas, " teste(s) falharam") else message("Todos os testes passaram.")
