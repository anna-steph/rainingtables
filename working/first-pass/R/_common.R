# Common

# Loads at the top of each chapter

# Turn off scientific notation
options(scipen = 999)

# Libraries
libraries <- c("dplyr", "readr", "ggplot2", "gt", "janitor")
invisible(sapply(libraries, library, character.only = TRUE))

# Package functions
# pkgload::load_all(quiet = TRUE)
program_list <- list.files("R", full.names = TRUE)
program_list <- program_list[program_list != "R/_common.R"]
invisible(sapply(program_list, source))

# Folders that chapters write into. Harmless to re-run.
dir.create("data-raw", showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)
