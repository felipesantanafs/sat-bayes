# Etapas 6-8: calendario temporal, modelos M0-M4 e calibracao (secoes 12-14).
models_version <- "modelos-1.0.0"

blocos_modelo <- function() {
  m1 <- colunas_m1
  m2 <- c(m1, colunas_m2_extra)
  m3 <- c(m2, colunas_m3_extra)
  list(M0 = character(), M1 = m1, M2 = m2, M3 = m3, M4 = c(m3, colunas_m4_extra))
}

fase_origem <- function(t, cfg) {
  data.table::fifelse(t < as.POSIXct("2022-01-01", tz = "UTC"), "inicializacao",
  data.table::fifelse(t < cfg$development_end_exclusive, "desenvolvimento",
  data.table::fifelse(t < cfg$operational_validation_end_exclusive, "validacao",
  data.table::fifelse(t < cfg$test_end_exclusive, "teste", "fora"))))
}

# Datas de ajuste: primeira hora UTC de cada mes. O ajuste ocorre em T + 60s.
calendario_ajustes <- function(cfg, primeiro_mes = as.POSIXct("2020-04-01", tz = "UTC")) {
  inicios <- seq(primeiro_mes, cfg$test_end_exclusive, by = "month")
  inicios <- inicios[inicios < cfg$test_end_exclusive]
  data.table::data.table(
    fit_id = format(inicios, "%Y-%m"), fit_at = inicios + cfg$availability_delay_seconds,
    T = inicios, prev_inicio = inicios,
    prev_fim = c(inicios[-1], cfg$test_end_exclusive),
    treino_inicio = pmax(inicios - cfg$training_window_days * 86400, cfg$analysis_start)
  )
}

# Indices de treino: origens no passado, rotulo ja disponivel no ajuste.
indices_treino <- function(amostra, aj) {
  which(amostra$t >= aj$treino_inicio & amostra$t < aj$T &
          amostra$label_available_at <= aj$fit_at & !is.na(amostra$y))
}

indices_previsao <- function(amostra, aj) {
  which(amostra$t >= aj$prev_inicio & amostra$t < aj$prev_fim)
}

# Escala estimada so no treino; exclui colunas constantes ou com desvio por
# classe abaixo do piso apos padronizar (regra de estabilidade do projeto).
preparar_escala <- function(x, y, piso) {
  centro <- colMeans(x); escala <- apply(x, 2, stats::sd)
  manter <- is.finite(escala) & escala > 0
  z <- sweep(sweep(x[, manter, drop = FALSE], 2, centro[manter]), 2, escala[manter], "/")
  sd0 <- apply(z[y == 0, , drop = FALSE], 2, stats::sd)
  sd1 <- apply(z[y == 1, , drop = FALSE], 2, stats::sd)
  ok <- sd0 >= piso & sd1 >= piso
  cols <- colnames(z)[ok]
  list(cols = cols, centro = centro[cols], escala = escala[cols],
       excluidas = setdiff(colnames(x), cols))
}

aplicar_escala <- function(x, esc) {
  sweep(sweep(x[, esc$cols, drop = FALSE], 2, esc$centro), 2, esc$escala, "/")
}

especificacoes <- function(cfg) {
  b <- names(blocos_modelo())
  ridge <- data.table::CJ(model_id = setdiff(b, "M0"), lambda = cfg$ridge_lambda_grid, sorted = FALSE)
  ridge[, algorithm := "ridge_logit"]
  nb <- data.table::data.table(model_id = setdiff(b, "M0"), lambda = NA_real_, algorithm = "gaussian_nb")
  m0 <- data.table::data.table(model_id = "M0", lambda = NA_real_, algorithm = "frequencia")
  s <- data.table::rbindlist(list(m0, nb, ridge), use.names = TRUE)
  s[, spec := sprintf("%s|%s|%s", model_id, algorithm, ifelse(is.na(lambda), "-", format(lambda)))]
  s[]
}

