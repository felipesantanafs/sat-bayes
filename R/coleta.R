# Etapas 1-2: auditoria de candidatos e extracao do historico completo.
# Fontes: https://github.com/binance/binance-public-data (arquivos, checksums)
# e https://developers.binance.com/en/docs/catalog/core-trading-spot-trading/api/rest-api/market

s3_listing_base <- "https://s3-ap-northeast-1.amazonaws.com/data.binance.vision"

# Lista objetos publicados sob um prefixo do repositorio publico. O listing e
# paginado em 1000 chaves; segue `NextMarker`/ultima chave ate esgotar.
listar_objetos_binance <- function(prefix) {
  chaves <- character(); tamanhos <- numeric(); marker <- ""
  repeat {
    url <- paste0(s3_listing_base, "?delimiter=/&prefix=", utils::URLencode(prefix, reserved = TRUE),
                  if (nzchar(marker)) paste0("&marker=", utils::URLencode(marker, reserved = TRUE)) else "")
    r <- requisitar(url, timeout = 60)
    if (r$situacao != "disponivel") {
      stop("Listing indisponivel (", r$situacao, ", HTTP ", r$status, "): ", prefix)
    }
    xml <- httr2::resp_body_string(r$resp)
    blocos <- regmatches(xml, gregexpr("<Contents>.*?</Contents>", xml, perl = TRUE))[[1]]
    k <- sub(".*<Key>([^<]*)</Key>.*", "\\1", blocos)
    s <- as.numeric(sub(".*<Size>([^<]*)</Size>.*", "\\1", blocos))
    chaves <- c(chaves, k); tamanhos <- c(tamanhos, s)
    truncado <- grepl("<IsTruncated>true</IsTruncated>", xml, fixed = TRUE)
    if (!truncado || !length(k)) break
    marker <- utils::tail(k, 1)
  }
  data.table::data.table(s3_key = chaves, size = tamanhos)
}

# Arquivos de klines (.zip) de um simbolo, com a data do periodo extraida do nome.
listar_klines <- function(symbol, frequencia = c("monthly", "daily"), cfg) {
  frequencia <- match.arg(frequencia)
  prefix <- paste0("data/spot/", frequencia, "/klines/", symbol, "/", cfg$interval, "/")
  obj <- listar_objetos_binance(prefix)
  zips <- obj[grepl("\\.zip$", s3_key)]
  if (!nrow(zips)) {
    return(data.table::data.table(s3_key = character(), size = numeric(), periodo = character()))
  }
  padrao <- if (frequencia == "monthly") "([0-9]{4}-[0-9]{2})\\.zip$" else "([0-9]{4}-[0-9]{2}-[0-9]{2})\\.zip$"
  zips[, periodo := regmatches(s3_key, regexpr(padrao, s3_key))]
  zips[, periodo := sub("\\.zip$", "", periodo)]
  zips[]
}

# Calendario de meses de busca: agosto/2017 ate o mes da ultima abertura bruta.
meses_busca <- function(cfg) {
  ultimo <- as.Date(cfg$raw_open_time_end_exclusive - 1, tz = "UTC")
  inicio <- cfg$archive_start_month
  fim <- as.Date(format(ultimo, "%Y-%m-01"))
  format(seq(inicio, fim, by = "month"), "%Y-%m")
}

# Dias de um mes, limitados a aberturas anteriores ao corte bruto.
dias_do_mes <- function(mes, cfg) {
  inicio <- as.Date(paste0(mes, "-01"))
  fim <- seq(inicio, by = "month", length.out = 2L)[2] - 1
  limite <- as.Date(cfg$raw_open_time_end_exclusive - 1, tz = "UTC")
  dias <- seq(inicio, min(fim, limite), by = "day")
  format(dias, "%Y-%m-%d")
}

caminho_bruto <- function(raw_root, frequencia, symbol, cfg, filename) {
  file.path(raw_root, "binance", "spot", frequencia, "klines", symbol, cfg$interval, filename)
}

