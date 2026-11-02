# Piloto limitado a tres arquivos mensais; nao executa a coleta integral.
# Fontes: https://github.com/binance/binance-public-data
# https://httr2.r-lib.org/reference/req_perform.html
# https://httr2.r-lib.org/reference/req_retry.html
if (!file.exists("config/projeto.R")) stop("Execute na raiz sat-bayes.")
source("config/projeto.R", encoding = "UTF-8")
required <- c("httr2", "jsonlite", "digest", "data.table")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Execute o preparo. Faltam: ", paste(missing, collapse = ", "))
Sys.setenv(TZ = "UTC")

run_id <- paste0(format(Sys.time(), "%Y%m%dT%H%M%S", tz = "UTC"), "_", Sys.getpid())
raw_dir <- file.path("dados", "brutos", "piloto", run_id)
clean_dir <- file.path("dados", "intermediarios", "piloto", run_id)
audit_dir <- file.path("resultados", "auditoria", run_id)
invisible(lapply(c(raw_dir, clean_dir, audit_dir), dir.create,
                 recursive = TRUE, showWarnings = FALSE))

download_file <- function(url, destination) {
  request <- httr2::request(url)
  request <- httr2::req_timeout(request, seconds = 30)
  request <- httr2::req_retry(request, max_tries = 4, retry_on_failure = TRUE)
  httr2::req_perform(request, path = destination)
  invisible(destination)
}

# A consulta atual e um snapshot, nao um catalogo historico de listagens.
metadata_ok <- tryCatch({
  download_file(paste0(cfg$market_data_api, "/exchangeInfo"),
                file.path(raw_dir, "exchangeInfo.json"))
  metadata <- jsonlite::read_json(file.path(raw_dir, "exchangeInfo.json"))
  if (!is.list(metadata$symbols) || !length(metadata$symbols)) {
    stop("Resposta nao contem o catalogo de symbols esperado.")
  }
  TRUE
}, error = function(e) {
  writeLines(conditionMessage(e), file.path(audit_dir, "erro_exchangeInfo.txt"))
  warning("Snapshot atual indisponivel; disponibilidade permanece pendente: ",
          conditionMessage(e))
  FALSE
})

