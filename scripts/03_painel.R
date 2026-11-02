# Etapa 3: painel horario auditado a partir da coleta vigente.
if (!file.exists("config/projeto.R")) stop("Execute na raiz sat-bayes.")
Sys.setenv(TZ = "UTC")
for (f in c("R/utils.R", "R/coleta.R", "R/painel.R")) source(f, encoding = "UTF-8")
cfg <- carregar_cfg()

run_id <- readLines(file.path("dados", "brutos", "coleta_vigente.txt"), n = 1L)
coleta_dir <- file.path("resultados", "auditoria", "coleta", run_id)
manifesto <- data.table::fread(file.path(coleta_dir, "manifesto_coleta.csv"))
api_path <- file.path(coleta_dir, "api_klines.rds")
api_klines <- if (file.exists(api_path)) readRDS(api_path) else list()

audit_dir <- garantir_dir(file.path("resultados", "auditoria", "painel"))
r <- construir_painel(manifesto, api_klines, cfg, audit_dir)
gravar_painel(r$painel, file.path("dados", "intermediarios", "candles"))

qualidade <- r$qualidade
qualidade[, coleta_run_id := run_id]
data.table::fwrite(qualidade, file.path(audit_dir, "data_quality.csv"))
manifest_hash <- digest::digest(file = file.path(coleta_dir, "manifesto_coleta.csv"), algo = "sha256")
writeLines(c(paste0("coleta_run_id=", run_id), paste0("data_manifest_hash=", manifest_hash),
             paste0("parser_version=", parser_version)),
           file.path("dados", "intermediarios", "painel_versao.txt"))
print(qualidade[, .(symbol, primeira_abertura, ultima_abertura, horas_observadas, horas_ausentes,
                    horas_atividade_zero, conflitos)])