# Baixa um ZIP e seu .CHECKSUM, verifica SHA-256 e preserva versoes antigas.
# Retorna uma linha do manifesto; nunca descarta silenciosamente uma falha.
baixar_zip_verificado <- function(symbol, frequencia, periodo, cfg, raw_root, run_id) {
  filename <- paste0(symbol, "-", cfg$interval, "-", periodo, ".zip")
  url <- paste0(cfg$archive_base, "/", frequencia, "/klines/", symbol, "/",
                cfg$interval, "/", filename)
  destino <- caminho_bruto(raw_root, frequencia, symbol, cfg, filename)
  garantir_dir(dirname(destino))
  linha <- list(
    run_id = run_id, symbol = symbol, frequencia = frequencia, periodo = periodo,
    source_url = url, status_http = NA_integer_, situacao = NA_character_,
    sha256_esperado = NA_character_, sha256_calculado = NA_character_,
    bytes = NA_real_, local_path = destino, reutilizado_cache = FALSE,
    versao_anterior = NA_character_, consultado_utc = agora_utc(), erro = NA_character_
  )
  checksum_path <- paste0(destino, ".CHECKSUM")
  ck_tmp <- paste0(checksum_path, ".part")
  r <- requisitar(paste0(url, ".CHECKSUM"), path = ck_tmp)
  linha$status_http <- r$status
  if (r$situacao != "disponivel") {
    linha$situacao <- r$situacao; linha$erro <- r$erro
    return(data.table::as.data.table(linha))
  }
  ck_line <- readLines(ck_tmp, n = 1L, warn = FALSE)
  esperado <- tolower(strsplit(trimws(ck_line), "[[:space:]]+")[[1]][1])
  if (!length(esperado) || !grepl("^[0-9a-f]{64}$", esperado)) {
    linha$situacao <- "esquema_inesperado"; linha$erro <- "CHECKSUM sem SHA-256 valido"
    unlink(ck_tmp)
    return(data.table::as.data.table(linha))
  }
  linha$sha256_esperado <- esperado

  if (file.exists(destino)) {
    atual <- sha256_arquivo(destino)
    if (identical(atual, esperado)) {
      file.rename(ck_tmp, checksum_path)
      linha$situacao <- "disponivel"; linha$sha256_calculado <- atual
      linha$bytes <- file.size(destino); linha$reutilizado_cache <- TRUE
      return(data.table::as.data.table(linha))
    }
    # A fonte mudou: preservar a versao anterior antes de baixar a nova.
    versoes <- garantir_dir(file.path(dirname(destino), "versoes"))
    anterior <- file.path(versoes, paste0(substr(atual, 1, 16), "_", filename))
    file.rename(destino, anterior)
    linha$versao_anterior <- anterior
  }

  parcial <- paste0(destino, ".part")
  r <- requisitar(url, path = parcial, timeout = 120)
  linha$status_http <- r$status
  if (r$situacao != "disponivel") {
    linha$situacao <- r$situacao; linha$erro <- r$erro; unlink(ck_tmp)
    return(data.table::as.data.table(linha))
  }
  calculado <- sha256_arquivo(parcial)
  linha$sha256_calculado <- calculado; linha$bytes <- file.size(parcial)
  if (!identical(calculado, esperado)) {
    # Mantido como .part para inspecao; nao alimenta o painel.
    linha$situacao <- "checksum_divergente"; unlink(ck_tmp)
    return(data.table::as.data.table(linha))
  }
  listagem <- utils::unzip(parcial, list = TRUE)
  csv_esperado <- sub("\\.zip$", ".csv", filename)
  if (nrow(listagem) != 1L || listagem$Name[1] != csv_esperado) {
    linha$situacao <- "esquema_inesperado"; linha$erro <- "Conteudo ZIP inesperado"
    unlink(ck_tmp)
    return(data.table::as.data.table(linha))
  }
  file.rename(parcial, destino); file.rename(ck_tmp, checksum_path)
  linha$situacao <- "disponivel"
  data.table::as.data.table(linha)
}