column_names <- c(
  "open_time_raw", "open", "high", "low", "close", "base_volume",
  "close_time_raw", "quote_volume", "trade_count", "taker_buy_base_volume",
  "taker_buy_quote_volume", "ignore"
)
manifest <- list()
for (file_index in seq_len(nrow(cfg$pilot_files))) {
  symbol <- cfg$pilot_files$symbol[file_index]
  month <- cfg$pilot_files$month[file_index]
  filename <- paste0(symbol, "-", cfg$interval, "-", month, ".zip")
  url <- paste0(cfg$archive_base, "/monthly/klines/", symbol, "/",
                cfg$interval, "/", filename)
  zip_path <- file.path(raw_dir, filename)
  checksum_path <- paste0(zip_path, ".CHECKSUM")
  partial_path <- paste0(zip_path, ".part")
  download_file(paste0(url, ".CHECKSUM"), checksum_path)
  checksum_line <- readLines(checksum_path, n = 1L, warn = FALSE)
  if (length(checksum_line) != 1L) stop("Checksum vazio: ", url)
  expected_hash <- tolower(strsplit(trimws(checksum_line), "[[:space:]]+")[[1]][1])
  if (!grepl("^[0-9a-f]{64}$", expected_hash)) stop("Checksum SHA-256 invalido.")
  download_file(url, partial_path)
  actual_hash <- digest::digest(file = partial_path, algo = "sha256", serialize = FALSE)
  if (!identical(tolower(actual_hash), expected_hash)) {
    stop("Checksum divergente. Arquivo mantido como .part: ", partial_path)
  }
  if (!file.rename(partial_path, zip_path)) stop("Nao foi possivel finalizar o ZIP.")

  zip_listing <- utils::unzip(zip_path, list = TRUE)
  expected_csv <- sub("\\.zip$", ".csv", filename)
  if (nrow(zip_listing) != 1L || zip_listing$Name[1] != expected_csv) {
    stop("Conteudo ZIP inesperado; revisar antes de extrair: ", zip_path)
  }
  utils::unzip(zip_path, files = expected_csv, exdir = clean_dir)
  csv_path <- file.path(clean_dir, expected_csv)
  tab <- data.table::fread(file = csv_path, header = FALSE, colClasses = "character")
  if (ncol(tab) != 12L || !nrow(tab)) stop("Esquema de candles inesperado.")
  data.table::setnames(tab, column_names)
  if (any(!grepl("^[0-9]+$", tab$open_time_raw)) ||
      any(!grepl("^[0-9]+$", tab$close_time_raw))) {
    stop("Timestamp ou cabecalho inesperado; nao descartar linhas silenciosamente.")
  }
  # Unidade definida pela fonte/tipo/data; conferir plausibilidade apos converter.
  divisor <- if (month >= "2025-01") 1e6 else 1e3
  tab[, open_time := as.POSIXct(as.numeric(open_time_raw) / divisor,
                              origin = "1970-01-01", tz = "UTC")]
  tab[, close_time_source := as.POSIXct(as.numeric(close_time_raw) / divisor,
                                      origin = "1970-01-01", tz = "UTC")]
  tab[, candle_end := open_time + 3600]
  numeric_columns <- setdiff(column_names, c("open_time_raw", "close_time_raw", "ignore"))
  for (column in numeric_columns) {
    values <- suppressWarnings(as.numeric(tab[[column]]))
    if (any(!is.finite(values))) stop("Campo numerico invalido: ", column)
    data.table::set(tab, j = column, value = values)
  }
  data.table::setorder(tab, open_time)
  month_start <- as.POSIXct(paste0(month, "-01 00:00:00"), tz = "UTC")
  month_end <- seq(month_start, by = "month", length.out = 2L)[2]
  if (any(tab$open_time < month_start | tab$open_time >= month_end)) {
    stop("Datas fora do mes do arquivo: ", filename)
  }
  if (anyDuplicated(tab$open_time)) stop("Chave de candle duplicada.")
  if (any(tab$low <= 0 | tab$open <= 0 | tab$high <= 0 | tab$close <= 0) ||
      any(tab$low > pmin(tab$open, tab$close) | tab$high < pmax(tab$open, tab$close)) ||
      any(tab$high < tab$low)) stop("Inconsistencia OHLC.")
  if (any(tab$base_volume < 0 | tab$quote_volume < 0 | tab$trade_count < 0) ||
      any(tab$trade_count != floor(tab$trade_count))) stop("Volume ou contagem invalida.")
  if (any(tab$taker_buy_base_volume < 0 |
          tab$taker_buy_base_volume > tab$base_volume + 1e-8) ||
      any(tab$taker_buy_quote_volume < 0 |
          tab$taker_buy_quote_volume > tab$quote_volume + 1e-8)) {
    stop("Volume agressor inconsistente.")
  }
  close_error <- abs(as.numeric(tab$close_time_source) -
                     (as.numeric(tab$open_time) + 3600 - 1 / divisor))
  if (any(close_error > 1e-4)) stop("Fim de candle ou unidade temporal inconsistente.")
  expected_rows <- as.integer(difftime(month_end, month_start, units = "hours"))
  tab[, symbol := symbol]
  saveRDS(tab, file.path(clean_dir, sub("\\.zip$", ".rds", filename)))
  manifest[[file_index]] <- data.frame(
    run_id = run_id, symbol = symbol, month = month, source_url = url,
    sha256 = actual_hash, timestamp_unit = if (divisor == 1e6) "us" else "ms",
    observed_rows = nrow(tab), expected_calendar_rows = expected_rows,
    gaps = sum(diff(as.numeric(tab$open_time)) != 3600),
    exchange_info_snapshot_ok = metadata_ok,
    extracted_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    stringsAsFactors = FALSE
  )
  data.table::fwrite(data.table::rbindlist(manifest), file.path(audit_dir, "manifesto_piloto.csv"))
  message("Verificado: ", filename, " (", nrow(tab), " candles)")
}
writeLines(capture.output(sessionInfo()), file.path(audit_dir, "session_info.txt"))
message("Piloto concluido: ", audit_dir,
        ". Nenhuma rede ou modelo foi estimado; audite o manifesto antes da coleta integral.")
