# Etapa 3: normalizacao e auditoria do painel horario (secao 9 do plano).
parser_version <- "painel-1.0.0"

colunas_klines <- c(
  "open_time_raw", "open", "high", "low", "close", "base_volume",
  "close_time_raw", "quote_volume", "trade_count", "taker_buy_base_volume",
  "taker_buy_quote_volume", "ignore"
)

# Unidade dos timestamps dos arquivos spot: ms antes de 2025-01-01, us depois
# (Binance Public Data README). A magnitude e conferida apos converter.
divisor_timestamp_arquivo <- function(periodo) {
  if (substr(periodo, 1, 7) >= "2025-01") 1e6 else 1e3
}

# Valida um bloco de candles ja com colunas nomeadas e tipadas. Lanca erro
# com motivo explicito; nada e descartado silenciosamente.
validar_candles <- function(tab, inicio, fim_exclusivo, divisor, rotulo) {
  if (any(!grepl("^[0-9]+$", tab$open_time_raw)) || any(!grepl("^[0-9]+$", tab$close_time_raw))) {
    stop("Timestamp ou cabecalho inesperado: ", rotulo)
  }
  tab[, open_time := as.POSIXct(as.numeric(open_time_raw) / divisor, origin = "1970-01-01", tz = "UTC")]
  tab[, close_time_source := as.POSIXct(as.numeric(close_time_raw) / divisor, origin = "1970-01-01", tz = "UTC")]
  num <- setdiff(colunas_klines, c("open_time_raw", "close_time_raw", "ignore"))
  for (column in num) {
    values <- suppressWarnings(as.numeric(tab[[column]]))
    if (any(!is.finite(values))) stop("Campo numerico invalido (", column, "): ", rotulo)
    data.table::set(tab, j = column, value = values)
  }
  if (any(tab$open_time < inicio | tab$open_time >= fim_exclusivo)) stop("Datas fora do periodo: ", rotulo)
  if (anyDuplicated(tab$open_time)) stop("Chave de candle duplicada: ", rotulo)
  # Aberturas fora da grade (ex.: reinicio apos parada em 2018-02) nao
  # correspondem a nenhuma hora UTC; ficam marcadas e fora do painel.
  tab[, fora_grade := abs(as.numeric(open_time) %% 3600) > 1e-6]
  if (mean(tab$fora_grade) > 0.5) stop("Abertura fora da grade horaria na maior parte do arquivo: ", rotulo)
  if (any(tab$low <= 0 | tab$open <= 0 | tab$high <= 0 | tab$close <= 0) ||
      any(tab$low > pmin(tab$open, tab$close) | tab$high < pmax(tab$open, tab$close))) {
    stop("Inconsistencia OHLC: ", rotulo)
  }
  if (any(tab$base_volume < 0 | tab$quote_volume < 0 | tab$trade_count < 0) ||
      any(tab$trade_count != floor(tab$trade_count))) stop("Volume ou contagem invalida: ", rotulo)
  tol <- 1e-8
  if (any(tab$taker_buy_base_volume < 0 | tab$taker_buy_base_volume > tab$base_volume * (1 + tol) + tol) ||
      any(tab$taker_buy_quote_volume < 0 | tab$taker_buy_quote_volume > tab$quote_volume * (1 + tol) + tol)) {
    stop("Volume agressor inconsistente: ", rotulo)
  }
  erro_fim <- as.numeric(tab$close_time_source) - (as.numeric(tab$open_time) + 3600 - 1 / divisor)
  # Unidade errada desloca todos os candles; um candle isolado encerrado antes
  # da hora (paradas da exchange) e marcado, nao descartado em silencio.
  if (stats::median(abs(erro_fim)) > 1e-3) {
    stop("Fim de candle ou unidade temporal inconsistente: ", rotulo)
  }
  tab[, fim_irregular := abs(erro_fim) > 1e-3]
  tab[, candle_end := open_time + 3600]
  data.table::setorder(tab, open_time)
  tab[]
}

