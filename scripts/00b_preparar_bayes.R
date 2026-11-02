# Preparo da etapa bayesiana (secao 17.1). Executar uma vez, apos instalar o
# Rtools compativel com o R (Rtools44 para R 4.4).
# Fonte: https://mc-stan.org/cmdstanr/articles/cmdstanr.html
if (!file.exists("config/projeto.R")) stop("Execute na raiz sat-bayes.")
options(repos = c(P3M = "https://packagemanager.posit.co/cran/latest",
                  CRAN = "https://cloud.r-project.org"))
source("config/projeto.R", encoding = "UTF-8")

renv::install(cfg$packages_bayesian, prompt = FALSE)
renv::install("stan-dev/cmdstanr", repos = c("https://stan-dev.r-universe.dev", getOption("repos")),
              prompt = FALSE)
cmdstanr::check_cmdstan_toolchain(fix = TRUE)
if (is.null(tryCatch(cmdstanr::cmdstan_version(), error = function(e) NULL))) {
  cmdstanr::install_cmdstan(cores = 2)
}
renv::snapshot(packages = unique(c(names(renv::lockfile_read("renv.lock")$Packages),
                                   cfg$packages_bayesian, "cmdstanr")), prompt = FALSE)
dir.create("logs", showWarnings = FALSE)
writeLines(c(paste0("cmdstan_version=", cmdstanr::cmdstan_version()),
             paste0("cmdstan_path=", cmdstanr::cmdstan_path()),
             capture.output(sessionInfo())), "logs/versao_cmdstan.txt")
message("CmdStan ", cmdstanr::cmdstan_version(), " pronto.")