# Klines pela API publica para lacunas pequenas ou periodo recente (secao 8.3).
# Pagina pelo ultimo open time + 1 intervalo; cursor parado interrompe.
baixar_klines_api <- function(symbol, inicio, fim_exclusivo, cfg, raw_root, run_id) {
  passo_ms <- 3600 * 1000
  cursor <- as.numeric(inicio) * 1000
  fim_ms <- as.numeric(fim_exclusivo) * 1000 - 1
  dir_json <- garantir_dir(file.path(raw_root, "binance", "api", "klines", symbol, cfg$interval))
  linhas <- list(); paginas <- list()
  repeat {
    if (cursor > fim_ms) break
    url <- paste0(cfg$market_data_api, "/klines?symbol=", symbol, "&interval=", cfg$interval,
                  "&startTime=", format(cursor, scientific = FALSE),
                  "&endTime=", format(fim_ms, scientific = FALSE), "&limit=1000")
    r <- requisitar(url)
    pag <- data.table::data.table(run_id = run_id, symbol = symbol, source_url = url,
                                  status_http = r$status, situacao = r$situacao,
                                  consultado_utc = agora_utc(), local_path = NA_character_,
                                  linhas = 0L, erro = r$erro)
    if (r$situacao != "disponivel") { paginas[[length(paginas) + 1L]] <- pag; break }
    corpo <- httr2::resp_body_string(r$resp)
    arquivo <- file.path(dir_json, paste0(symbol, "_", format(cursor, scientific = FALSE), "_", run_id, ".json"))
    writeLines(corpo, arquivo, useBytes = TRUE)
    dados <- jsonlite::fromJSON(corpo, simplifyVector = TRUE)
    pag$local_path <- arquivo
    paginas[[length(paginas) + 1L]] <- pag
    if (!length(dados) || !nrow(dados)) break
    pag$linhas <- nrow(dados); paginas[[length(paginas)]] <- pag
    linhas[[length(linhas) + 1L]] <- dados
    ultimo <- as.numeric(dados[nrow(dados), 1])
    proximo <- ultimo + passo_ms
    if (proximo <= cursor) stop("Cursor da API nao avancou para ", symbol)
    cursor <- proximo
  }
  list(klines = if (length(linhas)) do.call(rbind, linhas) else NULL,
       manifesto = data.table::rbindlist(paginas, fill = TRUE))
}

# Snapshot atual do catalogo e cruzamento com os candidatos (Etapa 1).
# O endpoint descreve informacoes atuais; nao e catalogo historico.
auditar_exchange_info <- function(ativos, cfg, raw_root, run_id) {
  destino <- file.path(garantir_dir(file.path(raw_root, "binance", "exchangeInfo")),
                       paste0("exchangeInfo_", run_id, ".json"))
  r <- requisitar(paste0(cfg$market_data_api, "/exchangeInfo"), path = destino)
  base <- data.table::data.table(asset_id = ativos$asset_id, symbol = ativos$symbol_candidate)
  if (r$situacao != "disponivel") {
    base[, `:=`(no_catalogo_atual = NA, baseAsset = NA_character_, quoteAsset = NA_character_,
                status_atual = NA_character_, spot_permitido = NA,
                snapshot = destino, situacao_snapshot = r$situacao)]
    return(base[])
  }
  info <- jsonlite::fromJSON(destino, simplifyVector = TRUE)
  s <- data.table::as.data.table(info$symbols[, c("symbol", "status", "baseAsset", "quoteAsset",
                                                  "isSpotTradingAllowed")])
  out <- merge(base, s, by = "symbol", all.x = TRUE, sort = FALSE)
  data.table::setnames(out, c("status", "isSpotTradingAllowed"), c("status_atual", "spot_permitido"))
  out[, no_catalogo_atual := !is.na(status_atual)]
  out[, `:=`(snapshot = destino, situacao_snapshot = "disponivel")]
  out[]
}