periodo_limites <- function(frequencia, periodo) {
  if (frequencia == "monthly") {
    ini <- as.POSIXct(paste0(periodo, "-01 00:00:00"), tz = "UTC")
    fim <- seq(ini, by = "month", length.out = 2L)[2]
  } else {
    ini <- as.POSIXct(paste0(periodo, " 00:00:00"), tz = "UTC")
    fim <- ini + 86400
  }
  list(inicio = ini, fim = fim)
}

ler_klines_zip <- function(zip_path, symbol, frequencia, periodo, sha256) {
  csv <- sub("\\.zip$", ".csv", basename(zip_path))
  tmp <- garantir_dir(file.path(tempdir(), "klines"))
  utils::unzip(zip_path, files = csv, exdir = tmp, overwrite = TRUE)
  csv_path <- file.path(tmp, csv)
  on.exit(unlink(csv_path), add = TRUE)
  tab <- data.table::fread(file = csv_path, header = FALSE, colClasses = "character")
  if (ncol(tab) != 12L || !nrow(tab)) stop("Esquema de candles inesperado: ", basename(zip_path))
  data.table::setnames(tab, colunas_klines)
  lim <- periodo_limites(frequencia, periodo)
  tab <- validar_candles(tab, lim$inicio, lim$fim, divisor_timestamp_arquivo(periodo), basename(zip_path))
  tab[, `:=`(symbol = symbol, origem = frequencia, periodo_fonte = periodo, source_sha256 = sha256)]
  tab[]
}

# Klines da API: timestamps em ms (sem `timeUnit`), registrados como tal.
ler_klines_api <- function(klines, symbol, inicio, fim_exclusivo) {
  tab <- data.table::as.data.table(klines)
  if (ncol(tab) != 12L) stop("Esquema inesperado na API: ", symbol)
  data.table::setnames(tab, colunas_klines)
  for (column in names(tab)) data.table::set(tab, j = column, value = as.character(tab[[column]]))
  tab <- validar_candles(tab, inicio, fim_exclusivo, 1e3, paste0("API ", symbol))
  tab[, `:=`(symbol = symbol, origem = "api", periodo_fonte = NA_character_, source_sha256 = NA_character_)]
  tab[]
}

colunas_valor <- c("open", "high", "low", "close", "base_volume", "quote_volume", "trade_count",
                   "taker_buy_base_volume", "taker_buy_quote_volume")

# Consolida fontes de um simbolo. Copias identicas sao deduplicadas; conflitos
# sao registrados e resolvidos pela regra fixa arquivo > API, definida antes
# de qualquer modelo (nao por desempenho).
consolidar_simbolo <- function(blocos) {
  tab <- data.table::rbindlist(blocos, fill = TRUE)
  tab[, prioridade := data.table::fifelse(origem == "api", 2L, 1L)]
  data.table::setorder(tab, open_time, prioridade)
  tab[, n_versoes := .N, by = open_time]
  dup <- tab[n_versoes > 1]
  conflitos <- data.table::data.table()
  if (nrow(dup)) {
    assinatura <- dup[, .(distintas = data.table::uniqueN(.SD)), by = open_time, .SDcols = colunas_valor]
    conflitos <- assinatura[distintas > 1]
  }
  tab <- tab[, .SD[1], by = open_time]
  tab[, c("prioridade", "n_versoes") := NULL]
  list(candles = tab[], duplicatas = nrow(dup), conflitos = conflitos)
}

# Grade UTC de 1h entre a primeira e a ultima abertura observadas. Ausencias
# viram NA com motivo; candles com zero negociacoes sao marcados a parte.
gradear_simbolo <- function(candles, symbol) {
  na_grade <- candles[fora_grade %in% FALSE]
  grade <- data.table::data.table(open_time = seq(min(na_grade$open_time), max(na_grade$open_time), by = 3600))
  out <- merge(grade, na_grade, by = "open_time", all.x = TRUE, sort = TRUE)
  out[, fora_grade := NULL]
  out[, symbol := symbol]
  out[, candle_end := open_time + 3600]
  out[, motivo_ausencia := data.table::fifelse(is.na(close), "sem_linha_na_fonte", NA_character_)]
  # Candle encerrado antes da hora nao representa o fechamento em candle_end.
  irr <- which(out$fim_irregular %in% TRUE)
  if (length(irr)) {
    for (column in colunas_valor) data.table::set(out, i = irr, j = column, value = NA_real_)
    data.table::set(out, i = irr, j = "motivo_ausencia", value = "fim_candle_irregular")
  }
  out[, atividade_zero := !is.na(trade_count) & trade_count == 0]
  out[]
}

