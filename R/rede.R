# Etapa 5: rede dinamica de dependencia entre retornos (secao 11 do plano).
# Convencao: (A x)_i = soma_j A_ij x_j; linha i recebe, coluna j origina.
network_version <- "rede-1.0.0"

# Matriz horas x ativos de log-retornos com termino em (d - janela, d].
janela_retornos <- function(lr_wide, d, cfg) {
  inicio <- d - cfg$graph_window_days * 86400
  lr_wide[t > inicio & t <= d]
}

# Constroi um snapshot a partir da janela. Retorna NULL nos atributos quando
# o snapshot e invalido, registrando o motivo.
construir_snapshot <- function(janela, d, btc, cfg, kappa = cfg$katz_attenuation,
                               limiar = cfg$positive_correlation_threshold) {
  n_horas <- cfg$graph_window_days * 24L
  m <- as.matrix(janela[, !"t"])
  cobertura <- colSums(!is.na(m)) / n_horas
  variancia <- apply(m, 2, stats::var, na.rm = TRUE)
  elegiveis <- names(cobertura)[cobertura >= cfg$graph_return_coverage &
                                  is.finite(variancia) & variancia > 0]
  info <- list(graph_id = format(d, "%Y-%m-%d"), d = d, valido = FALSE, motivo = NA_character_,
               nodes = elegiveis, n_nodes = length(elegiveis), a_d = NA_real_,
               rho_A = NA_real_, n_arestas = 0L, network_version = network_version)
  if (nrow(janela) < n_horas * cfg$graph_return_coverage) {
    info$motivo <- "janela_incompleta"; return(info)
  }
  if (!(btc %in% elegiveis)) { info$motivo <- "btc_ausente"; return(info) }
  if (length(elegiveis) < cfg$minimum_graph_nodes) { info$motivo <- "poucos_nos"; return(info) }
  m <- m[, elegiveis, drop = FALSE]
  ok <- !is.na(m)
  pares <- crossprod(ok * 1)
  rho <- suppressWarnings(stats::cor(m, use = "pairwise.complete.obs"))
  rho[pares < ceiling(cfg$pair_return_coverage * n_horas) | !is.finite(rho)] <- 0
  B <- rho
  B[B < limiar] <- 0
  diag(B) <- 0
  B <- (B + t(B)) / 2
  a_d <- max(1, max(rowSums(B)))
  A <- B / a_d
  n <- length(elegiveis)
  I <- diag(n)
  rho_A <- max(Mod(eigen(A, symmetric = TRUE, only.values = TRUE)$values))
  if (!(kappa * rho_A < 1)) { info$motivo <- "multiplicador_divergente"; return(info) }
  Q <- solve(I - kappa * A)
  dimnames(Q) <- list(elegiveis, elegiveis)
  e_btc <- as.numeric(elegiveis == btc)
  katz <- as.numeric(solve(I - kappa * A, rep(1, n))) - 1
  expo <- as.numeric(solve(I - kappa * A, e_btc)) - e_btc
  stopifnot(isSymmetric(unname(B)), all(diag(B) == 0))
  # Intermediacao exploratoria: comprimento 1/B nas arestas retidas.
  g <- igraph::graph_from_adjacency_matrix(B, mode = "undirected", weighted = TRUE, diag = FALSE)
  btw <- if (igraph::ecount(g)) igraph::betweenness(g, weights = 1 / igraph::E(g)$weight,
                                                    normalized = TRUE) else stats::setNames(rep(0, n), elegiveis)
  info$valido <- TRUE
  info$a_d <- a_d; info$rho_A <- rho_A; info$n_arestas <- sum(B[upper.tri(B)] > 0)
  info$B <- B
  info$features <- data.table::data.table(
    graph_id = info$graph_id, symbol = elegiveis,
    strength_mean = rowSums(B) / (n - 1), katz_excess = katz, btc_exposure = expo,
    betweenness_w = as.numeric(btw[elegiveis]), n_nodes = n, a_d = a_d,
    cobertura_no = as.numeric(cobertura[elegiveis])
  )
  info
}

# Serie diaria de snapshots as 00h UTC. `retornos` tem colunas symbol, t, lr_1h.
construir_redes <- function(retornos, simbolos_rede, btc, cfg, inicio, fim, ...) {
  lr_wide <- data.table::dcast(retornos[symbol %in% simbolos_rede], t ~ symbol, value.var = "lr_1h")
  dias <- seq(as.POSIXct(format(inicio, "%Y-%m-%d"), tz = "UTC"),
              as.POSIXct(format(fim, "%Y-%m-%d"), tz = "UTC"), by = "day")
  snaps <- lapply(dias, function(d) construir_snapshot(janela_retornos(lr_wide, d, cfg), d, btc, cfg, ...))
  resumo <- data.table::rbindlist(lapply(snaps, function(s) data.table::data.table(
    graph_id = s$graph_id, d = s$d, valido = s$valido, motivo = s$motivo, n_nodes = s$n_nodes,
    a_d = s$a_d, rho_A = s$rho_A, n_arestas = s$n_arestas, nodes = paste(s$nodes, collapse = ";"),
    network_version = s$network_version)))
  feats <- data.table::rbindlist(lapply(snaps, `[[`, "features"))
  arestas <- data.table::rbindlist(lapply(snaps, function(s) {
    if (!s$valido) return(NULL)
    idx <- which(upper.tri(s$B) & s$B > 0, arr.ind = TRUE)
    if (!nrow(idx)) return(NULL)
    nm <- colnames(s$B)
    data.table::data.table(graph_id = s$graph_id, from = nm[idx[, 1]], to = nm[idx[, 2]],
                           weight = s$B[idx])
  }))
  list(resumo = resumo, features = feats, arestas = arestas)
}

# Associa cada origem t ao snapshot do dia: o snapshot de d vale para
# origens com t >= d, pois fica observavel em d + 60s = forecast_at de t = d.
juntar_rede <- function(feat, rede) {
  out <- data.table::copy(feat)
  out[, graph_id := format(t, "%Y-%m-%d", tz = "UTC")]
  # n_nodes do snapshot e controle de composicao (M2); os atributos por no sao M3.
  out <- merge(out, rede$resumo[, .(graph_id, graph_valido = valido, n_nodes)],
               by = "graph_id", all.x = TRUE, sort = FALSE)
  out[graph_valido %in% FALSE, n_nodes := NA_integer_]
  out <- merge(out, rede$features[, .(graph_id, symbol, strength_mean, katz_excess, btc_exposure,
                                      betweenness_w, a_d)],
               by = c("graph_id", "symbol"), all.x = TRUE, sort = FALSE)
  out[, btc_exposure_stress := btc_exposure * s_btc]
  out[]
}
