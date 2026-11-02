# Funcoes auxiliares comuns; ver contexto/plano_execucao_R.md.
# Nenhuma funcao deste arquivo altera estado global.

carregar_cfg <- function(path = "config/projeto.R") {
  env <- new.env(parent = baseenv())
  sys.source(path, envir = env, keep.source = FALSE)
  env$cfg
}

carregar_ativos <- function(path = "config/ativos_solicitados.csv") {
  data.table::fread(path, encoding = "UTF-8")
}

agora_utc <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

novo_run_id <- function() {
  paste0(format(Sys.time(), "%Y%m%dT%H%M%S", tz = "UTC"), "_", Sys.getpid())
}

garantir_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

sha256_arquivo <- function(path) {
  tolower(digest::digest(file = path, algo = "sha256", serialize = FALSE))
}

# Situacoes da secao 8.1 do plano. Um 404 prova apenas que o objeto nao foi
# localizado nesta consulta; nao vira volume zero.
classificar_http <- function(status) {
  if (is.na(status)) return("erro_transitorio")
  if (status >= 200 && status < 300) return("disponivel")
  if (status == 404) return("nao_localizado")
  if (status %in% c(401L, 403L)) return("acesso_negado")
  if (status %in% c(408L, 418L, 429L) || status >= 500) return("erro_transitorio")
  "erro_http"
}

# Requisicao GET com timeout e repeticao limitada de erros transitorios.
# httr2 respeita Retry-After em 429/503. Nao lanca erro por status HTTP:
# devolve status e situacao para registro no manifesto.
requisitar <- function(url, path = NULL, timeout = 60, max_tries = 4) {
  req <- httr2::request(url)
  req <- httr2::req_timeout(req, seconds = timeout)
  req <- httr2::req_retry(req, max_tries = max_tries, retry_on_failure = TRUE)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  resp <- tryCatch(httr2::req_perform(req, path = path), error = function(e) e)
  if (inherits(resp, "error")) {
    if (!is.null(path) && file.exists(path)) unlink(path)
    return(list(status = NA_integer_, situacao = "erro_transitorio",
                erro = conditionMessage(resp), resp = NULL))
  }
  status <- httr2::resp_status(resp)
  situacao <- classificar_http(status)
  if (situacao != "disponivel" && !is.null(path) && file.exists(path)) unlink(path)
  list(status = status, situacao = situacao, erro = NA_character_, resp = resp)
}

registrar_log <- function(..., arquivo = NULL) {
  linha <- paste0("[", agora_utc(), "] ", paste0(..., collapse = ""))
  message(linha)
  if (!is.null(arquivo)) cat(linha, "\n", file = arquivo, append = TRUE, sep = "")
  invisible(linha)
}
