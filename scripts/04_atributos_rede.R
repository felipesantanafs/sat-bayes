# Etapas 4-5: alvos, atributos M1/M2, redes diarias e amostra analitica.
if (!file.exists("config/projeto.R")) stop("Execute na raiz sat-bayes.")
Sys.setenv(TZ = "UTC")
for (f in c("R/utils.R", "R/painel.R", "R/atributos.R", "R/rede.R", "R/modelos.R")) source(f, encoding = "UTF-8")
cfg <- carregar_cfg()
ativos <- carregar_ativos()
out_dir <- garantir_dir(file.path("dados", "analiticos"))
audit_dir <- garantir_dir(file.path("resultados", "auditoria", "atributos"))

painel <- ler_painel()
ind <- construir_individuais(painel, cfg)
feat <- construir_mercado(ind, ativos, cfg)

btc <- ativos[papel_proposto == "ancora_rede", symbol_candidate]
alvos <- ativos[papel_proposto == "alvo_candidato", symbol_candidate]
ultima_origem <- cfg$test_end_exclusive - 3600
rede <- construir_redes(ind[, .(symbol, t, lr_1h)], c(btc, alvos), btc, cfg,
                        inicio = cfg$analysis_start, fim = ultima_origem)
feat <- juntar_rede(feat, rede)
tabs <- separar_tabelas(feat)

arrow::write_parquet(tabs$features, file.path(out_dir, "features_individual_market.parquet"))
arrow::write_parquet(tabs$targets, file.path(out_dir, "targets.parquet"))
arrow::write_parquet(rede$resumo, file.path(out_dir, "network_snapshots.parquet"))
arrow::write_parquet(rede$features, file.path(out_dir, "network_features.parquet"))
arrow::write_parquet(rede$arestas, file.path(out_dir, "network_edges.parquet"))

# Amostra principal: alvos (sem BTC e sem comparadores), origens do estudo e
# todos os atributos de M0-M4 observados em t. A disponibilidade de Y nao
# entra na elegibilidade; alvos ausentes ficam com motivo registrado.
obrigatorias <- blocos_modelo()$M4
amostra <- feat[symbol %in% alvos & t >= cfg$analysis_start & t < cfg$test_end_exclusive]
amostra[, elegivel := stats::complete.cases(amostra[, obrigatorias, with = FALSE]) & graph_valido %in% TRUE]
exclusoes <- amostra[elegivel == FALSE, .N, by = .(symbol, ano = format(t, "%Y"))]
amostra <- amostra[elegivel == TRUE]
amostra[, fase := fase_origem(t, cfg)]
manter <- c("symbol", "t", "forecast_at", "label_end", "label_available_at", "y", "ret_fwd_24h",
            "motivo_y_ausente", "graph_id", "fase", obrigatorias, "betweenness_w", "a_d")
amostra <- amostra[, ..manter]
data.table::setorder(amostra, t, symbol)
arrow::write_parquet(amostra, file.path(out_dir, "amostra_principal.parquet"))

data.table::fwrite(exclusoes, file.path(audit_dir, "exclusoes_por_ativo_ano.csv"))
data.table::fwrite(rede$resumo[, .N, by = .(valido, motivo)], file.path(audit_dir, "snapshots_validade.csv"))
cobertura <- amostra[, .(origens = .N, alvos_observados = sum(!is.na(y)), perdas = sum(y, na.rm = TRUE),
                         prevalencia = mean(y, na.rm = TRUE)), by = .(symbol, fase)][order(symbol, fase)]
data.table::fwrite(cobertura, file.path(audit_dir, "cobertura_amostra.csv"))
print(rede$resumo[, .N, by = .(valido, motivo)])
print(amostra[, .(origens = .N, perdas = sum(y, na.rm = TRUE), prevalencia = mean(y, na.rm = TRUE)), by = fase])