# Coleta integral de um simbolo: mensais listados, diarios para lacunas e
# para o mes final ainda sem arquivo mensal, API para o que restar.
coletar_simbolo <- function(symbol, cfg, raw_root, run_id, log = NULL) {
  meses <- meses_busca(cfg)
  mensais <- listar_klines(symbol, "monthly", cfg)
  mensais <- mensais[periodo %in% meses]
  registrar_log(symbol, ": ", nrow(mensais), " arquivos mensais listados", arquivo = log)
  if (!nrow(mensais)) {
    diarios_lst <- listar_klines(symbol, "daily", cfg)
    if (!nrow(diarios_lst)) {
      return(list(
        manifesto = data.table::data.table(run_id = run_id, symbol = symbol, frequencia = "monthly",
                                           periodo = NA_character_, situacao = "nao_localizado",
                                           consultado_utc = agora_utc()),
        api = NULL))
    }
  }
  man <- lapply(mensais$periodo, function(p) baixar_zip_verificado(symbol, "monthly", p, cfg, raw_root, run_id))
  man <- data.table::rbindlist(man, fill = TRUE)

  # Meses entre o primeiro listado e o fim da busca sem mensal valido.
  primeiro <- if (nrow(mensais)) min(mensais$periodo) else NULL
  cobertos <- man[situacao == "disponivel", periodo]
  candidatos <- if (is.null(primeiro)) meses else meses[meses >= primeiro]
  faltantes <- setdiff(candidatos, cobertos)
  man_d <- NULL
  if (length(faltantes)) {
    diarios <- listar_klines(symbol, "daily", cfg)
    dias <- unlist(lapply(faltantes, dias_do_mes, cfg = cfg))
    dias_listados <- intersect(dias, diarios$periodo)
    registrar_log(symbol, ": ", length(faltantes), " meses sem mensal; ",
                  length(dias_listados), " diarios listados", arquivo = log)
    man_d <- data.table::rbindlist(lapply(dias_listados, function(d)
      baixar_zip_verificado(symbol, "daily", d, cfg, raw_root, run_id)), fill = TRUE)
    nao_listados <- setdiff(dias, dias_listados)
    if (length(nao_listados) && !is.null(primeiro)) {
      man_d <- data.table::rbindlist(list(man_d, data.table::data.table(
        run_id = run_id, symbol = symbol, frequencia = "daily", periodo = nao_listados,
        situacao = "nao_localizado", consultado_utc = agora_utc())), fill = TRUE)
    }
  }
  man <- data.table::rbindlist(list(man, man_d), fill = TRUE)

  # Dias finais ainda sem diario publicado: complementar pela API.
  api <- NULL
  disp <- man[situacao == "disponivel"]
  ultimo_dia <- as.Date(cfg$raw_open_time_end_exclusive - 1, tz = "UTC")
  dias_fim <- format(seq(ultimo_dia - 6, ultimo_dia, by = "day"), "%Y-%m-%d")
  meses_disp <- disp[frequencia == "monthly", periodo]
  dias_disp <- disp[frequencia == "daily", periodo]
  sem_fonte <- dias_fim[!(substr(dias_fim, 1, 7) %in% meses_disp) & !(dias_fim %in% dias_disp)]
  if (length(sem_fonte) && nrow(disp)) {
    inicio <- as.POSIXct(paste(min(sem_fonte), "00:00:00"), tz = "UTC")
    registrar_log(symbol, ": complementando pela API desde ", min(sem_fonte), arquivo = log)
    api <- baixar_klines_api(symbol, inicio, cfg$raw_open_time_end_exclusive, cfg, raw_root, run_id)
    api$inicio <- inicio
  }
  list(manifesto = man, api = api)
}

# Catalogo de cobertura por par a partir do manifesto (entrega da secao 8.3).
resumir_cobertura <- function(manifesto, api_manifesto = NULL) {
  m <- data.table::copy(manifesto)
  cob <- m[, .(
    primeiro_mensal = if (any(frequencia == "monthly" & situacao == "disponivel"))
      min(periodo[frequencia == "monthly" & situacao == "disponivel"]) else NA_character_,
    ultimo_mensal = if (any(frequencia == "monthly" & situacao == "disponivel"))
      max(periodo[frequencia == "monthly" & situacao == "disponivel"]) else NA_character_,
    mensais_ok = sum(frequencia == "monthly" & situacao == "disponivel"),
    diarios_ok = sum(frequencia == "daily" & situacao == "disponivel"),
    nao_localizados = sum(situacao == "nao_localizado", na.rm = TRUE),
    erros_transitorios = sum(situacao == "erro_transitorio", na.rm = TRUE),
    checksum_divergente = sum(situacao == "checksum_divergente", na.rm = TRUE),
    esquema_inesperado = sum(situacao == "esquema_inesperado", na.rm = TRUE)
  ), by = symbol]
  if (!is.null(api_manifesto) && nrow(api_manifesto)) {
    a <- api_manifesto[, .(linhas_api = sum(linhas, na.rm = TRUE)), by = symbol]
    cob <- merge(cob, a, by = "symbol", all.x = TRUE)
  } else {
    cob[, linhas_api := 0L]
  }
  cob[is.na(linhas_api), linhas_api := 0L]
  cob[, situacao_par := data.table::fifelse(mensais_ok + diarios_ok == 0, "nao_localizado",
                       data.table::fifelse(erros_transitorios + checksum_divergente + esquema_inesperado > 0,
                                           "pendente_revisao", "coletado"))]
  cob[]
}