# Ajusta todos os blocos em um mes; devolve so as linhas previstas do mes,
# para que a matriz completa seja preenchida sem copias (memoria limitada).
ajustar_mes <- function(amostra, aj, specs, cfg) {
  tr <- indices_treino(amostra, aj); pr <- indices_previsao(amostra, aj)
  log <- list()
  if (!length(pr)) return(list(pr = pr, P = NULL, log = NULL))
  # P tem uma linha por origem prevista no mes (na ordem de `pr`).
  P <- matrix(NA_real_, length(pr), nrow(specs), dimnames = list(NULL, specs$spec))
  y <- amostra$y[tr]
  n1 <- sum(y == 1); n0 <- sum(y == 0)
  freq <- (n1 + 1) / (length(y) + 2)
  P[, specs[model_id == "M0", spec]] <- freq
  fallback_classe <- n1 < cfg$minimum_training_per_class || n0 < cfg$minimum_training_per_class
  for (b in setdiff(names(blocos_modelo()), "M0")) {
    s_b <- specs[model_id == b]
    reg <- data.table::data.table(fit_id = aj$fit_id, model_id = b, n_treino = length(tr), n1 = n1,
                                  n_previsao = length(pr), maior_label_usado = if (length(tr))
                                    max(amostra$label_available_at[tr]) else as.POSIXct(NA),
                                  fallback = NA_character_, excluidas = NA_character_)
    if (fallback_classe) {
      P[, s_b$spec] <- freq; reg$fallback <- "classe_insuficiente_M0"
      log[[b]] <- reg; next
    }
    cols <- blocos_modelo()[[b]]
    x <- as.matrix(amostra[tr, ..cols])
    esc <- preparar_escala(x, y, cfg$class_sd_floor_after_scaling)
    reg$excluidas <- paste(esc$excluidas, collapse = ";")
    if (!length(esc$cols)) { P[, s_b$spec] <- freq; reg$fallback <- "sem_colunas_M0"; log[[b]] <- reg; next }
    z <- aplicar_escala(x, esc)
    zp <- aplicar_escala(as.matrix(amostra[pr, ..cols]), esc)
    nb <- naivebayes::gaussian_naive_bayes(z, factor(y, levels = c("0", "1")))
    P[, s_b[algorithm == "gaussian_nb", spec]] <- predict(nb, zp, type = "prob")[, "1"]
    if (ncol(z) >= 2) {
      lam <- sort(cfg$ridge_lambda_grid, decreasing = TRUE)
      fit <- glmnet::glmnet(z, y, family = "binomial", alpha = cfg$ridge_alpha, lambda = lam,
                            standardize = FALSE)
      pp <- predict(fit, zp, s = lam, type = "response")
      for (k in seq_along(lam)) {
        P[, s_b[algorithm == "ridge_logit" & lambda == lam[k], spec]] <- pp[, k]
      }
    } else {
      g <- stats::glm(y ~ z, family = stats::binomial())
      P[, s_b[algorithm == "ridge_logit", spec]] <- stats::predict(
        g, newdata = data.frame(z = zp), type = "response")
      reg$fallback <- "uma_coluna_glm"
    }
    log[[b]] <- reg
  }
  list(pr = pr, P = P, log = data.table::rbindlist(log, fill = TRUE))
}

ajustar_todos <- function(amostra, cfg, ajustes = calendario_ajustes(cfg), progresso = TRUE) {
  specs <- especificacoes(cfg)
  P <- matrix(NA_real_, nrow(amostra), nrow(specs), dimnames = list(NULL, specs$spec))
  logs <- list()
  for (k in seq_len(nrow(ajustes))) {
    r <- ajustar_mes(amostra, ajustes[k], specs, cfg)
    if (length(r$pr)) P[r$pr, ] <- r$P
    logs[[k]] <- r$log
    rm(r); if (k %% 6 == 0) invisible(gc())
    if (progresso && k %% 12 == 0) message("Ajustes concluidos ate ", ajustes$fit_id[k])
  }
  list(P_raw = P, specs = specs, ajustes = ajustes, log = data.table::rbindlist(logs, fill = TRUE))
}

