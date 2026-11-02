# Etapas 1-2: auditoria dos candidatos e coleta integral dos klines spot 1h.
# Executar na raiz sat-bayes apos scripts/00_preparar_ambiente.R.
# Reexecucoes reaproveitam ZIPs cujo SHA-256 confere com o .CHECKSUM remoto.
if (!file.exists("config/projeto.R")) stop("Execute na raiz sat-bayes.")
Sys.setenv(TZ = "UTC")
for (f in c("R/utils.R", "R/coleta.R")) source(f, encoding = "UTF-8")
cfg <- carregar_cfg()
ativos <- carregar_ativos()

run_id <- novo_run_id()
raw_root <- file.path("dados", "brutos")
audit_dir <- garantir_dir(file.path("resultados", "auditoria", "coleta", run_id))
log <- file.path(garantir_dir("logs"), paste0("coleta_", run_id, ".log"))

catalogo <- auditar_exchange_info(ativos, cfg, raw_root, run_id)
data.table::fwrite(catalogo, file.path(audit_dir, "auditoria_catalogo_atual.csv"))
registrar_log("Catalogo atual: ", sum(catalogo$no_catalogo_atual, na.rm = TRUE), " de ",
              nrow(catalogo), " candidatos presentes", arquivo = log)

resultados <- lapply(ativos$symbol_candidate, function(s) {
  tryCatch(coletar_simbolo(s, cfg, raw_root, run_id, log = log), error = function(e) {
    registrar_log(s, ": falha na coleta: ", conditionMessage(e), arquivo = log)
    list(manifesto = data.table::data.table(run_id = run_id, symbol = s, frequencia = NA_character_,
                                            periodo = NA_character_, situacao = "erro_transitorio",
                                            consultado_utc = agora_utc(), erro = conditionMessage(e)),
         api = NULL)
  })
})
manifesto <- data.table::rbindlist(lapply(resultados, `[[`, "manifesto"), fill = TRUE)
api_man <- data.table::rbindlist(lapply(resultados, function(r) r$api$manifesto), fill = TRUE)
api_klines <- stats::setNames(lapply(resultados, function(r) {
  if (is.null(r$api$klines)) NULL else list(klines = r$api$klines, inicio = r$api$inicio)
}), ativos$symbol_candidate)
api_klines <- Filter(Negate(is.null), api_klines)
saveRDS(api_klines, file.path(audit_dir, "api_klines.rds"))

data.table::fwrite(manifesto, file.path(audit_dir, "manifesto_coleta.csv"))
if (nrow(api_man)) data.table::fwrite(api_man, file.path(audit_dir, "manifesto_api.csv"))
cobertura <- resumir_cobertura(manifesto, api_man)
cobertura <- merge(cobertura, ativos[, .(symbol = symbol_candidate, asset_id, papel_proposto)],
                   by = "symbol", all.x = TRUE)
data.table::fwrite(cobertura, file.path(audit_dir, "catalogo_cobertura.csv"))

# Ponteiro para a coleta vigente usada pelas etapas seguintes.
writeLines(run_id, file.path("dados", "brutos", "coleta_vigente.txt"))
writeLines(capture.output(sessionInfo()), file.path(audit_dir, "session_info.txt"))
print(cobertura)
registrar_log("Coleta concluida: ", audit_dir, arquivo = log)
