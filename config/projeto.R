# Protocolo v1: ver contexto/plano_execucao_R.md.
# Parametros numericos sao escolhas do projeto, nao resultados estimados.
cfg <- list(
  # 1.1.0: so a etapa bayesiana mudou; as previsoes classicas seguem 1.0.0.
  protocol_version = "1.1.0",
  seed = 20261102L,
  timezone = "UTC",
  interval = "1h",
  quote_asset = "USDT",
  archive_start_month = as.Date("2017-08-01"),
  analysis_start = as.POSIXct("2020-01-01 00:00:00", tz = "UTC"),
  development_end_exclusive = as.POSIXct("2024-07-01 00:00:00", tz = "UTC"),
  operational_validation_end_exclusive = as.POSIXct("2025-01-01 00:00:00", tz = "UTC"),
  test_end_exclusive = as.POSIXct("2026-11-01 00:00:00", tz = "UTC"),
  raw_open_time_end_exclusive = as.POSIXct("2026-11-02 00:00:00", tz = "UTC"),
  horizon_hours = 24L,
  loss_threshold = -0.05,
  availability_delay_seconds = 60L,
  graph_window_days = 90L,
  graph_update_hours_utc = 0L,
  graph_return_coverage = 0.98,
  pair_return_coverage = 0.95,
  minimum_graph_nodes = 5L,
  minimum_market_contributors = 3L,
  illiquidity_positive_volume_coverage = 0.95,
  positive_correlation_threshold = 0.30,
  katz_attenuation = 0.50,
  training_window_days = 730L,
  calibration_window_days = 90L,
  minimum_calibration_per_class = 50L,
  minimum_calibration_dates = 30L,
  ridge_alpha = 0,
  ridge_lambda_grid = c(1e-4, 1e-3, 1e-2, 1e-1, 1),
  class_sd_floor_after_scaling = 1e-8,
  minimum_training_per_class = 50L,
  tuning_brier_tie_tolerance = 1e-6,
  probability_clip = 1e-12,
  bootstrap_replicates = 2000L,
  bootstrap_mean_days = 7L,
  bayesian_refit_months = c(1L, 4L, 7L, 10L),
  # Revisao 1.1 (antes do teste, so com dados ate jun/2024): priors e MCMC da
  # etapa bayesiana; ver relatorios/registro_execucao.md.
  bayes_mu_a_prior = c(media = -3, dp = 2),
  bayes_sigma_v_prior_scale = 2,
  bayes_coef_prior_scale = 0.5,
  bayes_chains = 4L,
  bayes_warmup = 1000L,
  bayes_sampling = 2000L,
  bayes_rhat_max = 1.01,
  bayes_ess_min = 400,
  archive_base = "https://data.binance.vision/data/spot",
  market_data_api = "https://data-api.binance.vision/api/v3",
  packages_core = c(
    "httr2", "jsonlite", "digest", "data.table", "lubridate", "slider",
    "arrow", "DBI", "duckdb", "igraph", "glmnet", "naivebayes",
    "yardstick", "boot", "ggplot2", "targets"
  ),
  packages_bayesian = c("brms", "posterior", "bayesplot", "loo"),
  pilot_files = data.frame(
    symbol = c("BTCUSDT", "BTCUSDT", "ETHUSDT"),
    month = c("2024-12", "2025-01", "2025-01"),
    stringsAsFactors = FALSE
  )
)

stopifnot(
  cfg$development_end_exclusive < cfg$operational_validation_end_exclusive,
  cfg$operational_validation_end_exclusive < cfg$test_end_exclusive,
  cfg$katz_attenuation > 0,
  cfg$katz_attenuation < 1,
  cfg$graph_return_coverage >= cfg$pair_return_coverage
)