clip_prob <- function(p, eps) pmin(pmax(p, eps), 1 - eps)

# Calibrador sigmoide sobre previsoes fora da amostra dos 90 dias anteriores,
# com rotulos ja maturados; identidade quando falta suporte (secao 14).
ajustar_calibrador <- function(p, y, datas, cfg) {
  ok <- !is.na(p) & !is.na(y)
  p <- p[ok]; y <- y[ok]; datas <- datas[ok]
  if (sum(y == 1) < cfg$minimum_calibration_per_class || sum(y == 0) < cfg$minimum_calibration_per_class ||
      data.table::uniqueN(datas) < cfg$minimum_calibration_dates) {
    return(list(a = 0, b = 1, regra = "identidade_suporte"))
  }
  lp <- stats::qlogis(clip_prob(p, cfg$probability_clip))
  avisos <- character()
  g <- withCallingHandlers(
    tryCatch(stats::glm(y ~ lp, family = stats::binomial()), error = function(e) NULL),
    warning = function(w) { avisos <<- c(avisos, conditionMessage(w)); invokeRestart("muffleWarning") })
  if (is.null(g) || !g$converged || any(!is.finite(stats::coef(g))) || length(avisos)) {
    return(list(a = 0, b = 1, regra = "identidade_ajuste"))
  }
  list(a = unname(stats::coef(g)[1]), b = unname(stats::coef(g)[2]), regra = "sigmoide")
}

aplicar_calibrador <- function(p, cal, eps) {
  if (cal$regra != "sigmoide") return(p)
  stats::plogis(cal$a + cal$b * stats::qlogis(clip_prob(p, eps)))
}

calibrar_todos <- function(amostra, ajustados, cfg) {
  P <- ajustados$P_raw; Pc <- P; Pc[] <- NA_real_
  aj <- ajustados$ajustes; registros <- list()
  dia <- format(amostra$t, "%Y-%m-%d", tz = "UTC")
  for (k in seq_len(nrow(aj))) {
    a <- aj[k]
    pr <- indices_previsao(amostra, a)
    if (!length(pr)) next
    cal_idx <- which(amostra$t >= a$T - cfg$calibration_window_days * 86400 & amostra$t < a$T &
                       amostra$label_available_at <= a$fit_at & !is.na(amostra$y))
    for (s in colnames(P)) {
      cal <- ajustar_calibrador(P[cal_idx, s], amostra$y[cal_idx], dia[cal_idx], cfg)
      Pc[pr, s] <- aplicar_calibrador(P[pr, s], cal, cfg$probability_clip)
      registros[[length(registros) + 1L]] <- data.table::data.table(
        fit_id = a$fit_id, spec = s, regra = cal$regra, a = cal$a, b = cal$b, n_calibracao = length(cal_idx))
    }
  }
  list(P_cal = Pc, log = data.table::rbindlist(registros))
}

# Escolha de lambda por bloco no desenvolvimento: media dos Brier semestrais
# das probabilidades calibradas; empate dentro da tolerancia favorece maior lambda.
escolher_lambda <- function(amostra, P_cal, specs, cfg) {
  dev <- which(amostra$fase == "desenvolvimento" & !is.na(amostra$y))
  semestre <- paste0(format(amostra$t[dev], "%Y"), "-S", ifelse(as.integer(format(amostra$t[dev], "%m")) <= 6, 1, 2))
  r <- specs[algorithm == "ridge_logit"]
  r[, brier_dev := vapply(spec, function(s) {
    e <- (amostra$y[dev] - P_cal[dev, s])^2
    mean(tapply(e, semestre, mean, na.rm = TRUE))
  }, numeric(1))]
  escolha <- r[, {
    melhor <- min(brier_dev)
    cand <- lambda[brier_dev <= melhor + cfg$tuning_brier_tie_tolerance]
    .(lambda_escolhido = max(cand))
  }, by = model_id]
  list(grade = r, escolha = escolha)
}