construir_painel <- function(manifesto, api_klines, cfg, out_dir) {
  ok <- manifesto[situacao == "disponivel" & !is.na(local_path)]
  simbolos <- unique(c(ok$symbol, names(api_klines)))
  qualidade <- list(); paineis <- list()
  for (s in simbolos) {
    arq <- ok[symbol == s]
    blocos <- lapply(seq_len(nrow(arq)), function(k) {
      ler_klines_zip(arq$local_path[k], s, arq$frequencia[k], arq$periodo[k], arq$sha256_calculado[k])
    })
    api <- api_klines[[s]]
    if (!is.null(api)) {
      blocos[[length(blocos) + 1L]] <- ler_klines_api(api$klines, s, api$inicio, cfg$raw_open_time_end_exclusive)
    }
    if (!length(blocos)) next
    cons <- consolidar_simbolo(blocos)
    c_s <- cons$candles[open_time < cfg$raw_open_time_end_exclusive]
    g <- gradear_simbolo(c_s, s)
    qualidade[[s]] <- data.table::data.table(
      symbol = s, primeira_abertura = min(c_s$open_time), ultima_abertura = max(c_s$open_time),
      horas_grade = nrow(g), horas_observadas = sum(!is.na(g$close)),
      horas_ausentes = sum(is.na(g$close)), horas_atividade_zero = sum(g$atividade_zero),
      candles_fim_irregular = sum(g$motivo_ausencia %in% "fim_candle_irregular"),
      candles_fora_grade = sum(c_s$fora_grade),
      linhas_duplicadas = cons$duplicatas, conflitos = nrow(cons$conflitos),
      arquivos_mensais = sum(arq$frequencia == "monthly"), arquivos_diarios = sum(arq$frequencia == "daily"),
      linhas_api = if (is.null(api)) 0L else nrow(api$klines), parser_version = parser_version
    )
    anom <- c_s[fora_grade | fim_irregular, .(symbol, open_time_raw, close_time_raw, open_time,
                                              close_time_source, fora_grade, fim_irregular, origem, periodo_fonte)]
    if (nrow(anom)) {
      data.table::fwrite(anom, file.path(garantir_dir(file.path(out_dir, "anomalias")), paste0(s, ".csv")))
    }
    if (nrow(cons$conflitos)) {
      data.table::fwrite(cons$conflitos, file.path(garantir_dir(file.path(out_dir, "conflitos")),
                                                   paste0(s, ".csv")))
    }
    paineis[[s]] <- g
  }
  painel <- data.table::rbindlist(paineis, fill = TRUE)
  painel[, ano := as.integer(format(open_time, "%Y"))]
  painel[, parser_version := parser_version]
  list(painel = painel, qualidade = data.table::rbindlist(qualidade))
}

gravar_painel <- function(painel, dir) {
  if (dir.exists(dir)) unlink(dir, recursive = TRUE)
  arrow::write_dataset(painel, dir, format = "parquet", partitioning = c("symbol", "ano"))
  invisible(dir)
}

ler_painel <- function(dir = file.path("dados", "intermediarios", "candles"), simbolos = NULL) {
  painel <- data.table::as.data.table(as.data.frame(arrow::open_dataset(dir)))
  painel[, symbol := as.character(symbol)]
  if (!is.null(simbolos)) painel <- painel[symbol %in% simbolos]
  data.table::setorder(painel, symbol, open_time)
  painel[]
}
