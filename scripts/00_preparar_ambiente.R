# Executar a partir da raiz do repositorio, em uma sessao R nova.
# Fonte: https://rstudio.github.io/renv/articles/renv.html
if (!file.exists("config/projeto.R")) {
  stop("Abra a raiz sat-bayes como diretorio de trabalho antes de executar.")
}
if (getRversion() < "4.4.1") {
  stop("Este protocolo requer R >= 4.4.1; use uma versao compativel com os pacotes.")
}
# Binarios Windows para R 4.4 vem do Posit Package Manager; o CRAN deixou de
# publicar binarios atuais para essa versao e a compilacao local falhava.
options(repos = c(P3M = "https://packagemanager.posit.co/cran/latest",
                  CRAN = "https://cloud.r-project.org"))
Sys.setenv(TZ = "UTC")
source("config/projeto.R", encoding = "UTF-8")
set.seed(cfg$seed)

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}
if (!file.exists("renv/activate.R")) {
  renv::init(bare = TRUE, restart = FALSE)
} else {
  renv::load(project = ".")
}
if (file.exists("renv.lock")) {
  renv::restore(prompt = FALSE)
}

missing_packages <- cfg$packages_core[
  !vapply(cfg$packages_core, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) renv::install(missing_packages)

nao_carregam <- function() cfg$packages_core[
  !vapply(cfg$packages_core, requireNamespace, logical(1), quietly = TRUE)
]
still_missing <- nao_carregam()
# Dependencias antigas vindas do cache do renv (ex.: rlang) impedem o carregamento.
if (length(still_missing)) {
  renv::update(prompt = FALSE)
  still_missing <- nao_carregam()
}
if (length(still_missing)) {
  stop("Instalacao incompleta: ", paste(still_missing, collapse = ", "))
}

project_dirs <- c(
  "dados/brutos", "dados/intermediarios", "dados/analiticos",
  "resultados/auditoria", "resultados/modelos", "resultados/figuras",
  "resultados/tabelas", "logs", "R", "modelos", "relatorios"
)
invisible(lapply(project_dirs, dir.create, recursive = TRUE, showWarnings = FALSE))
previous_packages <- if (file.exists("renv.lock")) {
  names(renv::lockfile_read("renv.lock")$Packages)
} else character()
renv::snapshot(
  packages = unique(c("renv", cfg$packages_core, previous_packages)),
  prompt = FALSE
)
writeLines(capture.output(sessionInfo()), "logs/session_info_preparo.txt")
message("Ambiente preparado. Proxima etapa: scripts/01_piloto_extracao.R.")
